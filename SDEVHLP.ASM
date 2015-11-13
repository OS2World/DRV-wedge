    Title   sDevHlp.Asm - Device Help emulator for DOS device drivers.
    Page    ,132
;
; Copyright (C) 1989,1990 DWB Associates, All Rights Reserved
;
; Functional Description
;   The routines in this file reproduce the functionality of the OS/2
;   Device Help routines for use in DOS Device Drivers.
;


; Build Configuration Information.
    include Build.Cfg

If  DOS     ; Make sure it is not included on OS/2 makes.

; Standard segment definitions
    include Segments.inc

; include Device Help Equates.
    include devhlp.inc

;
;-----------------------------------------------------------------------
;

_DATA   segment

;
; use a variable to store HW specific IO Base addresses and IVEC offsets.
; Platforms that use the same hardware, but at different addresses, can
; override the values at config time.
;
    public  int1EOI
int1EOI             dw  INT_1EOIR
    public  int1IMR
int1IMR             dw  INT_1IMR
    public  int2EOI
int2EOI             dw  INT_2EOIR
    public  int2IMR
int2IMR             dw  INT_2IMR
    public  intBaseVec
intBaseVec          dw  INT_BASE
    public  altIntBaseVec
altIntBaseVec       dw  INT_BASE_ALT

    public  AllocAmount
AllocAmount         dw  0               ; Amount of AllocPhys memory.

;
; maintain a table of old IRQ vectors used for chaining interrupts. save
; enough room for 16 IRQ numbers and the Dword interrupt vector.
;
If  DebugBP
    public  IRQTab
endif
IRQTab              dd  16 dup(0)


_DATA   ends


;
;-----------------------------------------------------------------------
;

_TEXT   segment

; define the DevHlp jump table for DOS. These functions simulate the OS/2
; DEVHELP functions and are searched by the DevHlp opcode.

    align   4

    public  DevHlpJmpTab
DevHlpJmpTab    label   byte
    DevHlpJmp   <DevHlp_EOI,                offset CGROUP:DH_EOI>
    DevHlpJmp   <DevHlp_PhysToGDTSelector,  offset CGROUP:DH_Nop>
    DevHlpJmp   <DevHlp_PhysToUVirt,        offset CGROUP:DH_PhysToUVirt>
    DevHlpJmp   <DevHlp_PhysToVirt,         offset CGROUP:DH_PhysToVirt>
    DevHlpJmp   <DevHlp_VirtToPhys,         offset CGROUP:DH_VirtToPhys>
    DevHlpJmp   <DevHlp_UnPhysToVirt,       offset CGROUP:DH_Nop>
    DevHlpJmp   <DevHlp_AllocGDTSelector,   offset CGROUP:DH_Nop>
    DevHlpJmp   <DevHlp_SetIRQ,             offset CGROUP:DH_Nop>
    DevHlpJmp   <DevHlp_UnSetIRQ,           offset CGROUP:DH_Nop>
    DevHlpJmp   <DevHlp_AllocPhys,          offset CGROUP:DH_AllocPhys>
    DevHlpJmp   <DevHlp_FreePhys,           offset CGROUP:DH_Nop>
;   DevHlpJmp   <DevHlp_SetTimer,           offset CGROUP:DH_SetTimer>
;   DevHlpJmp   <DevHlp_ResetTimer,         offset CGROUP:DH_ResetTimer>
    DevHlpJmp   <0,         0>



;*****************************************************************************
;
; Function: DevHlp
;
; Inputs:
;   DL - device help function code
;   as well as a variety of other registers, function code dependent
;
; Outputs:
;   returns the status of the function code handler, or CY set if none.
;
; Side Effects:
;   This is the interface function for the DOS simulation of OS/2 device
;   helper routines. It searches the _DevHlpJmpTab table for an opcode
;   match, and then invokes the associated function.
;
;   DOS only OS/2 emulation routines. The Device Helper entry point is not
;   passed in via the device driver header in DOS, rather it must be
;   hardcoded and supplied by the DOS driver. At this point, not all of the
;   OS/2 DevHlp functions are supported, only those that make sense and those
;   that ease the porting effort. The DevHlp entry point (__DevHlp) compares
;   the incoming function in DL and calls the appropriate handler. If the
;   handler is not found, then PANIC is executed. Following is the current
;   list of DevHlp functions supported:
;
;       DevHlp_EOI
;       DevHlp_PhysToGDTSelector
;       DevHlp_PhysToUVirt
;       DevHlp_VirtToPhys
;       DH_AllocGDTSelector
;       DH_SetIRQ
;       DH_UnSetIRQ
;       DH_AllocPhys
;       DH_FreePhys
;       DH_SetTimer
;       DH_ResetTimer
;
;

    public DeviceHelp
DeviceHelp  proc    far
    push    bp
    push    es                          ; save the registers used
    push    di
