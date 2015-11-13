    Title   uSysReq.Asm - Upper level System Request functions.
    Page    , 132
;
; Copyright (C) 1989, 1990, 1991 DWB Associates, All Rights Reserved
;
; Description: This file contains the WEDGE upper function SystemRequest
;

.xlist
; Build Configuration Information.
    include Build.Cfg

; Standard segment definitions
    include Segments.inc

; NDIS specific structures and Generic Model Structures
    include sStrucs.Inc

; Support Macros
    include sMacros.inc

; Wedge specific structures.
    include wedge.inc

    include devhlp.inc

.list


;
;-----------------------------------------------------------------------------
;

_DATA   Segment

; Data defined in sData.Asm.

    extrn   RxGDT:Word
    extrn   TxGDT:Word
    extrn   WCC:byte
    extrn   WLD:byte
    extrn   MSS:byte
    extrn   WCC:byte
    extrn   WUD:byte
    extrn   MCC:dword
    extrn   MACPtrs:dword
    extrn   PCC:dword
    extrn   MACsBound:word
    extrn   MUDsTable:byte
    extrn   PLDsTable:byte
    extrn   DevHlp:dword
    extrn   TestToolParms:dword         ; Pointer to current shared memory area.
    extrn   tmpBindStruc:word           ; Bind structure with harmless pointers
                                        ;   to OUR memory buffers

    public  SysReqTable
SysReqTable label   word
        dw  offset CGROUP:InitiateBind
        dw  offset CGROUP:Bind
        dw  offset CGROUP:InitiatePrebind
        dw  offset CGROUP:InitiateUnbind
        dw  offset CGROUP:Unbind

SysReqMaxFunc   equ ($ - SysReqTable) Shr 1

_DATA   ends


;
;-----------------------------------------------------------------------------
;

_TEXT   segment

;
; Function: SystemRequest
;
;   Description:
;
;   Inputs:
;       The stack contains the SystemRequest info structure provided by
;           the protocol.
;
;   Outputs:
;
;   Side Effects:
;
;
    extrn   WSystem:near
    public  SystemRequest
SystemRequest   proc    far
;
;   This structure represents the stack after the stack frame has been setup.
;   This structure MUST reside inside the procedure.
;
SysReq  Struc
            dw  ?       ; Pushed BP.
            dw  (Not (Type SystemRequest))+1 Dup(?) ; Ret address on the stack.
SRMacDS     dw  ?       ; The DS value for this code.
SR_Opcode   dw  ?       ; Function code for the request.
SR_Param3   dw  ?       ; Parameter 3.
SR_Param2   dd  ?       ; Parameter 2.
SR_Param1   dd  ?       ; Parameter 1.
SysReq  ends

RetSysReqSize   equ size SysReq - (2 + -(Type SystemRequest * 2))

;
; First setup the Stack Pointer.
    push    bp
    mov     bp, sp

; Save the machine state
    push    bx
    push    cx
    push    dx
    push    di
    push    si
    push    ds
    push    es

ifndef  DOS
    mov     ds, word Ptr ss:[bp].SRMacDS
else
    push    word Ptr ss:[bp].SRMacDS
    pop ds
endif

    mov     ax, INVALID_FUNCTION        ; Defualt to Bad Function return value.
    mov     bx, ss:[bp].SR_Opcode       ; Set BL = SysReq Opcode.
    cmp     bx, 1                       ; Is the Opcode good.
    jb      SysReq_Exit                 ; if so.
    cmp     bx, SysReqMaxFunc           ; Is it past the last function.
    ja      SysReq_Exit                 ; Brif so.
    dec     bx                          ; Make it zero relative for the table.
    shl     bx, 1                       ; Make Opcode a word index.
    call    SysReqTable[bx]             ; Call the function. AX will be setup
                                        ; by the called routine.
SysReq_Exit:

; Restore machine state.
    pop     es
    pop     ds
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx

    pop     bp          ; Restore Stack frame pointer.
    ret     RetSysReqSize
SystemRequest   endp

;
;   System Request #1 InitiateBind.
;
;   In: Pointer to buffer containing the Characteristics Table in Parameter 2,
;       LastBind flag in Parameter 3.
;
;   Out:
;
;   Note: This routine is called by ProtMan to make the Wedge driver bind
;             to the MAC.  
;       
;
    public  InitiateBind
