        Title   sNDIInit.Asm - Standard NDIS Initialization Routine.
        Page    , 132
;
; Copyright (C) 1989, 1990, 1991 DWB Associates, All Rights Reserved
;
; Description: This file contains the NDIS Specific Initialization Code.
;

.xlist
; Build Configuration Information.
        Include Build.Cfg

; standard segment definitions
        Include Segments.inc

; NDIS specific structures and Generic Model Structures
        Include sStrucs.Inc

; Support Macros
        Include sMacros.inc

; Standard DOS and OS/2 Driver header equates.
        Include devhdr.inc
.list

DevHeaderSeg    Segment

; Data defined in sStrat.Asm

        Extrn   DevHdr:Byte

DevHeaderSeg    Ends


_DATA   segment

; Data defined in sStrat.Asm

;       Extrn   DevHdr:Byte
        Extrn   DevHlp:Dword

; Data defined in sData.Asm

        Extrn   WCC:byte
        Extrn   BindingsList:Word
        Extrn   NumBindings:Word
        Extrn   ModuleNames:Word
        Extrn   adapterNum:Word
        Extrn   StartPI:Abs
        Extrn   PI_Count:Abs

; Data defined in sMsgs.Asm

;       Extrn   NoProtoIniMatch:Byte
        Extrn   NoDrvrNameKW:Byte
        Extrn   NoKeyWordFound:Byte
        Extrn   ProtMgrErr:Byte

_DATA   ends

;
;-----------------------------------------------------------------------------
;

IDATA   Segment

; Data located in hData.Asm

        Extrn   drvrDevName:Byte
        Extrn   ProtNameKW:Byte

;
;       All strings must be zero terminated.
;
protMgrName     DB      "\DEV\PROTMAN$", 0
DrvrNameKW      DB      "DRIVERNAME", 0

PMHandle        DW      ?               ; File handle for Protocol Manager.


Ife     DOS

DDHandle        DW      0               ; Handle for opened device drivers.

OpenAction      DW      0               ; Return Open Action.

Endif                                   ; OS/2 version.

        ReqBlock        RqBlk <>
                DD      0               ; Scratch space for Testtool bug.

IDATA   Ends


;
;-----------------------------------------------------------------------------
;

ICODE   Segment

Ife     DOS
; Routines provided by the OS/2 Kernel

        Extrn   DOSOPEN:FAR
        Extrn   DOSDEVIOCTL:FAR
        Extrn   DOSCLOSE:FAR
Endif                                   ; OS/2

; Routines defined in sInit.Asm

        Extrn   printf:Near



;-----------------------------------------------------------------------------
;
; Function: ndisInit
;
; Inputs:
;               none
;
; Outputs:
;       returns Not Carry if initialization was successful, Carry otherwise.
;
; Side Effects:
;
;       This function controls the generic NDIS intialization:
;
;               * Negotiate drivername (MAC$, MAC2$, ... MACn$).
;               * Open the PROTMAN$.
;               * GetProtocolManagerInfo.
;               * Parse the Module configuration image to dispatch action
;                 routines per parameter.
;               * RegisterModule (with protocol manager).
;
        Public  NDISInit
NDISInit        Proc    Near
        Push    ES                      ; Save Init Packet address.
        Push    BX
        Call    SearchDriver            ; Find any others like us out there and
                                        ; create a unique name for us.
        Jc      NDISInit_Err
        Call    CopyNameToHeader        ; Copy the driver name to the header.
        Call    OpenPM                  ; Open the Protocol Manager.
        Jc      NDISInit_Err            ; Exit out if not found.
        Call    GetPMI                  ; Get Protocol Manager Info.
        Jc      NDISInit_Err            ; Exit out if error.
        Les     DI, [ReqBlock].Pointer1 ; Set ES:DI pointer to the parameters.
        Call    ParseProtIni            ; Parse Protocol.Ini Parameters and KeyWords.
        Jc      NDISInit_Err            ; Exit out if error occured.
        Call    RegisterMAC             ; Go register with the Protocol Manager.
        Jc      NDISInit_Err            ; Exit out if error.
        Call    ClosePM                 ; Close the Protocol Manager.
        Clc                             ; Indicate success.
        Pop     BX                      ; Restore Init packet address.
        Pop     ES                      ;
        Ret
