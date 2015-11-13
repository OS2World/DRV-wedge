    Title   sStrat.Asm - Main driver entry point (Strategy).
    Page    , 132
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Functional Description
;   This file contains the strategy routine for the driver.
;

.Xlist
; Build Configuration Information.
    Include Build.Cfg

; Standard segment definitions
    Include segments.inc

; Standard IOCTL equates.
    Include ioctl.inc

; Standard DOS and OS/2 Driver header equates.
    Include devhdr.inc

; Build a linker control statement to include DOSCALLS.LIB
    includelib  doscalls.lib

; Standard OS/2 Defines (including DevHlp function numbers)
    Include os2equ.inc

.List

;
;-----------------------------------------------------------------------
;
;   Setup the Device Driver header based on OS.
;
Ife DOS

DevHeaderSeg    segment

; define the device header OS/2 style

    public  DevHdr
    DevHdr  SysDev <-1, DEV_CHAR_DEV+DEVLEV_1+DEV_30, cgroup:Strategy, 0>

DevHeaderSeg    ends

Else

    Org 0

DevHeaderSeg    Segment

; define the device header DOS style

    Public  DevHdr
    DevHdr  SysDev <-1, DEV_CHAR_DEV+DEVLEV_1+DEV_30+DEV_IOCTL+DEV_GIOCTL, CGROUP:Strategy, CGROUP:DOSIntr>

DevHeaderSeg    Ends

Endif


;
;-----------------------------------------------------------------------
;

_DATA   segment

; Defined in sdata.asm
    extrn   TestToolParms:dword         ; Pointer to current shared memory area.
    extrn   tmpBindStruc:word           ; Bind structure with harmless pointers
                                        ;   to OUR memory buffers
    extrn   top_lock:word               ; Next free memory lock handle.
    extrn   mem_locks:dword             ; Lock handles for memory locked by
                                        ;   IbmTool.

; define a far pointer for the Dev Help functions. it gets filled out at
; driver init time.

    public  DevHlp
DevHlp      DD  ?

; code ending location offsets and data ending location offsets go here.
; allocPhys() adds to the _DataEndOffset to increase the brk address.

    Public  CodeEndOffset
CodeEndOffset   DW  0

    Public  DataEndOffset
DataEndOffset   DW  0


If  DOS
;
; save SS and SP on entry to Driver Interrupt routine so that the driver
; runs on a local stack.

DOS_STACK_SIZE  equ 2048

SP_SAVE     DW  ?
SS_SAVE     DW  ?

    Public  DOSStack
DOSStack    DW  DOS_STACK_SIZE dup (?) ; DOS device stack
TOS_DOSSTack    label   near        ; Address of the Top of the DOS Stack.

packetPtr   DD  ?       ; remember the packet pointer

Endif

_DATA   ends

;
;-----------------------------------------------------------------------
;

_TEXT   Segment

; Routine defined in sInit.Asm

    Extrn   OSInit:near

; Routine defined in kioctl.asm


; Routine defined in DevIoctl.asm

    extrn   GenIoctl:near



;-----------------------------------------------------------------------
;
; Function: Strategy
;
; Inputs:
;   ES:BX - points to the driver request packet
;
; Outputs:
;   none
;
; Side Effects:
;   Handle device driver strategy calls from OS/2. 
;   INIT, OPEN, CLOSE and Generic are the only functions handled.
;   The INIT function call is only made once, by the operating
;   system.
;   The OPEN function is supported to allow other drivers
;   to see if the driver "exists". The generic function is supported
;   for general status and HW specific functions.
;   Status is returned in the request packet.
;
    Public  Strategy
Strategy    Proc    Far

If  DOS

; stash the packet pointer
    Mov Word Ptr [packetPtr], BX
    Mov Word Ptr [packetPtr+2], ES
    Ret

DOS_Strategy:

Endif

; Make sure reps increment by clearing the direction flag
;
    Cld
;
; an init packet?
;
    Cmp ES:[BX].PktCmd, CMDInit
    Je  strategy_init       ; go do the init if asked
;
; An open/close?
;
    Cmp ES:[BX].PktCmd, CMDOpen
    Je  strategy_open
    Cmp ES:[BX].PktCmd, CMDClose
    Je  strategy_close
;
; handle Generic IOCTLs
;
if DOS
    cmp     es:[bx].PktCmd, CMDIOCTLW
else
    cmp     es:[bx].PktCmd, CMDGenIOCTL
endif
    je      strategy_Ioctl