InitiateBind    proc    Near

;
; call MAC's Bind() and let the MAC copy our CommChar table.
;
    push    ds                          ; save our DS, NOT for the MAC's bind()

    push    ds                          ; Push (far *) to our CommChar table
    mov     ax, offset DGROUP:WCC
    push    ax

    push    ds                          ; Push (far *) to a table of handy ptrs
    mov     ax, offset DGROUP:MACPtrs   ;   He'll fill in first DWORD w/ptr to
    push    ax                          ;    his Common Characteristics table.

    xor     ax, ax                      ; Pad parameter (must be zero)
    push    ax

    mov     ax, _BIND                   ; Bind command (equal to 2)
    push    ax

    lds     si, ss:[bp].SR_Param2       ; Ptr (ds:si) to MAC's CommChar table.

    mov     ax, [si].CcDataSeg			; pass MAC's DS
    push    ax                          

    call    dword ptr ds:[si].CcSysReq_off  ; Tell the MAC to bind

    pop     ds                          ; restore our DS.

    cmp     ax, SUCCESS
    je      BindCopyMacInfo
    jmp     FailIB


; now get his cc table stuff and copy his upper dispatch table.

BindCopyMacInfo:

    push    ds                          ; save our DS
    push    ds                          ; es:di set to our copy of CommChar.
    pop     es
    mov     di, offset DGROUP:MCC

    mov     si, offset DGROUP:MACPtrs   ; get ptr to MAC's CC from our handy
    lds     si, [si].MP_CommChar        ;   table of MAC pointers.  (Currently,
                                        ;   the table only has the CC pointer.)

    mov     cx, size CommChar           ; Set cx = size of the structure.
    cld
    rep     movsb

    pop     ds                          ; restore our DS

;
;   Copy the MAC's Upper Dispatch table to our local structure.
;
    push    ds                          ; Save our DS.
    mov     di, offset DGROUP:MUDsTable ; Set es:di to our copy of his upper
                                        ;   dispatch table. ES is still to us.
    lds     si, dword ptr [MCC].CcUDp_off ; Set ds:si to *his* dispatch
                                        ;  table (from his CC table).
    mov     cx, size MACUprDisp         ; Set CX to size of structure copied.
    cld
    rep     movsb                       ; Copy dispatch table.
    pop     ds                          ; Restore DS.

;
; Fill in rest of pointers in MACPtrs.
;
    mov     si, offset DGROUP:MACPtrs   ; point to our handy table of MAC ptrs.

    les     di, [si].MP_CommChar        ; get MAC's module id from his CC table.
    mov     ax, es:[di].CcModuleID
    mov     [si].MP_ModuleID, ax        ; save it in MACPtrs table.

    mov     ax, es:[di].CcDataSeg       ; get MAC's DS
    mov     [si].MP_MACDS, ax           ; save it in MACPtrs table.

    mov     ax, es:[di].CcUDp_off       ; Get pointer to MAC's Service Specific
    mov     [si].MP_UpDisp_off, ax      ;   Characteristics table, and save it.
    mov     ax, es:[di].CcUDp_seg
    mov     [si].MP_UpDisp_seg, ax

    mov     ax, es:[di].CcSCp_off       ; Get pointer to MAC's Service Specific
    mov     [si].MP_MACsc_off, ax       ;   Characteristics table, and save it.
    mov     ax, es:[di].CcSCp_seg
    mov     [si].MP_MACsc_seg, ax

;
; Initialize temporary bind structure, so that MAC calls to us don't tempt us
;   to write with uninitialized pointers.  Use the tmpBindStruc, and initialize
;   pointers to harmless values.  RxGDT points to a convenient scratch buffer.
;
    mov     word ptr TestToolParms, offset DGROUP:tmpBindStruc
    mov     word ptr TestToolParms+2, ds

    mov     di, offset DGROUP:tmpBindStruc

    mov     word ptr [di].IndArray, 0		; use RxGDT:0 as dump for indics
    mov     ax, RxGDT
    mov     word ptr [di].IndArray+2, ax

    mov     word ptr [di].RcvData, 0		; dump frames in RxGDT:0 too
    mov     ax, RxGDT
    mov     word ptr [di].RcvData+2, ax

    mov     ax, word ptr [si].MP_Recv_Phys	; save physical address of RxGDT too
    mov     word ptr [di].RcvPhysAddr, ax
    mov     ax, word ptr [si].MP_Recv_Phys+2
    mov     word ptr [di].RcvPhysAddr+2, ax

    inc     MACsBound                       ; increment counter of bound MAC's
    mov     ax,SUCCESS

