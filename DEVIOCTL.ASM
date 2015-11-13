    Title   DevIoctl.Asm - support for "binding" to the Ibm Test Tool
    Page    , 132
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Functional Description
;   This file contains the General Ioctl routine for the driver.  This
;   ioctl routine fills in the passed data buffer with far pointers to
;   internal structures, functions and to structures and functions of
;   the mac bound to this "protocol".  Carry is set if error.
;

.Xlist
; Build Configuration Information.
    Include Build.Cfg

; Standard segment definitions
    Include segments.inc

; Standard standard structures
    Include sStrucs.inc

; Standard IOCTL equates.
    Include ioctl.inc

; Standard IOCTL equates.
    Include wedge.inc

; Standard DOS and OS/2 Driver header equates.
    Include devhdr.inc

; OS/2 specific strucs and equates.
    Include OS2Equ.Inc

; DevHlp defines
    Include devhlp.inc

.List


;
;-----------------------------------------------------------------------
;

_DATA   segment


; Data defined in sData.Asm.

    extrn   MACsBound:word          ; number of MACs we are bound to
    extrn   MACPtrs:word            ; ptrs to useful things in MAC
    extrn   MCC:word                ; copy of MAC's CommonChar
    extrn   MUDsTable:word          ; copy of MAC's Upper Dispatch table
    extrn   WCC:word                ; copy of our CommonChar
    extrn   DevHlp:dword            ; pointer to devhlp functions
    extrn   xmit_desc:word          ; transmit descriptor used in stress
    extrn   txUseGDT:word           ; copy of UseGDT flag in area shared with
                                    ;  IbmTool
    extrn   txHandle:word           ; txChain handle, used by stress transmits


    public  ioctl_table, mcc_copy_ptr, data_copy_ptr, command_req_ptr
    public  gen_req_ptr, virt_to_phys_ptr, lock_memory
ioctl_table     equ     $
mcc_copy_ptr    dw      offset CGROUP:MccCopy
data_copy_ptr   dw      offset CGROUP:DataCopy
gen_req_ptr     dw      offset CGROUP:WGenReq
command_req_ptr dw      offset CGROUP:CommandReq
virt_to_phys_ptr dw     offset CGROUP:CvtVirtToPhys
xmit_stress_frame dw    offset CGROUP:xmitStressFrame
lock_memory     dw    offset CGROUP:lockMemory
MAX_IOCTL_CMD   equ    ($-ioctl_table) / 2

        public  command_table
command_table   equ     $
                dw      offset CGROUP:WXmitChain
                dw      offset CGROUP:WXferData
                dw      offset CGROUP:WRcvRelease
                dw      offset CGROUP:WIndOff
                dw      offset CGROUP:WIndOn
MAX_COMMAND     equ     ($-command_table) / 2


        public TestToolParms, header_length, length_offset, data_size
        public frames_left, size_increment, max_frame, max_data
        public top_lock, mem_locks, mem_gdts
TestToolParms   dd      0               ; Pointer to test tool parameters
header_length   dw      0               ; Length of a frame's header
length_offset   dw      0               ; Offset of the length field in the
                                        ;   frame header
data_size       dw      0               ; Size of frame to transmit next
frames_left     dd      0               ; Number of frames left to transmit
                                        ;   in this stress test (copy)
size_increment  dw      0               ; Incremental for data size.  if the
                                        ;   frames are increasing +1, if the
                                        ;   frames are decreasing -1
max_frame       dw      0               ; Maximum frame size (including header)
max_data        dw      0               ; Maximum data size in a frame
top_lock        dw      0               ; Current lock open for business
mem_locks       db      MAX_LOCKS*4 dup (0) ; Lock handles for locking memory
                                            ;   in place
mem_gdts        db      MAX_LOCKS*2 dup (0) ; GDT's for locked memory selectors

_DATA   ends

;
;-----------------------------------------------------------------------
;

_TEXT   Segment

    extrn   WXmitChain:near
    extrn   WXferData:near
    extrn   WRcvRelease:near
    extrn   WIndOff:near
    extrn   WIndOn:near
    extrn   WGenReq:near

