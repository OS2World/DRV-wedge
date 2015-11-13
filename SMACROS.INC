    SubTtl sMacros.Inc - Generic Model support macros.
;
; Copyright (C) 1989,1990 DWB Associates, All Rights Reserved
;

;
;   Assembly equate for processor type during assembly. This is not the
;   run-time equate for proccessor type.
;
p86 Equ (@Cpu AND 01H)      ; Set if this .8086 model.

;
; Processor Type Equates.
;
SIXTEEN_BIT     equ 0001H
PROC_TYPE_MASK      equ 0030H

PROC_8086       equ 0000H OR SIXTEEN_BIT
PROC_80286      equ 0010H OR SIXTEEN_BIT
PROC_80386      equ 0020H
PROC_80486      equ 0040H

;
; Disable and restore interrupts based on the value of IF at the time 
; interrupts were disabled. Popping into a register and testing for IF
; is a work around for some steps of the 80286. Those steps could
; potentially not restore IF correctly. disableIntr and restoreIntr are
; meant to be used in tightly nested pairs, i.e., :
;
;   disableIntr
;   disableIntr
;   ...
;   restoreIntr DX
;   restoreIntr DX
;
disableIntr Macro
    Pushf
    Cli
        Endm

;
; Restore interrupts using the supplied register, otherwise default to AX.
;
restoreIntr Macro   reg
    Local   exit
IFB <reg>
    Pop AX
    Test    AX, 200H
ELSE
    Pop reg
    Test    reg, 200H
ENDIF
    Jz  exit
    Sti
exit:
        Endm

;
; StartCrit - Is a spinlock macros for synchronizing and preventing access
;   to critical sections of code.
;
StartCrit   Macro   Semaphore
    Pushf
    Push    AX
    Cli
    Mov AX, 1       ; Set have semaphore flag.
@@:
    Xchg    Semaphore, AX   ; Exchange have flag for current semaphore.
    Cmp AX, 0       ; Did we get the semaphore?
    Jne @B          ; If not, Loop until we do.
    Pop AX
        Endm
        
;
; EndCrit - Removes the spinlock and if Interrupts were enabled before
;   StartCrit was called it will enable them.
;
EndCrit Macro   Semaphore
    Mov Semaphore, 0    ; Reset Semaphore.
    Push    BP
    Mov BP, SP      ; Establish pointer to the stack.
    Test    Word Ptr SS:[BP+2], 200H
    Jz  @F
    Sti
@@:
    Pop BP
    Add SP, 2       ; Remove flags from the stack.
        Endm

;
; Generic PANIC MACRO. The input 'line' is meant to be used as a positional
; indicator in the source code.
;
PANIC   macro   line
ife NOPANIC
    push    ax
    mov ax, line
    int 3
    pop ax
Endif
Endm



If  Trace
    Extrn   AddFuncTrace:Near
    Extrn   AddCallTrace:Near
Endif
If  DebugMon
    Extrn   Putchar:Near
Endif   

FuncTrace   Macro   Func
If  Trace or DebugMon
    Push    AX
    Mov AL, Func
If  DebugMon
    Call    Putchar
Endif
If  Trace
    Call    AddFuncTrace
Endif
    Pop AX
Endif   ; Trace or DebugMon.
        Endm

CallTrace   Macro   FCall
    Push    AX
    Mov AX, FCall
    Call    AddCallTrace
    Pop AX
        Endm


ifdef DOS

;/* Defines for device open/close.  */

SIZE_0          equ     0H
NORM_FILE       equ     0H
EXIST_ONLY      equ     0001H
WO_DENY_RW_PRIV equ     0091H
RW_DENY_NONE_PRIV   equ     00C2H
READ_ONLY       equ     0040H
RESERVED_DW_0       equ     0H

;
; convert a real mode segment:offset to a 32 bit physical address.
; ENTRY: dx - seg
;        si - offset
; EXIT:  dx:ax
;       CX trashed
SEGOFF_PHYS MACRO
    mov ax, dx
    mov cx, 4
    shl ax, cl
    mov cx, 12
    shr dx, cl
    add ax, si
    adc dx, 0
ENDM
endif


;-----------------------------------------------------------------------------
; bcopy - copies n bytes from src to dest.
;
; ENTRY:
;       ds:[si] - source ptr
;       es:[di] - destination ptr
;       cx      - byte count
;       dl      - low bit indicates indicates 386 (0) or 286 (1)
;
; EXIT:
;       cx      - 0
;       src     - end of source data
;       dest    - end of destionation data
;       dl      - trashed

bcopy       Macro   srcSeg
    Local   moveWords

    Cld             ; Forward copy.

    Test    DL, SIXTEEN_BIT     ; Is this a sixteen bit copy?
    Jnz     moveWords       ; Brif so.

    Push    CX          ; Save original count.
.386
    Shr CX,2            ; Set to Dword aligned count.
    Rep Movs Dword Ptr ES:[DI], Dword Ptr srcSeg:[SI] ; Copy the Count of Dwords.
.8086
    Pop CX          ; Set CX to the original count.
    And CX,3            ; Mask off Dword Count.
moveWords:
    Shr CX,1            ; Bump off the Odd Byte and save in carry.
    Rep Movs Word Ptr ES:[DI], Word Ptr srcSeg:[SI] ; Copy the last word if any.
    Adc CX,0            ; Get the carry value in CX.
    Rep Movs Byte Ptr ES:[DI], Byte Ptr srcSeg:[SI] ; Copy the Odd byte first.