FailIB:
    ret

InitiateBind    endp



;
;   System Request #2 Bind.
;
;   In: Pointer to buffer containing the Characteristics Table in Parameter 1,
;       Table address for return parameters in Parameter 2.
;
;   Out:
;       
;   Note: This routine is called by the protocol to make the Wedge driver bind
;             to a Protocol if there is one.  
;        
;
    public  Bind
Bind    proc    Near
    test    word ptr [MSS].MssStatus, MS_BOUND ; Are we bound already?
    jnz     AlreadyBound                ; Brif so.

;
;   Copy Protocols Common Characteristics table to our Data Seg.
;
    mov     si, word ptr ss:[bp].SR_Param1
    mov     ax, word ptr ss:[bp].SR_Param1+2 ; Set ds:si to Protocol CommChar.
    lea     di, [PCC]                   ; Get offset to our local copy of CommChar.
    mov     cx, size CommChar           ; Set cx = size of the structure.
    push    ds
    push    ds                          ; es:di set to our copy of CommChar.
    pop     es
    mov     ds, ax                      ; ds:si set to Protocols copy of CommChar.
    cld
    rep     movsb
    pop     ds
;
;   Copy the Protocols Lower Dispatch table to our local structure.
;
;   Note:   es still equals ds.
;
    lea     di, [PLDsTable]             ; Set Destination to our Data.
    push    ds                          ; Save ds.
    mov     cx, size ProtLwrDisp        ; Set size of structure.
    lds     si, dword ptr [PCC].CcLDp_off   ; Set ds:si to dispatch table.
    rep     movsb                       ; Copy dispatch table.
    pop     ds                          ; Restore ds.
;
;   Set the address of a Wedge Common Characteristics table in the Packet for
;       return.
;
    lea     ax, [WCC]                   ; Set to offset of Characteristics table.
    push    es
    push    bx
    les     bx, ss:[bp].SR_Param2       ; Get pointer to Arg.
    mov     word ptr es:[bx], ax        ; Set pointer to Upper Dispatch Table.
    mov     word ptr es:[bx]+2, ds
    pop     bx
    pop     es

;
;   Set the Specific charactristics table that the Wedge is now bound.
;
    or      word ptr [MSS].MssStatus, MS_BOUND  ; Set Bound Flag.
    mov     ax, SUCCESS                 ; Indicate BIND Successful.
    ret

AlreadyBound:
    mov     ax, GENERAL_FAILURE ; Set General Failure if second bound.
    ret

Bind    endp

;
;   System Request #3 InitiatePrebind.
;
;   In:
;
;   Out:
;
;   Note: This call is not used by the MAC driver, it is meant for Protocol
;       Binding.
;
    public  InitiatePrebind
InitiatePrebind proc    Near
    mov ax, GENERAL_FAILURE
    ret
InitiatePrebind endp

;
;   System Request #4 InitiateUnbind.
;
;   In: Pointer to buffer containing the Characteristics Table in Parameter 2,
;       LastUnbind flag in Parameter 3.
;
;   Out:
;
;   Note: This call is not used by the MAC driver, it is meant for Protocol
;       UnBinding.
;
    public  InitiateUnbind
InitiateUnbind  proc    Near
    mov ax, GENERAL_FAILURE
    ret
InitiateUnbind  endp

;
;   System Request #5 Unbind.
;
;   In: Pointer to buffer containing the Characteristics Table in Parameter 1.
;
;   Out:
;
;   Note: This call is not supported by the MAC driver.
;
    public  Unbind
Unbind  proc    Near
    mov ax, INVALID_FUNCTION
    ret
Unbind  endp


_TEXT   ends

    End