;-----------------------------------------------------------------------
;
; Function: GenIoctl()
;
; Inputs:
;   ES:BX - points to the buffer to fill with our pointers
;
; Outputs:
;   Carry is set if error, clear if not.  Only error condition is if
;   not yet bound.
;
;
    Public  GenIoctl
GenIoctl    Proc    Near
    push    bx
    push    cx
    push    dx
    push    ds
    push    es
    push    si
    push    di

    cmp     MACsBound, 0
    jne     ParseIoctl
    stc
    jmp     DoneIoctl

ParseIoctl:
    mov     si, es:[bx].ioctl_cmd
    cmp     si, MAX_IOCTL_CMD
    jb      DoIoctl

DoIoctl:
    shl     si, 1
    add     si, offset DGROUP:ioctl_table
    call    [si]

    clc

DoneIoctl:
    pop     di
    pop     si
    pop     es
    pop     ds
    pop     dx
    pop     cx
    pop     bx
    ret

GenIoctl Endp


;-----------------------------------------------------------------------
;
; Function: MccCopy()
;
; Inputs:
;   ES:BX - points to the ioctl packet, containing pointer to buffer to
;       copy Mcc into.
;
;
    Public  MccCopy
MccCopy     Proc    Near

    mov     cx, word ptr es:[bx].data_from
    mov     word ptr TestToolParms, cx
    mov     cx, word ptr es:[bx].data_from+2
    mov     word ptr TestToolParms+2, cx

    les     di, es:[bx].data_to
    mov     si, offset DGROUP:MCC
    mov     cx, [si]
    cld
    rep movsb

    ret

MccCopy Endp



;-----------------------------------------------------------------------
;
; Function: DataCopy()
;
; Inputs:
;   ES:BX - points to the ioctl packet, containing pointer to buffer to
;       copy data into.
;
;
    Public  DataCopy
DataCopy     Proc    Near

    push    ds

    mov     di, bx                                      ; es:di = es:bx

if OS2
    mov     ax, word ptr es:[di].data_to+2              ; selector to be locked
    mov     bh, 0                                       ; short-term lock
    mov     bl, 0                                       ; block until locked
    mov     dl, DH_LockSeg
    call    dword ptr [DevHlp]                          ; lock it
endif

    mov     cx, word ptr es:[di].ioctl_length           ; get length
    lds     si, dword ptr es:[di].data_from             ; ds:si -> source
    les     di, dword ptr es:[di].data_to               ; es:di -> destination
    cld
    rep     movsb                                       ; copy

    pop     ds

if OS2
    mov     dl, DH_UnlockSeg                            ; ax:bx still has handle
    call    dword ptr [DevHlp]                          ; unlock it
endif

    ret

DataCopy Endp


;-----------------------------------------------------------------------
;
; Function: CommandReq()
;
; Inputs:
;   ES:BX - points to the ioctl packet, containing pointer to buffer to
;       get parameters for the command.
;
;
    Public  CommandReq
CommandReq     Proc    Near

    mov     si, es:[bx].ioctl_length
    cmp     si, MAX_COMMAND
    jae     bad_commandreq
    shl     si, 1
    add     si, offset DGROUP:command_table
    call    [si]

bad_commandreq:
    ret

CommandReq Endp



;-----------------------------------------------------------------------
;
; Function: CvtVirtToPhys()
;
; Inputs:
;   ES:BX - points to the ioctl packet, containing pointer to buffer to
;       get parameters for the command.
;
;
    Public  CvtVirtToPhys
CvtVirtToPhys   Proc    Near

    push    cx
    push    dx
    push    ax
    push    bx
    push    es
    push    si

    mov     si, word ptr es:[bx].data_from
    mov     ax, ds
    mov     ds, word ptr es:[bx].data_from+2
    mov     es, ax
    mov     dl,DH_VirtToPhys

if DOS
	ASSUME es:DGROUP
endif
    call    dword ptr es:[DevHlp]     ; convert virtual address to phys
if DOS
	ASSUME es:NOTHING
endif
                                        
    pop     si
    pop     es

    mov     dx, bx
    mov     cx, ax
    pop     bx
    pop     ax

    mov     word ptr es:[bx].data_from, dx  ; return phys addr in same place
    mov     word ptr es:[bx].data_from+2, cx

    pop     dx
    pop     cx

    ret

