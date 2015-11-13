    Title   sInit.Asm - Standard Initialization Routines.
    Page    , 132
;
; Copyright (C) 1989, 1990, 1991 DWB Associates, All Rights Reserved
;
; Description: This file contains the Driver Initialization Code.
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

; OS/2 specific strucs and equates.
    Include OS2Equ.Inc

; DevHlp stuff
    Include DevHlp.Inc

; Wedge specific structures
    Include Wedge.Inc

.list


_DATA   segment

; Data defined in sStrat.Asm

    extrn   DevHlp:Dword

; Data defined in sData.Asm

    extrn   MSS:Byte
    extrn   procType:Word
    extrn   Ring0:Byte
    extrn   devInitStr:Byte
    extrn   GDT_table:Word
    extrn   RxGDT:Word
    extrn   TxGDT:Word
	extrn	MACPtrs:Word
    extrn   num_gdt:word
	extrn	mem_gdts:word


If  DOS
; Data defined in sDevHlp.Asm

    extrn   AllocAmount:Word
Endif                   ; DOS

; Data defined in smsgs.Asm

    extrn   AdapterMsg:Byte
    extrn   EnvInitFail:Byte
    extrn   NDISInitFail:Byte
    extrn   AllocBufFail:Byte
    extrn   GDTAllocFail:Byte


_DATA   ends


_TEXT   Segment

    extrn   NDISInit:near

If  DOS
; routine defined in sDevHlp.Asm

    extrn   DeviceHelp:Near

Endif                   ; DOS

_TEXT   Ends


;
;-----------------------------------------------------------------------------
;

IDATA   Segment

BytesWritten    DW  ?       ; Used by DOSWRITE for return count.

Ten     DW  10D
PrintfBuffer    DB  120 Dup (?)
BtoA_Buf    DB  12 Dup(?)   ; Buffer area for number conversions.
BtoA_Buf_End    Label   Word

IDATA   Ends


;
;-----------------------------------------------------------------------------
;

ICODE   Segment

Ife DOS
; Routine defined in DOSCALLS.LIB   OS/2 Kernel function.

    extrn   DOSWRITE:Far
Endif                   ; OS/2


;
; Function: OSInit
;
; Inputs:
;   ES:BX   - Request Packet pointer to an initialization request packet
;       that was originally given to the strategy entry point.
;
; Outputs:
;       none
;
; Side Effects:
;
;   This function does OS initialization generic to all NDIS drivers:
;
;       Saves DevHlp Address,
;       Prints Load-Time Message,
;       Calls NDIS init routine,
;       Inserts return values in request packet.
;

    Public  OSInit
OSInit  Proc    Near
Ife DOS
    Mov AX, Word Ptr ES:Pointer_1[BX] ; Get Device Help pointer,
    Mov Word Ptr [DevHlp], AX   ;
    Mov AX, Word Ptr ES:Pointer_1[BX]+2 ; from the initialzation packet.
    Mov Word Ptr [DevHlp+2], AX ;
Else
    Lea AX, DeviceHelp      ; Set AX = address of DOS devHlp routine.
    Mov Word Ptr [DevHlp], AX   ;
    Mov AX, CS          ; The routine resides in our code seg.
    Mov Word Ptr [DevHlp+2], AX ;
Endif
    Mov [Ring0], 0      ; Set Ring 0 to false.
    Call    SetProcType         ; Set to Processor type.

;
; save the DEVICE= string for later processing.
;
    Push    si
    Push    DI
    Push    DS
    Push    ES
    Mov CX, DEVINIT_LEN     ; Set Copy length.
    Lea DI, [devInitStr]    ; Set DI to our storage.
    Les si, ES:[BX].Pointer_2   ; Get ES:si pointer to Init Data.
    Push    ES
    Push    DS
    Pop ES          ; Swap ES with DS.
    Pop DS          ; Set Source DS:si
    Rep Movsb
    Pop ES          ; Restore Packet Sel.
    Pop DS          ; Restore Data Sel.
    Pop DI
    Pop si
;
; print the sign-on message
;
    Lea DX, [AdapterMsg]    ; Load address of signon message.
    Push    DX          ; Setup for printf.
    Call    printf          ; Display it.
    Add SP, 2           ; Normalize the stack.

;
; Allocate GDT's for transmit and receive during stress
;
    call    Init_GDT                    ; Allocate a GDT for our use.
    jnc     Alloc_Buffs                 ; Brif successful.
    lea     dx, [GDTAllocFail]          ; Load address of failure message.
    push    dx                          ; Setup for printf.
    call    printf                      ; Display it.
    add     sp, 2                       ; Normalize stack.
    jmp     InitFailure                 ; Exit out via failure.