;
; Setup to interogate the jump table
;
    mov     di, CGROUP
    mov     es, di                      ; We have to setup es:di.
    lea     di, DevHlpJmpTab

; Determine which DevHlp function to call.

FuncCodeLoop:

; If the function pointer from the table is NULL, then PANIC

    cmp     dl, es:[di].DevHlpFuncCode
    je      FoundFuncCode
    cmp     es:[di].DevHlpFuncptr, 0
    je      DH_Panic
    add     di, Size DevHlpJmp
    jmp     short FuncCodeLoop

FoundFuncCode:

; Save the function pointer, restore the register set, and call the
; indicated function.

    mov     bp, es:[di].DevHlpFuncptr
    pop     di
    pop     es
    call    bp
ExitDevHlp:
    pop     bp
    ret

DH_Panic:
If  Debugbp
    push    ax
    mov     ax, 31
    int     3
    pop     ax
endif
    pop     di
    pop     es
    stc                                 ; Indicate error on DevHlp call.
    jmp     short ExitDevHlp

DeviceHelp  endp

;*****************************************************************************
;
;   DH_AllocPhys - allocate physical memory from the start of the init data
;                  segment.
;
;   In:     BX = Size to allocate,
;           unimplemented: DH = 0 above 1meg, DH = 1 below 1meg.
;
;   Out:    Carry cleared and AX:BX = Physical address if successful.
;
;   Note: This call cannot allocate over 64K total.
;
;   Note: THE MEMORY ALLOCATED CANNOT BE ACCESSED DURING INITIALIZATION.
;
    public  DH_AllocPhys
DH_AllocPhys    proc    near
    push    di
    push    si
    push    bx                          ; save input alloc size
    mov     si, offset CGROUP:ICode     ; Get end of resident code.
    add     si, AllocAmount             ; Plus the size previously allocated.
    mov     di, si
    And     si, 0FFF0h                  ; Paragraph align the address.
    add     si, 10h                     ; Round up one paragraph.
    mov     cx, si
    sub     cx, di
    call    DH_VirtToPhys
    mov     si, bx                      ; save the physical LSW
    pop     bx                          ; restore input alloc size
    add     bx, cx                      ; add on paragraph alignment bytes
    add     word ptr AllocAmount, BX    ; Save this allocation size.
    mov     bx, si                      ; restore phys LSW to BX
    pop     si
    pop     di
    ret
DH_AllocPhys    endp


;*****************************************************************************
;
;   DH_EOI
;
;   Perform a Non-Specific EOI to the 8259 PIC (both if cascaded).
;
;   In: AL = IRQ Number (0 - F)
;
;   Out:    Nothing.
;
    public  DH_EOI
DH_EOI      proc    near
    push    dx
    mov     dl, al                      ; move IRQ number to dl.
    mov     al, NONSPEC_EOI             ; Set al = non-specific EOI
; If on the slave, then do it first for level sensitive machines (MCA).
    cmp     dl,8                        ; Is this on the slave?
    Jb      doMasterEoi                 ; Brif not.
    mov     dx, Int2EOI                 ; EOI the Slave first.
    Out     dx, al
doMasterEoi:
; send an EOI to the master
    mov     dx, Int1EOI                 ; EOI the Master PIC.
    Out     dx, al
    pop     dx
    clc
    ret
DH_EOI      endp


;*****************************************************************************
;
;   NOP function, just clear carry and return
;
    public  DH_NOP
DH_NOP  proc near
    clc
    ret
DH_NOP  endp


;*****************************************************************************
;
;   DH_PhysToUVirt - Convert Physical address in ax:BX to a Virtual address
;       returned in es:BX.
;
;   In: ax:bx = Physical address, cx = Length, dh = Request Type.
;
;   Out:    es:bx = segment:offset.
;
    public  DH_PhysToUVirt
DH_PhysToUVirt  proc near
    push    ax
    push    cx
    push    dx                          ; Save scratched regs.
    mov     dx, bx                      ; Copy LSW of address in dx.
    and     dx, 0FH                     ; Save the Low nibble.

    mov     cl, 4                       ; Setup shift count.
    shr     bx, cl                      ; Divide LSW by 16.
    mov     cl, 12                      ; Setup shift count.
    sal     ax, cl                      ; Multiply MSW by 4096.
    or      bx, ax                      ; Create segment value in bx.
    mov     es, bx                      ; Setup es:bx for return.
    mov     bx, dx                      ;
    pop     dx                          ; Restore scratched.
    pop     cx                          ;
    pop     ax                          ;
    clc                                 ; Indicate success.
    ret
DH_PhysToUVirt  endp


;*****************************************************************************
;
;   DH_PhysToVirt - Convert Physical address in ax:bx to a Virtual address
;       returned in ds:si if dh = 0, or es:di if dh =1.
;
;   In: ax:bx = Physical address, cx = Length, dh = Request Type.
;
;   Out:    es:bx = segment:offset.
;
    public  DH_PhysToVirt