NDISInit_Err:
        Lea     DX, [ProtMgrErr]        ; Load address of failure message.
        Push    DX                      ; Setup for printf.
        Call    printf                  ; Display the message.
        Add     SP, 2                   ; Normalize the stack.
        Stc                             ; Indicate failure.
        Pop     BX                      ; Restore Init packet address.
        Pop     ES                      ;
        Ret
NDISInit        Endp

;
;       Out:    Carry set if 10 drivers are found.
;
        Public  SearchDriver
SearchDriver    Proc    Near
        Cld                             ; Insure forward direction.
        Mov     adapterNum, 1           ; Start with the first adapter.
CheckDriver:
        Lea     DX, [DrvrDevName]       ; Set DS:DX = base driver name.
        Call    OpenDriver              ; Try to open the driver by name.
        Jnc     NoDriverFound           ; Brif not found.
        Inc     adapterNum              ; Bump the adapter count.
        Push    DS                      ; Setup ES
        Pop     ES                      ; to point to DS.
        Lea     DI, [DrvrDevName]       ; Set ES:DI = base driver name.
        Mov     AL, "$"                 ; Set search delimiter.
        Mov     CX, 80                  ; Set maximum search length.
        Repne   Scasb                   ; Search for the $ delimiter.
        Jne     NoMoreDrivers           ; Brif failed to find delimiter.
        Dec     DI                      ; Point DI to the delimiter.
        Cmp     Byte Ptr [DI-1], '2'    ; Is the value Numeric
        Jb      @F                      ; Brif not.
        Cmp     Byte Ptr [DI-1], '9'    ; Check upper range too.
        Ja      @F                      ; Brif not numeric.
        Je      NoMoreDrivers           ; Exit if no more slots available.
        Inc     Byte Ptr [DI-1]         ; Else just bump the number up one.
        Jmp     Short CheckDriver       ; Try this name.
@@:
        Mov     Byte Ptr [DI], '2'      ; Start at driver name2.
        Mov     Byte Ptr [DI+1], '$'    ; Terminate the string.
        Jmp     Short CheckDriver       ; Try this name.

NoMoreDrivers:
        Stc                             ; Indicate Error.
        Ret
NoDriverFound:
        Clc                             ; Indicate success.
        Ret
SearchDriver    Endp

;
;
;
        Public  CopyNameToHeader
CopyNameToHeader        Proc    Near
        Cld                             ; Insure forward direction.
        Push    DS                      ; Setup ES
        Pop     ES                      ; to point to DS.
        Lea     DI, [DrvrDevName]       ; Set DS:DX = base driver name.
        Mov     AL, "$"                 ; Set search delimiter.
        Mov     CX, 80                  ; Set maximum search length.
        Repne   Scasb                   ; Search for the $ delimiter.
        Dec     DI                      ; Point DI to the delimiter.
        Sub     CX, 80
        Not     CX                      ; Set CX to length of the string.
        Push    CX                      ; Save for size conversion.
        Std                             ; Reverse the scan.
        Mov     AL, "\"                 ; Set search path delimiter.
        Repne   Scasb                   ; Search for the $ delimiter.
        Add     DI, 2                   ; Point DI to the first character in the string.
        Inc     CX                      ; Just copy up to and including the $.
        Cld                             ; Insure forward direction.
        Pop     AX                      ; Set AX = total string size.
        Sub     AX, CX                  ; Calc length of string to copy.
        Mov     CX, AX                  ; Move to count reg.
        Mov     SI, DI                  ; Move to source reg for copying.
        Lea     DI, [DevHdr].SDevName   ; Set Destination to the drivers header.
        Rep     Movsb
        Ret
CopyNameToHeader        Endp


;       In:     DS:DX = Pointer to device driver name.
;
;       Out:    Carry Set if driver found, Carry Clear if not.
;
        Public  OpenDriver