;
; Now we need to allocate some space to use for receive buffering during
; receive look ahead time.
;

Alloc_Buffs:
	push	es								; save some registers
	push	di
	push	bx

	mov		bx, 4096						; hope that 4K is enough
    mov     ax, 0                           ; high order word of alloc size=0
    mov     dh, 0                           ; allocated memory can be above 1Mb
    mov     dl, DevHlp_AllocPhys
    call    [DevHlp]

    jnc     BRxAllocOK                      ; if Rx buff alloc failed
    mov     ax, GENERAL_FAILURE             ; then return failure

	pop		bx								; restore registers (and stack)
	pop		di
	pop		es
    jmp     InitFailure

BRxAllocOK:
    mov     word ptr MACPtrs.MP_Recv_Phys, ax  ; save phys address of rcv buff
    mov     word ptr MACPtrs.MP_Recv_Phys+2, bx

if OS2                                      ; Get GDT for Rx Buff
    push    si                              ; save ptr to mac ptr table
    mov     cx, 4096				        ; size of buf addressed by selector
    mov     si, RxGDT
    mov     dl, DH_PhysToGDTSelector		; Map phys to virt address via GDT.
    call    [DevHlp]
    pop     si                              ; restore ptr to mac ptr table
    jnc     BRxGDTMapOK                     ; if GDT mapping failed,
    mov     ax, GENERAL_FAILURE             ; then return failure
	pop		bx								; restore registers (and stack)
	pop		di
	pop		es
    jmp     InitFailure
else
    mov     cl, 4                           ; get a DOS segment for rx buffer
    shr     bx, cl                          ; a dos segment is just all but the
    mov     cl, 12                          ;   bottom 4 bits of the physical
    shl     ax, cl                          ;   address
    add     ax, bx
    mov     RxGDT, ax
endif

BRxGDTMapOK:
    push    si                              ; save ptr to MAC ptr table
	mov		bx, 4096						; Hope that 4K is enough
    mov     ax, 0                           ; high order word of alloc size=0
    mov     dh, 0                           ; allocated memory can be above 1Mb
    mov     dl, DevHlp_AllocPhys
    call    [DevHlp]
    pop     si                              ; restore ptr to MAC ptr table

    jnc     BTxAllocOK                      ; if alloc failed (CY)
    mov     ax, GENERAL_FAILURE             ; then, fail InitiateBind
	pop		bx								; restore registers (and stack)
	pop		di
	pop		es
    jmp     InitFailure

BTxAllocOK:
    mov     word ptr MACPtrs.MP_Tx_Phys, ax  ; save phys address of tx buff
    mov     word ptr MACPtrs.MP_Tx_Phys+2, bx

if OS2                                      ; Get GDT for Rx Buff
    push    si                              ; save ptr to mac ptr table
    mov     cx, 4096						; size of buf addressed by selector
    mov     si, TxGDT
    mov     dl, DevHlp_PhysToGDTSelector
    call    [DevHlp]
    pop     si                              ; restore ptr to mac ptr table
    jnc     BTxGDTMapOK                     ; if GDT mapping failed,
    mov     ax, GENERAL_FAILURE             ; then return failure
	pop		bx								; restore registers (and stack)
	pop		di
	pop		es
    jmp     InitFailure
else
    mov     cl, 4                           ; get a DOS segment for rx buffer
    shr     bx, cl                          ; a dos segment is just all but the
    mov     cl, 12                          ;   bottom 4 bits of the physical
    shl     ax, cl                          ;   address
    add     ax, bx
    mov     TxGDT, ax
endif

BTxGDTMapOK:
	pop		bx								; restore registers (and stack)
	pop		di
	pop		es


;
;
; Set resident size in the Request Packet.
;
Init_ndis:
    call    NDISInit
    jnc SetExitSize
    jmp     InitFailure                 ; Exit out via failure.

SetExitSize:
    Mov ES:[BX].PCKT_Status, 0  ; Clear return status.

SetResidentSize:

Ife DOS
    Mov CX, Offset ICode    ; Get end of resident code.
    Mov DX, Offset IData    ; Get end of resident data.
    Mov Word Ptr ES:[BX].Pointer_1, CX ; Set Size of Resident Code Seg.
    Mov Word Ptr ES:[BX].Pointer_1+2, DX ; Set Size of Resident Data Seg.