Endm

;-----------------------------------------------------------------------------
; bcopy32 - copies n bytes from src to dest. this is an assembly function 
;   only. it also assumes at least a 80386. this macro could be used to move
;   data in a flat 4 Gig address space.
;
; ENTRY:
;       srcSeg:[esi]    - source ptr
;       es:[edi]        - destination ptr
;       ecx         - byte count
;
; EXIT:
;       srcSeg:[esi]    - end of source data
;       es:[edi]    - end of destionation data
;       ecx     - 0

bcopy32 Macro   srcSeg
    Cld             ; Forward copy.
    Push    ECX         ; Save original count.
    Shr ECX,2           ; Set to Dword aligned count.
    Rep Movsd ES:[EDI], srcSeg:[ESI] ; Copy the Count of Dwords.
    Pop ECX         ; Set ECX to the original count.
    And ECX,3           ; Make off Dword Count.
    Shr ECX,1           ; Bump off the Odd Byte and save in carry.
    Rep Movsw ES:[EDI], srcSeg:[ESI] ; copy the last word if any.
    Adc ECX,0           ; Get the carry value in CX.
    Rep Movsb ES:[EDI], srcSeg:[ESI] ; Copy the Odd byte first.
Endm


;-----------------------------------------------------------------------------
; iCopy - copies n bytes from io port in DX to ES:DI.
;
; ENTRY:
;       ES:[DI] - Destination ptr
;       AX  - Processor type.
;       CX  - byte count
;       DX  - Port Number to In from.
;
; EXIT:
;       CX  - 0
;       ES:DI   - end of source data
;       DX  - unchanged

iCopy       Macro
    Local   moveBytes, InWLoop, ChkBIcopy, InBLoop, IcopyDone
    Cld             ; Forward copy.
Ife p86
    Test    AL, PROC_8086       ; should we use 8 bit xfers?
    Jnz     moveBytes       ; Brif so.
    Shr CX,1            ; Bump off the Odd Byte and save in carry.
    Rep Insw            ; Copy the words if any.
    Adc CX,0            ; Get the carry value in CX.
moveBytes:
    Rep Insb            ; Copy the Odd byte if any.
Else
    Test    AL, PROC_8086       ; should we use 8 bit xfers?
    Jnz     ChkBIcopy       ; Brif so.
    Shr CX,1            ; Bump off the Odd Byte and save in carry.
    Jcxz    ChkBIcopy       ; If no words do the byte copy.
InWLoop:
    In  AX, DX          ; Get a word from the port.
    Stosw               ; Save the word in the buffer.
    Loop    InWLoop         ; Go for the count.
    Adc CX,0            ; Get the carry value in CX.
ChkBIcopy:
    Jcxz    IcopyDone       ; Exit out if nothing left.
InBLoop:
    In  AL, DX          ; Get a byte from the port.
    Stosw               ; Save the byte in the buffer.
    Loop    InBLoop         ; Go for the count.
IcopyDone:
Endif
Endm

;-----------------------------------------------------------------------------
; oCopy - copies n bytes from DS:SI to io port in DX.
;
; ENTRY:
;       DS:[SI] - source ptr
;       AX  - Processor type.
;       CX  - byte count
;       DX  - Port Number to Out to.
;
; EXIT:
;       CX  - 0
;       DS:SI   - end of source data
;       DX  - unchanged

oCopy       Macro
    Local   moveBytes, OutWLoop, ChkBOcopy, OutBLoop, OcopyDone
    Cld             ; Forward copy.
Ife p86
    Test    AL, PROC_8086       ; should we use 8 bit xfers?
    Jnz     moveBytes       ; Brif so.

    Shr CX,1            ; Bump off the Odd Byte and save in carry.
    Rep Outsw           ; Copy the words if any.
    Adc CX,0            ; Get the carry value in CX.
moveBytes:
    Rep Outsb           ; Copy the Odd byte if any.
Else
    Test    AL, PROC_8086       ; should we use 8 bit xfers?
    Jnz     ChkBOcopy       ; Brif so.
    Shr CX,1            ; Bump off the Odd Byte and save in carry.
    Jcxz    ChkBOcopy       ; If no words do the byte copy.
OutWLoop:
    Lodsw               ; Load up a word in AX.
    Out DX, AX          ; Send it out.
    Loop    OutWLoop        ; Go for the count.
    Adc CX,0            ; Get the carry value in CX.
ChkBOcopy:
    Jcxz    OcopyDone       ; Exit out if nothing left.
OutBLoop:
    Lodsb               ; Load up a byte in AL.
    Out DX, AL          ; Send it out.
    Loop    OutBLoop        ; Go for the count.
OcopyDone:
Endif
Endm

;-----------------------------------------------------------------------------
; sCopy - copies n bytes from parameter list on stack to ss:[sp]
;
; ENTRY:
;               dx      - offset to plist on stack 
;               cx      - byte count
;                       
; EXIT:
;       CX  - 0
;               dx      - unchanged
;       DS  - unchanged
;       si,di   - unchanged
;               ss:sp   - points to new data on stack
;               bp      - trashed
        
sCopy           macro
                cld
                mov     bx,ss
                mov     ax,ds
                mov     es,bx
                mov     ds,bx
                mov     di,sp
                sub     di,cx
                sub     sp,cx
                mov     si,dx
                rep     movsb
                mov     ds,ax
                endm