CvtVirtToPhys Endp




;----------------------------------------------------------------------------
;
; xmitStressFrame - transmits a BUNCH of frames
;
;----------------------------------------------------------------------------
    public xmitStressFrame
xmitStressFrame proc    near

    mov     si, offset DGROUP:MACPtrs               ; ds:si -> MACPtrs
    mov     di, bx                                  ; es:di -> ioctl_packet
                                                    ;   (was es:bx ptr)

    push    es                                      ; save frame pointer
    push    di
    les     di, testToolParms
    mov     ax, es:[di].UseGDT                      ; Save the UseGDT variable
    mov     txUseGDT, ax                            ;   for later
    mov     ax, es:[di].HeaderLen                   ; Save the header length
    mov     header_length, ax                       ;   for later

    mov     ax, word ptr es:[di].StressCount        ; #frames left to transmit
    mov     word ptr frames_left, ax
    mov     ax, word ptr es:[di].StressCount+2
    mov     word ptr frames_left+2, ax

    les     di, dword ptr [si].MP_MACsc_off         ; Get maximum frame size
    mov     bx, es:[di].MscMaxFrame                 ;   (includes header)
    mov     max_frame, bx
    pop     di                                      ; restore the frame pointer
    pop     es

    sub     bx, header_length                       ; Calculate maximum amount
    mov     max_data, bx                            ;   of data allowable in a
                                                    ;   frame (max_size-header)

;-------------------------------------------------------------------------------
;
; The scheme is to implement a zig-zag frame data size ranging from zero to
; the maximum.  The easiest way was to always end the last frame as having zero
; data, and the last (max_frame+1) frames decreasing in size to that zero data
; length frame.  If the last (max_frame+1) frames were decrementing, then
; the frames from 2*(max_frame+1) to (max_frame+1+1) were incrementing in data
; size.  This means that if the result of a divide of (frames_left-1) by
; (max_data+1) is even, then frame size decrements, and vice-versa.  In
; addition, the current frame size is easily calculated.  If the current set is
; decrementing, then the current frame size is the remainder of the divide.  If
; the current set is increasing, then the current_size is max_data MINUS the
; remainder.
;
;-------------------------------------------------------------------------------

    mov     bx, max_data                            ; Maximum data in frame
    inc     bx                                      ;   plus one
    mov     ax, word ptr frames_left                ; High word of stress - 1
    sub     ax, 1
    mov     ax, word ptr frames_left+2
    sbb     ax, 0
    xor     dx, dx
    div     bx                                      ; Do high word div, throw
                                                    ;   away result high word.
                                                    ;   Only interested in
                                                    ;   whether odd/even.
    mov     ax, word ptr frames_left
    div     bx
    mov     data_size, dx                           ; DX is remainder of div,
                                                    ;   and ranges from 0 to
                                                    ;   maximum data size.  This
                                                    ;   is why we divided by
                                                    ;   max data size + 1.

    mov     size_increment, -1                      ; Init increment as negative
    test    ax, 1                                   ; Is the result odd?
    jz      frames_increasing                       ; If so, inc and size stay
    mov     size_increment, -1                      ; Else increment is positive
    mov     ax, data_size                           ; And Current data size is:
    neg     ax                                      ;   -remainder + max_data
    add     ax, max_data
    mov     data_size, ax
frames_increasing:

    mov     bx, word ptr es:[di].data_to            ; AX:BX physical address of
    mov     ax, word ptr es:[di].data_to+2          ;   frame (ax is high word)
    mov     dx, es:[di].ioctl_length                ; Save offset to length
    mov     length_offset, dx                       ;   field in header
    mov     cx, 1024                                ; CX: number of  frames to
                                                    ;   try to transmit

    cmp     cx, word ptr frames_left                ; Is 1024 > frames_left?
    jbe     frame_full_ptr                          ; if not, get frame ptr
    cmp     word ptr frames_left+2, 0               ; Anything in upper word?
    jne     frame_full_ptr                          ; if so, get frame ptr
    mov     cx, word ptr frames_left                ; Else only xmit frames we
                                                    ;   should xmit.
    cmp     cx,0                                    ; initial 0 check for loop
    jne     frame_full_ptr
    jmp     doneStressFrame