Else
    Mov CX, Offset DGROUP:ICode ; Get end of resident code.
    Add CX, AllocAmount     ; Add in any memory allocated at the bottom.
    Mov Word Ptr ES:[BX].Pointer_1, CX ; Set Size of Resident Code + Data
    Mov Word Ptr ES:[BX].Pointer_1+2, CS ; Set Segment of Resident Driver.
Endif
;
; set the done bit
;
    Mov ES:[BX].Data_1, 0   ; Character device return zero
    Mov Word Ptr ES:[BX].Pointer_2, 0 ; No BPB for Character Devices.
    Mov Word Ptr ES:[BX].Pointer_2+2, 0 ;

    Or  ES:[BX].PCKT_Status, STDON ; Return Done, OK
;
; upon exit from this thread, we get to be a ring 0 device driver. DOS
; will still scribble to the screen.
;
Ife DOS
    Mov [Ring0], 1      ; Indicate that we will be going to Ring 0.
Endif
    Ret

;
; Initialization failure is a "normal" return from the init command,
; we signal failure by "deinstalling" the device driver.
;
InitFailure:
    Mov ES:[BX].PCKT_Status, STERR ; Clear return status.
    Xor CX, CX          ; Set Zero resident size.
    Xor DX, DX
    Jmp Short SetResidentSize   ; Exit out.

OSInit  Endp



;
;
; Function: Init_GDT
;
; Inputs:
;   None
;
; Outputs:
;   The carry flag is set if the GDT's failed to allocate
;
; Side Effects: none
;
;
    public  Init_GDT
Init_GDT    proc    near

    push    cx
    push    dx
    push    di
    push    es

    push    ds                          ; Set es to the data seg.
    pop     es                          ;
    lea     di, [GDT_table]             ; Load address of GDT table.
    mov     cx, num_gdt                 ; Number of GDT's to allocate.
    mov     dl,DH_AllocGDTSelector      ; load function number.
    call    [DevHlp]                    ; Ask the kernel.

	lea		di, mem_gdts
	mov		cx, MAX_LOCKS
    mov     dl,DH_AllocGDTSelector      ; load function number.
    call    [DevHlp]                    ; Ask the kernel.

    pop     es
    pop     di
    pop     dx
    pop     cx
    ret                                 ; Carry Set if error occurred.
Init_GDT    endp



;
;
;
; Function: SetProcType
;
; Inputs:
;   None
;
; Outputs:
;   Returns one of the processor types PROC_8086, PROC_80286, PROC_80386,
;   or PROC_80486.
;
; Side Effects: none
;   The CY flag is cleared if this is an 80386 or 80486, signifying 32 bit
;   capability.
;
;
    public  SetProcType
SetProcType Proc    Near
;
; check for 8086
;
    Pushf
    Xor AX, AX          ; Set AX = 0
    Push    AX          ; Push 0
    Popf                ; Attempt to set flags = 0
    Pushf               ; Push flags
    Pop AX          ; Set AX = flags
    And AX, 0F000H      ; Set AX = bits 12-15 of flags
    Cmp AX, 0F000H      ; Compare flags to bits 12-15 on
    Je  Before_286      ; If all 4 flags on ==> before 286
    Mov AX, 07000H      ; Set AX = bits 12-14 on
    Push    AX          ; Push pattern
    Popf                ; Attempt to set flags = 7000h
    Pushf               ; Push flags
    Pop AX          ; Set AX = flags
    Test    AX, 07000H      ; Test flag bits 12-14
    Jz  Its_286         ; If bits 12-14 are zero ==> its an 80286
;
;   If none of the above tests successed, it must be an 80386
;
    Mov AX, PROC_80386
    Jmp Short xProcType
Its_286:
    Mov AX, PROC_80286
    Jmp Short xProcType
Before_286:
    Push    CX
    Mov AX, 0FFFFH      ; Set AX = All 1'S
    Mov CL, 33          ; Set CL = Shift Count = 33
    Shl AX, CL          ; Set AX = All 1'S Shifted 33 Left
    Pop CX
    Jnz Its_186         ; If AX <> 0 ==> Its an 80186
;
;   If it fails above test, must be an 8086 or 8088
;   AX = 0 (Indicates 8088 OR 8086)
;
    Jmp Short xProcType
Its_186:
    Mov AX, 1           ; SET AX = 186
xProcType:
    Mov [procType], AX      ; Set Global Proc Type variable.
    Popf                ; Out with AX = Processor Type
    Ret             ;
SetProcType Endp