OpenDriver      Proc    Near
Ife     DOS
        Push    DS                      ; Set pointer to Device driver name.
        Push    DX                      ; 
        Push    DS                      ; Set pointer to DDHandle in our Data.
        Push    Offset [DDHandle]       ; 
        Push    DS                      ; Set pointer to action return.
        Push    Offset [OpenAction]     ; 
        Push    0                       ; Set file size of zero.
        Push    0                       ;
        Push    0                       ; Set file attribute to zero.
        Push    1                       ; Set open flag to Exist Only.
        Push    0C2h                    ; Set OpenMode to R/W Priv, Deny None.
        Push    0                       ; Set Reserved Dword.
        Push    0                       ;
        Call    DOSOPEN                 ; Call the kernel.
        Cmp     AX, 0                   ; Were we successful?
        Jne     OpenDriver_NotFound     ; Brif not (we don't want to find the driver!).
        Push    [DDHandle]              ; Set the handle to close.
        Call    DOSCLOSE                ; Close the driver.
Else
        Mov     AX, 0C2h                ; Set Open Mode.
        Mov     AH, 3DH                 ; Set DOS Function Number.
        Int     21H                     ; Call DOS kernel.
        Jc      OpenDriver_NotFound     ; If error, exit.
        Mov     BX, AX                  ; Move handle to BX for closing.
        Mov     AH, 3Eh                 ; Set DOS FUnction code to Close file.
        Int     21H                     ; Call DOS Kernel.
Endif

OpenDriver_Found:
        Stc                             ; Indicate we found the driver.
        Ret
OpenDriver_NotFound:
        Clc                             ; Indicate we did not find the driver.
        Ret
OpenDriver      Endp


;       In:     Nothing.
;
;       Out:    AX = 0 if no errors else error code.
;
        Public  OpenPM
OpenPM  Proc    Near
Ife     DOS
        Push    DS                      ; Set pointer to protocol managers name.
        Push    Offset ProtMgrName      ; 
        Push    DS                      ; Set pointer to PMHandle in our Data.
        Push    Offset [PMHandle]       ; 
        Push    DS                      ; Set pointer to action return.
        Push    Offset [OpenAction]     ; 
        Push    0                       ; Set file size of zero.
        Push    0                       ;
        Push    0                       ; Set file attribute to zero.
        Push    1                       ; Set open flag to Exist Only.
        Push    0091h                   ;91h Set OpenMode to R/W Priv, Write Only.
        Push    0                       ; Set Reserved Dword.
        Push    0                       ;
        Call    DOSOPEN                 ; Call the kernel.
        Cmp     AX, 0                   ; Was there an error?
        Jne     OpenPM_NotFound         ; Brif so.
Else
        Mov     AX, 0C2h                ; Set Open Mode.
        Mov     AH, 3DH                 ; Set DOS Function Number.
        Lea     DX, [ProtMgrName]       ; Set DX = pointer to file name.
        Int     21H                     ; Call DOS kernel.
        Jc      OpenPM_NotFound         ; If error, exit.
        Mov     PMHandle, AX            ; else save handle.
        Xor     AX, AX                  ; Set success return code.
Endif

OpenPM_Found:
        Clc                             ; Indicate we did not find the driver.
        Ret
OpenPM_NotFound:
        Stc                             ; Indicate we found the driver.
        Ret
OpenPM  Endp

;
;       In:     Nothing.
;
;       Out:    Nothing.
;
        Public  ClosePM
ClosePM Proc    Near
Ife     DOS
        Push    [PMHandle]              ; Set the handle to close.
        Call    DOSCLOSE                ; Close the driver.
Else
        Mov     BX, [PMHandle]          ; Move handle to BX for closing.
        Mov     AH, 3Eh                 ; Set DOS FUnction code to Close file.
        Int     21H                     ; Call DOS Kernel.
Endif
ClosePM Endp

;
;
        Public  GetPMI
GetPMI  Proc    Near
        Mov     [ReqBlock].Opcode, GetPMInfo ; Set PM Opcode.
        Lea     BX, [ReqBlock]          ; Set DS:BX = pointer to the request.
        Call    CallPM                  ; Call PM Interface.
        Ret
GetPMI  Endp


;
;
        Public  RegisterMAC
RegisterMAC     Proc    Near
        Mov     [ReqBlock].Opcode, RegisterModule ; Set PM Opcode.
        Mov     Word Ptr [ReqBlock].Pointer1, Offset [WCC] ; Set Offset the Comm Char.
        Mov     Word Ptr [ReqBlock].Pointer1+2, Seg _DATA ; Far Pointer.
        Xor     AX, AX                  ; Set AX = 0.

        Mov     Word Ptr [ReqBlock].Pointer2, Offset [BindingsList]
        Mov     Word Ptr [ReqBlock].Pointer2+2, Seg _DATA ; Far Pointer.
        Lea     BX, [ReqBlock]          ; Set DS:BX = pointer to the request.
        Call    CallPM                  ; Call PM Interface.
        Ret
RegisterMAC     Endp


;       In:     DS:BX = pointer to the request block.
;
        Public  CallPM
CallPM  Proc    Near
Ife     DOS
        Push    0                       ; Null Pointer to Data area.
        Push    0                       ; 
        Push    DS                      ; Pointer to parameter area.
        Push    BX                      ; 
        Push    58h                     ; Set category code.
        Push    81h                     ; Set function code.
        Mov     AX, PMHandle            ; Set AX = PM's File handle.
        Push    AX                      ; Set handle for kernel call.
        Call    DOSDEVIOCTL             ; Call Kernel function.
        Cmp     AX, 0                   ; Were we successful?
        Jne     CallPM_Exit             ; Brif not.
        Mov     AX, [BX+2]              ; Retrieve packet status.

Else
        Push    BX
        Push    CX
        Push    DX
        Mov     AX, 4402H               ; Set DOS function code and IOCTL function.
        Mov     DX, BX                  ; Move Argument to DS:DX.
        Mov     BX, PMHandle            ; Set PM's Handle.
        Mov     CX, 81h                 ; Set Category.
        Int     21H                     ; Call DOS kernel.
        Pop     DX
        Pop     CX
        Pop     BX
        Mov     AX, [BX+2]              ; Set AX = packet status
        Jnc     CallPM_Exit             ; If call was successful, exit.
        Mov     AX, 1                   ; Set error code and exit.
Endif

CallPM_Exit:
        Ret
CallPM  Endp


;
;       In:     ES:DI = Pointer to Protocol.Ini ModCfg Structure.
;
;       Out:    Carry Set if error occurred.
;
        Public  ParseProtIni
ParseProtIni    Proc    Near
        Push    DI                      ; Save Base pointer.
        Add     DI, KE                  ; Plus the offset to the keywords.
        Lea     SI, DrvrNameKW          ; Set to offset of DRIVERNAME.
        Call    SearchKeyWord           ; Go search for a match.
        Jnc     FoundDrvrName           ; Brif we found it.
CheckNextMod:
        Pop     DI                      ; Restore Base Pointer.
        Cmp     Word Ptr ES:[DI], 0     ; See if we have a null pointer.
        Jne     LinkNextMod             ; Brif not.
        Cmp     Word Ptr ES:[DI+2], 0   ; Its a Long Pointer.
        Je      PPI_NoDrvrName          ; Brif null.
LinkNextMod:
        Les     DI, ES:[DI].NextModCfg  ; Get pointer to next record.
        Jmp     ParseProtIni            ; Go try again.

PPI_NoDrvrName:
        Lea     DX, [NoDrvrNameKW]      ; Load address of failure message.
        Push    DX                      ; Setup for printf.
        Call    printf                  ; Display the message.
        Add     SP, 2                   ; Normalize the stack.
        Jmp     PPI_Err                 ; Exit out via failure.

FoundDrvrName:
        Lea     DI, ES:[DI].Params      ; Set to start of passed parameter string.
        Lea     DI, ES:[DI].ParmStart   ; 
        Lea     SI, [DevHdr].SDevName   ; Set Destination to the drivers header.
        Mov     CX, 8                   ; Set maximum search length.
PPI_Loop:
        Cmpsb                           ; Compare a byte.
        Jne     CheckNextMod            ; Brif not a match.
        Cmp     Byte Ptr ES:[DI], 0     ; Have we found the null terminator.
        Je      PPI_FoundMatch          ; Brif so.
        Loop    PPI_Loop                ; Try the next character.
PPI_FoundMatch:
        Pop     SI                      ; Restore start of ModCfg.
        Push    SI                      ; Save current position.

        Mov     CX, NAME_LEN            ; Set size of field.
        Add     SI, ModName             ; Index to Name field.
        Lea     DI, [WCC].CcName        ; Save name in Common Char table.
        Push    ES
        Push    DS                      ; Save DS and swap ES with DS
        Push    ES                      ; for copying.
        Push    DS                      ;
        Pop     ES                      ;
        Pop     DS                      ;
        Rep     Movsb
        Pop     DS                      ; Restore DS.
        Pop     ES                      ; Restore ES
        Pop     DI                      ; Restore to start of ModCfg.

        Add     DI, KE                  ; Plus the offset to the keywords.
        Mov     CX, PI_Count            ; Get CX to Count of Keywords.
        Mov     SI, StartPI             ; Set to offset of first argument.
KeyLoop:
        Push    ES
        Push    DI                      ; Save Keyword start point.
        Push    CX                      ; Save keyword count.

        Call    SearchKeyWord           ; Go search for a match.
        Jc      NoKeyWordMatch          ; Brif not found.
        Lea     DI, ES:[DI].Params      ; Set to start of passed parameter string.
        Mov     AX, DS:[SI].SrchParmType ; Get type of parameter this should be.
        Cmp     ES:[DI].ParamType, AX   ; Is this the right type of parameter?
        Jne     NoKeyWordMatch          ; Brif not.
        Mov     DX, Word Ptr ES:[DI].ParmStart+2 ; Load DX with Most significant value.
        Mov     AX, Word Ptr ES:[DI].ParmStart ; Load AX with the least.
        Call    DS:[SI].SetFCN          ; Call Set parameter function.
        Jmp     Short NextKeyWord       ; Go do the next keyword.
NoKeyWordMatch:
        Lea     DX, [NoKeyWordFound]    ; Load address of failure message.
        Push    DX                      ; Setup for printf.
        Call    printf                  ; Display the message.
        Add     SP, 2                   ; Normalize the stack.
NextKeyWord:
        Pop     CX                      ; Restore keyword count.
        Pop     DI                      ; Restore start of keywords.
        Pop     ES
        Add     SI, Size PI_Record      ; Inc to next Protocol keyword to parse
        Loop    KeyLoop                 ; Go for the count.
        Clc                             ; Indicate success.
        Ret
PPI_Err:
        Stc                             ; Indicate failure.
        Ret
ParseProtIni    Endp


;
;       In:     ES:DI = Protocol Manager Info.
;               DS:SI = Keyword to search for.  
;
        Public  SearchKeyWord
SearchKeyWord   Proc    Near
        Push    DI                      ; Save pointer to the base of this record.
        Push    SI                      ; Save pointer to start of keyword.
        Cld                             ; Forward search.
        Add     DI, ModName             ; Add offset to Name field.
        Mov     CX, NAME_LEN            ; Set maximum search length.
SKW_Loop:
        Cmpsb                           ; Compare a byte.
        Jne     SKW_NoMatch             ; Brif not a match.
        Cmp     Byte Ptr ES:[DI], 0     ; Have we found the null terminator.
        Je      SKW_FoundMatch          ; Brif so.
        Loop    SKW_Loop                ; Try the next character.
SKW_FoundMatch:
        Pop     SI                      ; Restore pointer to the start of the keyword.
        Pop     DI                      ; Restore pointer to start of PM args.
        Clc                             ; Indicate we found a match.
        Ret

SKW_NoMatch:
        Pop     SI                      ; Restore Keyword pointer.
        Pop     DI                      ; Restore pointer to start of the record.
        Cmp     Word Ptr ES:[DI], 0     ; See if we have a null pointer.
        Jne     @F                      ; Brif not.
        Cmp     Word Ptr ES:[DI+2], 0   ; Its a Long Pointer.
        Je      SKW_Exit                ; Brif null.
@@:
        Les     DI, ES:[DI].NextModCfg  ; Get pointer to next record.
        Jmp     SearchKeyWord           ; Go try again.
SKW_Exit:
        Stc                             ; Indicate failed to find a match.
        Ret
SearchKeyWord   Endp

        public  LogBindings
LogBindings     proc
        mov     si, offset DGROUP:ModuleNames
        mov     ax, 16                  ; ASCIIZ strings 16 bytes long
        mul     NumBindings
        inc     NumBindings             ; The number of bindings to do
        add     si, ax
        add     di, 2
        mov     cx, WORD PTR es:[di]    ; byte length of module name
        add     di, 2
bindings_copy:
        mov     al, BYTE PTR es:[di]    ; Copy module names into the bindings 
        mov     BYTE PTR ds:[si], al    ; list
        inc     di
        inc     si
        loop    bindings_copy
        ret
LogBindings     endp

ICODE   Ends

        End