DH_PhysToVirt   proc    near
    push    dx
;
; call PhysToVirt to do the work, result comes back in es:bx
;
    push    bx
    push    es
    call    DH_PhysToUVirt
;
    cmp     dh, 0                       ; return result in ds:si?
    jne     Do_esdi                     ; Brif not.
    push    es                          ; move es to...
    pop     ds                          ; ds.
    mov     si, bx                      ; Copy offset ot si.
    jmp     short ExitPhysToVirt

Do_esdi:
    add     SP, 2                       ; Remove saved es off the stack.
    mov     di, bx                      ; move offset to di.

ExitPhysToVirt:
    pop     bx
    pop     dx                          ; Restore scratch regs.
    clc                                 ; Indicate success.
    ret
DH_PhysToVirt   endp


;*****************************************************************************
;
;   DH_VirtToPhys - return a virtual address in ax:bx.
;
;   In: ds:si = Virtual address.
;
;   Out:    ax:bx = Physical address.
;
    public  DH_VirtToPhys
DH_VirtToPhys   proc    near
    push    cx
    mov     bx, ds                      ; Set bx = Current ds.
    mov     ax, ds                      ; Set ax = Current ds.
    mov     cx, 4                       ; Set shift count.
    shl     bx, cl                      ; Multiply segment * 16.
    mov     cx, 12                      ; Set shift count.
    shr     ax, cl                      ; Divide segment / 4096.
    add     bx, si                      ; add offset.
    adc     ax, 0                       ; Roll over if any.
    pop     cx
    clc
    ret
DH_VirtToPhys   endp




;*****************************************************************************
;
;   MaskIntr - mask an interrupt level at the 8259 (PIC).
;
;   In: bx = IRQ Number.
;
;   Out:    Nothing.
;
    public  MaskIntr
MaskIntr    proc    near
    push    ax
    push    cx
    push    dx
    cmp     bx, 7                       ; Is this on the First PIC.
    jbe     MasterPIC                   ; Brif so.

    sub     bx, 8                       ; offset to second PIC IRQ numbers.
    mov     dx, int2IMR                 ; Set address of the Slave 8259 mask port.
    jmp     short MaskIRQ

MasterPIC:
    mov     dx, int1IMR                 ; Set address of the Master 8259 mask port.

MaskIRQ:
    mov     cx, bx                      ; move IRQ number to cx.
    and     cx, 7H                      ; Mask off any stray bits.
    mov     BL, 1                       ; Create a shift mask.
    shl     BL, cl                      ; Shift out the mask.

    pushf                               ; Save Int state.
    cli                                 ; Shut Ints off.
    In      al, dx                      ; Read old Int mask.
    nop
    nop
    nop
    nop                                 ; Timing delays.
    or      al, BL                      ; or in the new mask bit.
    out     dx, al                      ; Send the new mask to the PIC.
    pop     ax                          ; Restore Interrupt state.
    test    ax, 200H                    ; Were Interrupts on.
    jz      @F                          ; Bypass STI if not.
    sti                                 ; Ints on.
@@:
    pop     dx
    pop     cx
    pop     ax
    ret
MaskIntr    endp

;*****************************************************************************
;
;   UnMaskIntr - UnMask an interrupt level at the 8259 (PIC).
;
;   In: bx = IRQ Number.
;
;   out:    Nothing.
;
    public  UnMaskIntr
UnMaskIntr  proc    near
    push    ax
    push    cx
    push    dx
    cmp     bx, 7                       ; Is this on the First PIC.
    jbe     UnMasterPIC                 ; Brif so.

    sub     bx, 8                       ; offset to second PIC IRQ numbers.
    mov     dx, int2IMR                 ; Set address of the Slave 8259 mask port.
    jmp     short UnMaskIRQ

UnMasterPIC:
    mov     dx, int1IMR                 ; Set address of the Master 8259 mask port.

UnMaskIRQ:
    mov     cx, bx                      ; move IRQ number to cx.
    and     cx, 7H                      ; Mask off any stray bits.
    mov     BL, 1                       ; Create a shift mask.
    shl     BL, cl                      ; Shift out the mask.
    not     BL                          ; Complement the mask.

    pushf                               ; Save Int state.
    cli                                 ; Shut Ints off.
    In      al, dx                      ; Read old Int mask.
    nop
    nop
    nop
    nop                                 ; Timing delays.
    and     al, BL                      ; or in the new mask bit.
    out     dx, al                      ; Send the new mask to the PIC.
    pop     ax                          ; Restore Interrupt state.
    test    ax, 200H                    ; Were Interrupts on.
    jz      @F                          ; Bypass STI if not.
    sti                                 ; Ints on.
@@:
    pop     dx
    pop     cx
    pop     ax
    ret
UnMaskIntr  endp


_TEXT       ends

endif   ; DOS   Matches Top of Files "If DOS".

        end