frame_full_ptr:
    les     di, es:[di].data_from                   ; ES:DI ptr to a full frame
    

;
; inputs for loop
;   ES:DI is pointer to beginning of frame
;   AX:BX is physical address (32-bits) of frame (ax is high word)
;   CX is number of frames to attempt transmitting
;   DS: Wedge's data segment for these variables
;       txUseGDT is a copy of the IbmTool shared info area UseGDT member
;       frames_left is copy of the IbmTool shared info area StressCount member
;       length_offset is the offset of the length field in the frame header
;       data_size is the size of the data area
;
; This leaves DX as the temporary register
;
stressXmitLoop:
    push    ax
    push    bx
    push    cx
    push    es
    push    di

    ; Initialize  transmitChain descriptor
    mov     word ptr xmit_desc.TxImmedPtr, di       ; ptr to immed. data
    mov     word ptr xmit_desc.TxImmedPtr+2, es
    mov     dx, header_length                       ; Immed data is header
    mov     xmit_desc.TxImmedLen, dx
    mov     xmit_desc.TxDataCount, 1                ; Number of data blocks
    mov     xmit_desc.TDRsvdByte1, 0                ; Reserved byte
    mov     dx, data_size                           ; Length of rest of data
    mov     xmit_desc.TDDataLen1, dx                ;   (after the header)
    add     di, length_offset                       ; Save length into frame
    mov     word ptr es:[di], dx                    ;   header
    sub     di, length_offset                       ; Restore es:di -> frame

    cmp     txUseGDT,0                              ; use GDT addresses?
    je      stressUsePhys                           ; if not, use physical

                                                    ; Use virt addr in es:di
    mov     xmit_desc.TDPtrType1, 2                 ; GDT type pointer

    add     di, max_frame
    sub     di, data_size

    mov     word ptr xmit_desc.TDDataPtr1, di       ; Pass pointer to rest of
    mov     word ptr xmit_desc.TDDataPtr1+2, es     ;   data (all after header)
    jmp     stressCallTx

stressUsePhys:
    mov     xmit_desc.TDPtrType1, 0                 ; Phys type pointer

    add     bx, max_frame                           ; addresss is data_size
    adc     ax,0                                    ;   bytes from the end of
    sub     bx, data_size                           ;   the data
    sbb     ax, 0

    mov     word ptr xmit_desc.TDDataPtr1, bx       ; ax:bx 32-bit physical addr
    mov     word ptr xmit_desc.TDDataPtr1+2, ax     ;   (ax is high word)

stressCallTx:
    push    WCC.CcModuleID                          ; Wedge's ID
    inc     txHandle                                ; (next) handle
    push    txHandle
    push    ds                                      ; far *xmit descriptor
    mov     ax, offset DGROUP:xmit_desc
    push    ax
    push    MCC.CcDataSeg                           ; MAC'S data seg
    call    dword ptr MUDsTable.MudXmitChain_off    ; MAC'S upper dispatch

    
;
; Update statistics
;
stressUpdateStats:
    mov     bx, data_size                           ; Increment/decrement frame
    add     bx, size_increment                      ;   size
    mov     data_size, bx
    cmp     bx, max_data                            ; If (data_size > max_data)
    jbe     update_frames_left                      ; {

change_size_increment:
    neg     size_increment                          ;  Reverse frame increment.
    add     bx,size_increment                       ;  Reverse dangerous size
    mov     data_size, bx                           ;   change.  -1 size becomes
                                                    ;   0, and max_data+1 size
                                                    ;   becomes max_data.
                                                    ; }