;
;
;   A printf like routine for assembler language programs.
;
;   All variables are passed via the stack. i.e.:
;
;   Start of Sample Code.
;
;       Push    AX              ; set value for %u
;       Lea DX, String
;       Push    DX              ; Offset of the sting.
;       Call    printf          ; Call the display function.
;       Add SP,6                ; normalize the stack.
;       
;String DB  "This is a %u test string.",0
;
;   End of Sample Code.


    Public  printf
printf  Proc    Near
    Mov BP, SP          ; Make a stack frame in BP.
    Push    CX          ; Save regs used in this routine.
    Push    DX          ;
    Push    DI          ;       
    Push    si          ;
    Push    ES          ;
    Push    DS          ;
    Pop ES
    Lea DI, [PrintfBuffer]  ; Load the address of the work buffer.
    Push    DI
    Add BP, 2           ; Minus the return address (Near).
    Mov si, [BP]        ; Load string offset in si.
    Add BP, 2           ; Minus the previous parameter (Word).
String_Loop:
    Lodsb               ; Get a character from the string.
    Cmp AL, '%'         ; See if variable lead in char.
    Jne Chk_Slash       ; Brif not.
Call    Process_Percent         ; Go process this one.
    Jnc String_Loop         ; If carry is not set this was a valid variable.
Chk_Slash:
    Cmp AL, '\'         ; See if escape sequence lead in.
    Jne Chk_EOS         ; Brif not.
Call    Process_Escape          ; Go process the escape sequence.
    Jnc String_Loop         ; If Carry is not set then this is a valid escape.
Chk_EOS:
    Or  AL, AL          ; Is this the end of the string?
    Jz  sprintf_exit        ; Brif so.

    Stosb               ; Store the character.
    Jmp String_Loop         ; Get the next char.
sprintf_exit:
    Mov AL, 0           ; Set the termination char.
    Stosb               ; Store the character.
    Mov CX, DI          ; Save end pointer address in AX.
    Pop DI          ; Restore beginning of return buffer.
    Sub CX, DI          ; Minus the start location of the buffer.
    Call    DisplayMsg      ; DS:DI = PrintfBuffer, CX = Count.
    Pop ES          ; Restore used regs.
    Pop si          ;
    Pop DI          ;
    Pop DX          ;
    Pop CX          ;
    Ret
printf  Endp

;
;   This procedure handles the printf variable command codes.
;
Process_Percent Proc    Near
    Lodsb               ; Get the type byte.
    Cmp AL, '%'         ; See if its another percent.
    Je  Dont_Process        ; Bypass this one.
    Mov BH, AL          ; Copy char to BH.
    Mov BL, AL          ; Copy char to BL.
    And BH, 05FH        ; Make the variable in BH a capital.
    Cmp BH, 'C'         ; See if it a single char.
    Jne Chk_Str         ; Brif not.
    Mov AX, [BP]        ; Get the char from the stack frame.
    Add BP, 2           ; 'POP' the previous value.
    Stosb               ; Store the character.
    Jmp PP_Exit         ; Wrapup.
Chk_Str:
    Cmp BH, 'S'         ; See if it a string pointer.
    Jne Chk_Uint        ; Brif not.
    Push    DS          ; Save current data seg.
    Mov BX, [BP]        ; Get the string offset pointer from the stack frame.
    Add BP, 2           ; 'POP' the previous value.
    Mov DS, [BP]        ; Get the string segment pointer from the stack frame.
    Add BP, 2           ; 'POP' the previous value.
SS_Loop:
    Mov AL, DS:[BX]         ; Get the character.
    Or  AL, AL          ; Is this the terminator?
    Jz  SS_Exit         ; Brif so.
    Inc BX          ; Bump the index pointer.
    Stosb               ; Store the character.
    Jmp SS_Loop         ; Next char please.
SS_Exit:
    Pop DS          ; Restore dataseg.
    Jmp PP_Exit
Chk_Uint:
    Cmp BH, 'U'         ; See if unsigned Int.
    Jne Dont_Process        ; Brif not. I give up!.
    Mov AX, [BP]        ; Get the Value from the stack frame.
    Xor DX, DX          ; Clear MSW value.
    Add BP, 2           ; 'POP' the previous value.
    Test    BL, 20H         ; See if its a Lower Case 'u'.
    Jnz Not_LongU       ; Brif so.
    Mov DX, [BP]        ; Get the Value from the stack frame.
    Add BP, 2           ; 'POP' the previous value.