;
; flag this as a bad request (set done, error, unknown command)
; and return.
;
errExit:
;
    Mov ES:[BX].PktStatus, STDON+STERR+UNK_CMD
    Ret

; Open/Close both return OK. (This just shows that we exist, used in
; determining the driver name when multiple adapters are used.)

strategy_open:
    Mov ES:[BX].PktStatus, STDON
    Ret

;
; Use this opportunity to reset the shared data area pointer to a structure
;   with harmless pointers.  This way, we don't write to non-valid memory
;   when the application is gone.  Also, it unlocks the memory locked when
;   IbmTool binds to us.
;
strategy_close:
    mov     word ptr TestToolParms, offset DGROUP:tmpBindStruc
    mov     word ptr TestToolParms+2, ds

    mov     si, top_lock
    shl     si, 1
    shl     si, 1
    add     si, offset DGROUP:mem_locks
    
    push    bx

closeFreeLoop:
    sub     si, 4
    cmp     si, offset DGROUP:mem_locks
    jb      endFreeLoop
    mov     bx, [si]                        ; AX:BX lock handle
    mov     ax, [si]+2
    mov     dl, DH_UnlockSeg
    call    dword ptr [DevHlp]
    jmp     closeFreeLoop

endFreeLoop:
    pop     bx
    mov     top_lock, 0
    Mov     es:[bx].PktStatus, STDON
    ret
;
; do device driver initialization
;
strategy_init:

If  DOS
; setup the segment values in the device driver header. if DOS, these 
; values are not setup on entry.

;   Mov Word Ptr [DevHdr].SDevProtCS, CS
;   Mov Word Ptr [DevHdr].SDevRealCS, CS
;   Mov Word Ptr [DevHdr].SDevProtDS, DS
;   Mov Word Ptr [DevHdr].SDevRealDS, DS

endif

    Call    OSInit          ; will return with status set
                    ; in request packet.
    Ret


strategy_Ioctl:
    mov     word ptr es:[bx].PktStatus, STDON
If DOS
    les     bx, es:[bx+0Eh]             ; get data passed by pointer
Else
    cmp     es:[bx].GIOCategory,SupCatagory
    jne     errExit
    les     bx, es:[bx+13h]             ; Get pointer to data passed by ioctl.
Endif
    call    GenIoctl                    ; Will return with carry bit as status.
    jnc     doneIoctl

    or      word ptr es:[bx].PktStatus, STERR   ; Set error bit to indicate that
                                                ;   protocol hasn't bound yet.

doneIoctl:
    ret

Strategy    Endp


If  DOS

;*****************************************************************************
;
; Function: DOSIntr
;
; Inputs:
;   none
;
; Ouputs:
;   none
;
; Side Effects:
;   This is the DOS device driver interrupt entry point. It retrieves the
;   request packet stored in [packetPtr] and jumps into the Strategy 
;   routine code that is common to DOS and OS/2.
;
;
    Public  DOSIntr
DOSIntr Proc    Far

    Push    DS
    Push    AX
    Mov AX, DGROUP      ; Set AX = our Data seg.
    Mov DS, AX          ; Set DS to our Data seg.
;
; switch to the specified stack
;
    Cli             ; Interrupt protected the stack swap.
    Mov [SP_SAVE], SP       ; Save callers stack pointer,
    Mov [SS_SAVE], SS       ; And his stack seg in our DS space.
    Mov AX, DS          ; Now setup our stack in our data space.
    Mov SS, AX          ; 
    mov sp, offset DGROUP:TOS_DOSStack
    Sti             ; Ints on again.
;
; set SP to the top of the new stack and save the rest of the world
;
    Push    BX
    Push    CX
    Push    DX
    Push    DI
    Push    SI
    Push    ES
    Push    BP
;
; create a stack frame
;
    Mov BP, SP

; I know that the packet pointer has already been stashed

    Les BX, Dword Ptr [packetPtr]

; When Strategy returns, I want it to come back to me

    Call    Far Ptr DOS_Strategy    ; Call our normal strategy entry.

; restore the world from the current stack

    Pop BP
    Pop ES
    Pop SI
    Pop DI
    Pop DX
    Pop CX
    Pop BX

; restore the stack to the original SS and SP

    Cli             ; Ints off during stack swap.
    Mov SS, [SS_SAVE]
    Mov SP, [SP_SAVE]
    Sti
;
; restore trashed registers
;
    Pop AX
    Pop DS
    Ret
DOSIntr Endp

Endif

_TEXT   Ends

    End