update_frames_left:
    les     di, TestToolParms                       ; setup addressability to
                                                    ;   shared data area again
    cmp     ax, SUCCESS                             ; check immediate success
    jne     stressCheckQueued
    add     word ptr es:[di].TotalTx,1              ; if so, inc total xmitted
    adc     word ptr es:[di].TotalTx+2,0
    mov     word ptr es:[di].TxOutResource,0        ; and reset out of resource
    mov     word ptr es:[di].TxOutResource+2,0      ;   count
    sub     word ptr es:[di].StressCount,1          ; and decrement stress count
    sbb     word ptr es:[di].StressCount+2,0        ;   (use carry/borrow flag)
                                                    ;   below to exit loop)
    jnc     nextStressFrame                         ; If StressCount positive
                                                    ;   continue loop
    mov     word ptr es:[di].StressCount, 0         ; else stick at zero, not
    mov     word ptr es:[di].StressCount+2, 0       ;   wrap below to 0xFFFF
    jmp     nextStressFrame

stressCheckQueued:
    cmp     ax, REQUEST_QUEUED                      ; if queued, wait for the
    jne     stressCheckOutResource                  ;   xmitConf to update stats
    mov     word ptr es:[di].TxOutResource,0        ; reset out of resource
    mov     word ptr es:[di].TxOutResource+2,0      ;   count
    jmp     nextStressFrame

stressCheckOutResource:
    cmp     ax, OUT_OF_RESOURCE                     ; if out resources
    jne     stressCheckTxError
    add     word ptr es:[di].TxOutResource,1        ; increment OutResource stat
    adc     word ptr es:[di].TxOutResource+2,0
    jmp     nextStressFrame

stressCheckTxError:
    add     word ptr es:[di].TxErr,1                ; all other returns are
    adc     word ptr es:[di].TxErr+2,0              ;   errors

nextStressFrame:
    pop     di                                      ; restore frame ptr ES:DI
    pop     es
    pop     cx                                      ; Restore # frames to xmit
    pop     bx                                      ; Restore physical address
    pop     ax                                      ;   (AX:BX, AX is high word)

    sub     cx,1
    jz      doneStressFrame
    jmp     stressXmitLoop

doneStressFrame:
    ret
xmitStressFrame endp






;----------------------------------------------------------------------------
;
; lockMemory - locks a segment described by a far pointer down in memory
;	es:bx points to data packet
;
;----------------------------------------------------------------------------
    public  lockMemory
lockMemory  proc    near

if OS2
    push    ax
    push    bx
    push    dx
    push    si
                                        
	mov		di, bx										; keep ioctl data ptr in
														;  es:di, bx is used
    stc
    cmp     top_lock, MAX_LOCKS
    jge     done_lock

    mov     ax, word ptr es:[di].data_from+2            ; selector to be locked
    mov     bh, 1                                       ; long-term lock
    mov     bl, 0                                       ; block until locked
    mov     dl, DH_LockSeg
    call    dword ptr [DevHlp]                          ; lock it
    jc      done_lock                                   ; exit if error

    mov     si, top_lock                                ; Put handle into array
    shl     si, 1                                       ;   (4 bytes/handle)
    shl     si, 1
    add     si, offset DGROUP:mem_locks                 ; SI: memlocks[top_lock]
    mov     word ptr [si], bx                           ; save handle
    mov     word ptr [si]+2, ax

; get physical address of selector
	push	ds
	push	si
	push	es

	mov		ax, ds
	lds		si, es:[di].data_from
	mov		es, ax
	mov		dl, DH_VirtToPhys

if DOS
	ASSUME es:DGROUP
endif
    call    dword ptr es:[DevHlp]     		; convert virtual address to phys
if DOS
	ASSUME es:NOTHING
endif

	pop		es
	pop		si
	pop		ds

; get GDT pointer to physical address
	mov		si, top_lock
	shl		si, 1
	add		si, offset DGROUP:mem_gdts
	mov		si, [si]
	mov		cx, es:[di].ioctl_length
	mov		dl, DH_PhysToGDTSelector
    call    dword ptr [DevHlp]     			; convert virtual address to phys


	mov		word ptr es:[di].data_to, 0
	mov		word ptr es:[di].data_to+2, si

    inc     top_lock                        ; point to next handle

done_lock:
    pop     si
    pop     dx
    pop     bx
    pop     ax
else
	clc
	mov		ax, word ptr es:[bx].data_from
	mov		word ptr es:[bx].data_to, ax
	mov		ax, word ptr es:[bx].data_from+2
	mov		word ptr es:[bx].data_to+2, ax
endif
                                        
    ret
lockMemory  endp


_TEXT   ends

    End