Not_LongU:
    Call    Bin_to_ASCII        ; Convert the binary number to an ASCII string.
    Jmp PP_Exit         ; Wrapup.

Dont_Process:
    Stc             ; Set so this char will be displayed.
    Ret
PP_Exit:
    Clc             ; Process complete.
    Ret
Process_Percent Endp

;
;   This procedure handles the printf escape codes.
;
Process_Escape  Proc    Near
    Ret
Process_Escape  Endp

;
;
;   Converts the DWord in DX:AX to an ASCII string.
;
;   In: DX:AX = Word to convert.
;
Bin_To_ASCII    Proc    Near        ; Format double precision count
    Push    si          ; Save si.
    Push    DS          ; And DS.
    Push    CS          ; Point DS to Code Seg.
    Pop DS          ; ...
    Lea si, BtoA_Buf_End    ; Set si = Offset(LAST BYTE IN FIELD)
    Dec si          ; Point to last char space.
    Push    si          ; Save Buffer end.
    Mov CX, Size BtoA_Buf   ; Get size of buffer.
Clear_Buf:
    Mov Byte Ptr DS:[si], 20H   ; Space out the buffer.
    Dec si          ; Next one backwards.
    Loop    Clear_Buf       ; Go for the count.
    Pop si          ; Restore buffer end.
    Mov CX, 3           ; Set CX = Digits per subfield = 3
FORMAT_NEXT:
    Mov BX, AX          ; Set BX = LSW(COUNT)
    Mov AX, DX          ; Set AX = MSW(COUNT)
    Xor DX, DX          ; Set DX,AX = MSW(COUNT)
    Div Ten             ; Set DX = MSW(COUNT) MOD 10
                    ;     AX = MSW(COUNT) / 10
    Xchg    AX, BX          ; Set AX = LSW(COUNT)
                    ;     BX = MSW(COUNT / 10)
    Div Ten             ; Set DX = COUNT MOD 10
                    ;     AX = LSW(COUNT / 10)
    Add DL, '0'         ; Set DL = DIGIT
    Mov Byte Ptr DS:[si], DL    ; Put digit in count field
    Dec si          ; Set si = Offset(NEXT POsiTION IN FIELD)
    Mov DX, BX          ; Set DX = MSW(COUNT / 10)
    Test    DX, DX          ; Test MSW(COUNT / 10)
    Jnz MORE_LEFT       ; If not zero ==> more left
    Test    AX, AX          ; Test remaining size digits
    Jz  COUNT_FORMATTED     ; If zero ==> count formatted
MORE_LEFT:
    Loop    FORMAT_NEXT         ; If not 3 digits yet ==> format next
    Mov Byte Ptr DS:[si], ','   ; Put comma to left of most recent digit
    Dec si          ; Set si = Offset(NEXT POsiTION IN FIELD)
    Mov CX, 3           ; Reset CX = Digits per subfield = 3
    Jmp FORMAT_NEXT         ; ==> Format next digit
COUNT_FORMATTED:
    Lea CX, BtoA_Buf_End    ; Get End offset.
    Inc si          ; Point to first char in string.
    Sub CX, si          ; Subtract current from end offset.
Print_String:
    Movsb               ; Store the character.
    Loop    Print_String
    Pop DS          ;
    Pop si          ;
    Ret             ;
Bin_To_ASCII    Endp


;
;   Displays messages at initialization time only.
;
;   In: DS:DI = Offset of message to display, CX =Length of message.
;
;   Out:    Nothing
;
    Public  DisplayMsg
DisplayMsg  Proc    Near
Ife DOS
    Mov AX, STDOUT      ; Set AX = Standard Out Handle value.
    Push    AX          ; Push Standard Out handle.
    Push    DS          ; Set address of message.
    Push    DI
    Push    CX          ; Set Length of message.
    Lea AX, [BytesWritten]  ; Get pointer to return byte count.
    Push    DS          ; Set address of Bytes Written variable.
    Push    AX
    Call    DosWrite
Else
    Push    BX
    Push    DX
    Mov DX, DI          ; Set DX = Offset to PrintfBuffer.
    Mov BX, DI          ; Setup Index reg.
    Add BX, CX          ; Add string length.
    Dec BX          ; Backup over the Null.
    Mov Byte Ptr [BX], 24H  ; Terminate with a $ sign.  
    Mov AH, 09H         ; Set DOS function code.
    Int 21H             ; Call DOS kernel.
    Pop DX
    Pop BX
Endif                   ;
    Ret
DisplayMsg  Endp


ICODE   Ends

    End


