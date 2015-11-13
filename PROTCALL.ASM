        Title   genreq.Asm - Upper level General Request functions.
        Page    , 132
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Description: This file contains the Wedge's dummy lower dispatch functions
;

.xlist
; Build Configuration Information.
        Include Build.Cfg

; Standard segment definitions
        Include Segments.inc

; NDIS specific structures and Generic Model Structures
        Include sStrucs.Inc

; Support Macros
        Include sMacros.inc

; Support for the Wedge
        Include wedge.inc

.list
_DATA   segment
        extrn   PLDsTable:byte
        extrn   WCC:byte
        extrn   TestToolParms:dword
        extrn   MUDsTable:byte
        extrn   MCC:byte
        extrn   RxGDT:word
        extrn   TxGDT:word
        extrn   MACPtrs:word
        extrn   xmit_desc:word
        extrn   txHandle:word

    public  frameoffset, txUseGDT, stressTxStat, txFrameSize
frameoffset     dw      ?                               ; offset into frame
txUseGDT        dw      ?                               ; use of GDT's in stress
                                                        ;   frame echoing
stressTxStat    dw      TXFREE                          ; status of echo xmit
                                                        ;   TXFREE, TXREADY or
                                                        ;   TXBUSY
txFrameSize     dw      0                               ; size of frame received
                                                        ;   during the server's
                                                        ;   stress

_DATA   ends

_TEXT   Segment
        assume  es:DGROUP




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The following procedures are called by the MAC to provide the protocol
; with various indications.  They simply pass control to the protocol through
; the saved protocol lower dispatch table.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RC_STACK       struc
                    dw      ?               ; BP
                    dd      ?               ; ret address
    RC_ProtDS       dw      ?               ; ProtDS
    RC_Opcode       dw      ?               ; original request opcode
    RC_Status       dw      ?               ; xmit status
    RC_Handle       dw      ?               ; request handle
    RC_MACID        dw      ?               ; MACID number
    RC_ProtID       dw      ?               ; protocol ID number
RC_STACK       ends
        public  ReqConfirm
ReqConfirm      proc    far
    push    bp
    mov     bp, sp                  ; setup stack frame
    push    bx
    push    cx
    push    dx
    push    di
    push    si
    push    es
    push    ds

    mov     ds, [bp].RC_ProtDS              ; setup data addressability

    les     di, TestToolParms               ; get ptr to testtool shared
                                            ;   memory info area

    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      ReqConfChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

ReqConfChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      ignore_reqcfm                   ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement
    mul     bl                              ;   Array + element*sizeof(element))
    add     di, ax

    mov     es:[di].IndicType,GENERALREQUEST ; pass type of indication
    mov     ax, [bp].RC_Handle              ; pass status of gen request
    mov     es:[di].IndReqC_Handle, ax
    mov     ax, [bp].RC_Status              ; pass status of gen request
    mov     es:[di].IndReqC_Status, ax
    mov     ax, [bp].RC_Opcode              ; pass status of gen request
    mov     es:[di].IndReqC_Opcode, ax

ignore_reqcfm:
    popf

    pop     ds
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    mov     sp, bp
    pop     bp

    mov     ax, SUCCESS
    ret     12
ReqConfirm      endp

;---------------------------------------------------------------------------
        public  XmitConfirm
XmitConfirm     proc    far

XMC_STACK       struc
                    dw      ?               ; BP
                    dd      ?               ; ret address
    XMC_ProtDS      dw      ?               ; ProtDS
    XMC_Status      dw      ?               ; xmit status
    XMC_ReqHandle   dw      ?               ; request handle
    XMC_MACID       dw      ?               ; MACID number
    XMC_ProtID      dw      ?               ; protocol ID number
XMC_STACK       ends

    push    bp
    mov     bp, sp                  ; setup stack frame
    push    bx
    push    cx
    push    dx
    push    di
    push    si
    push    es
    push    ds

    mov     ds, [bp].XMC_ProtDS             ; setup data addressability

    les     di, TestToolParms               ; get a pointer to the testtool
                                            ;   parameters
    cmp     es:[di].StressMode, 0           ; are we in stress?
    jne     xmitConfStress


    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      TxConfChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

TxConfChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      ignore_txconf                   ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement           ;   Array + element*sizeof(element))
    mul     bl
    add     di, ax

    mov     es:[di].IndicType,TRANSMITCONFIRM ; pass type of indication
    mov     ax, [bp].XMC_ReqHandle          ; get application handle
    mov     es:[di].IndTxC_Handle, ax
    mov     ax, [bp].XMC_Status             ; get tx status
    mov     es:[di].IndTxC_Status, ax

ignore_txconf:
    popf									; restore interrupts
    jmp xmitConfDone						; go to exit

xmitConfStress:
    mov     stressTxStat, TXFREE            ; we are done xmitting

    cmp     [bp].XMC_Status, SUCCESS        ; was transmit successful?
    jne     xmitConfErr
    add     word ptr es:[di].TotalTx,1      ; add onto total transmitted
    adc     word ptr es:[di].TotalTx+2,0

    sub     word ptr es:[di].StressCount,1  ; decrement stress count
    sbb     word ptr es:[di].StressCount+2,0
	jnb		xmitConfDone					; brif didn't go negative

	mov		word ptr es:[di].StressCount, 0		; else, stick at zero
	mov		word ptr es:[di].StressCount+2, 0

    jmp     xmitConfDone

xmitConfErr:
    add     word ptr es:[di].TxErr,1        ; add onto transmit error stat
    adc     word ptr es:[di].TxErr+2,0

xmitConfDone:
    pop     ds
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    mov     sp, bp
    pop     bp

    mov     ax, SUCCESS
    ret     10
XmitConfirm     endp




;---------------------------------------------------------------------------
; Function: int far PASCAL
;           RcvLookAhead (MACID, FrameSize, BytesAvail, Buffer, Indicate, ProtDS)
;
;
; Inputs:
;
; Outputs:
;       always returns success
;
; Side Effects:
;
;------------------------------------------------------------------------------
        public  RcvLookAhead
RcvLookAhead      proc    far

RLA_STACK       struc
                    dw      ?               ; BP  <-- SP points here
                    dd      ?               ; ret address
    RLA_ProtDS      dw      ?               ; ProtDS
    RLA_Indicate    dd      ?               ; Address of indicate flag
    RLA_Buffer      dd      ?               ; Address of lookahead data
    RLA_BytesAvail  dw      ?               ; Bytes of lookahead available
    RLA_FrameSz     dw      ?               ; Total size of frame (possible 0)
    RLA_MACID       dw      ?               ; MACID number
RLA_STACK       ends

RLA_LOCAL_STACK struc
    RLALS_RxDesc    db      size TDBufDesc dup (?)
    RLA_BytesCopied dw      ?
RLA_LOCAL_STACK ends

RLALOC  equ     [bp-size RLA_LOCAL_STACK]

; First setup the Stack Pointer.
    push    bp
    mov     bp, sp
    sub     sp, size RLA_LOCAL_STACK    ; Make room for the transdata buffer
                                        ; descriptor to pass to TranferData
    push    bx
    push    cx
    push    dx
    push    di                          ; save the world for caller
    push    si
    push    es
    push    ds

    mov     ds, [bp].RLA_ProtDS         ; setup data addressability
    mov     di, TestToolParms.addr_off  ; get a pointer to the testtool
    mov     es, TestToolParms.addr_seg  ; parameters

    cmp     es:[di].StressMode, 0
    jne     RcvLookCallReg
    call    RegRcvLookAhead
    jmp     RcvLookDone

RcvLookCallReg:
    call    StressRcvLookAhead


RcvLookDone:
    pop     ds
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    mov     sp, bp
    pop     bp
    ret     16                      ; Clean up the stack (pascal call)
RcvLookAhead      endp



;-----------------------------------------------------------------------
;
;  Look Ahead routine called if we are not stressed
;
;   DS: must be OUR data segment
;   ES:DI must point to wedge's shared memory area
; 
;-----------------------------------------------------------------------
    public  RegRcvLookAhead
RegRcvLookAhead   Proc    Near

    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      RegRLChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

RegRLChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      ignore_regrxlook                ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    push    es
    push    di

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement           ;   Array + element*sizeof(element))
    mul     bl
    add     di, ax

    mov     es:[di].IndicType,RECEIVELOOKAHEAD ; pass type of indication
    mov     ax, [bp].RLA_FrameSz            ; get frame size handle
    mov     es:[di].IndRxLk_FrameSz, ax
    mov     ax, [bp].RLA_BytesAvail         ; get available bytes
    mov     es:[di].IndRxLk_BytesAvail, ax

    pop     di                              ; restore pointer to shared area
    pop     es

    push    es                              ; Save pointer to area shared with
    push    di                              ;   IbmTool

    mov     ax, word ptr es:[di].RcvPhysAddr+2  ; 32-bit physical address of
    mov     bx, word ptr es:[di].RcvPhysAddr    ;   IbmTool's receive buffer
    les     di, es:[di].RcvData             ; ptr to IbmTool's receive buffer
    mov     si, offset DGROUP:MACPtrs       ; address of MAC and local ptrs
    call    copyLookFrame                   ; copy frame to es:di (IbmTool)
    call    checkFrame                      ; check frame for errors if the
                                            ;   CheckData shared variable is set

    pop     di                              ; Restore pointer to area shared
    pop     es                              ;   with IbmTool


ignore_regrxlook:
    popf
    ret

RegRcvLookAhead      endp



    public  StressRcvLookAhead
StressRcvLookAhead      Proc      Near

    push    es                              ; save ptr to shared data area
    push    di

    mov     si, offset DGROUP:MACPtrs
    push    ds
    push    si
    lds     si, [bp].RLA_Buffer             ; address of the RLA buffer header

    add     si, es:[di].HeaderLen           ; test if this is a control frame
    cmp     byte ptr [si], 'I'              ;   if it is not, do next check
    jne     doneCheckControl                ;   otherwise (below) jmp to the
    cmp     byte ptr [si]+1, 'B'            ;   regular lookahead, to pass the
    jne     doneCheckControl                ;   frame up to IbmTool
    cmp     byte ptr [si]+2, 'M'
    jne     doneCheckControl

    pop     si                              ; restore pointer to MACPtrs
    pop     ds
	pop		di								; restore pointer to shared data
	pop		es
    jmp     RegRcvLookAhead                 ; jmp into regular lookahead

doneCheckControl:
    pop     si                              ; restore pointer to MACPtrs
    pop     ds

    push    ds                              ; save pointer to MACPtrs
    push    si
    push    es                              ; save pointer to shared memory area
    push    di

    mov     dx, es:[di].HeaderFromOffset    ; DX: source addr offset in header
    mov     cx, es:[di].NetAddrLen          ; get length of address to cmp

    les     di, dword ptr [si].MP_MACsc_off ; Get current station address from
    add     di, MscCurrStnAdr               ;  service specific char. table.

    lds     si, [bp].RLA_Buffer             ; address of the RLA buffer header
    add     si, dx                          ; point to source address in header

    repe    cmpsb                           ; compare our address with this
                                            ;   frame's source address
                                            ;   (repeat while equal, and CX)
    jne     doneCheckLoopback               ; if they are not the same, work
                                            ;   on this frame

    pop     di                              ; restore pointer to IbmTool's
    pop     es                              ;   shared area
    pop     si                              ; restore pointer to MACPtrs
    pop     ds
    jmp     stressDone                      ; ignore this frame, we sent it

doneCheckLoopback:
    pop     di                              ; restore pointer to IbmTool's
    pop     es                              ;   shared area
    pop     si                              ; restore pointer to MACPtrs
    pop     ds

    cmp     es:[di].ResponseMode, WKSTAMODE ; if we are a wksta, we only need
    je      StrJustCheck                    ;   to check incoming frames

;
; Check if we are busy echoing a previous frame, or if we can save frame to echo
;
    cmp     stressTxStat, TXFREE            ; Is transmit buffer being used?
    jne     strJustCheck                    ;   if so, go fill the other buffer
    mov     cx, [bp].RLA_FrameSz            ; Save the frame size for later
    mov     txFrameSize, cx                 ;   echo transmission
    mov     es, TxGDT                       ; TxGDT:0 is buffer for later xmit
    xor     di,di
    mov     si, offset DGROUP:MACPtrs
    mov     ax, word ptr [si].MP_Tx_Phys    ; get physical address of tx buff
    mov     bx, word ptr [si].MP_Tx_Phys+2  ;   (AX-high, BX-low)

    call    copyLookFrame                   ; copy frame
    mov     stressTxStat, TXREADY           ; frame is ready to echo (done in
                                            ;   indications complete)
    call    checkFrame                      ; check frame for errors
    jnc     strSetEchoAddr
    mov     stressTxStat, TXFREE
strSetEchoAddr:
    call    setEchoAddr                     ; put our net addr in from, and
                                            ;   broadcast in the destination
    jmp     stressDone

strJustCheck:
    mov     es, RxGDT                       ; get address of place to put frame
    xor     di,di                           ;   our LOCAL rcv buf is RxGDT:0
    mov     si, offset DGROUP:MACPtrs       ; address of MAC and local ptrs
    mov     ax, word ptr [si].MP_Recv_Phys  ; get physical address of our LOCAL
    mov     bx, word ptr [si].MP_Recv_Phys+2 ;  receive buf (AX-high, BX-low)
    call    copyLookFrame                   ; copy frame
    call    checkFrame                      ; check it for errors

    cmp     stressTxStat, TXREADY           ; Has transmit buffer been waiting?
    jne     stressDone                      ;   if not, exit

    mov     es, TxGDT                       ; ES:0 is transmit buffer
    xor     di,di
    mov     si, offset DGROUP:MACPtrs
    mov     ax, word ptr [si].MP_Tx_Phys    ; get physical address of tx buff
    mov     bx, word ptr [si].MP_Tx_Phys+2  ;   (AX-high, BX-low)
    call    echoStressFrame                 ; start this pending xmit going

stressDone:
    pop     di                              ; restore ptr to shared data area
    pop     es
    ret

StressRcvLookAhead      endp




;----------------------------------------------------------------------------
;
;   setEchoAddr - put our address into the from address, and put broadcast
;                   into the destination
;   es:di points to the frame
;   ds:si points to MACPtrs (and our data segment)
;
;----------------------------------------------------------------------------
    public  setEchoAddr
setEchoAddr     proc    near

    push    ax
    push    bx
    push    cx
    push    di

    push    es
    push    di

    les     di, TestToolParms
    mov     ax, es:[di].HeaderFromOffset
    mov     bx, es:[di].HeaderToOffset
    mov     cx, es:[di].NetAddrLen

    pop     di
    pop     es

    push    ds
    push    si

    push    di
    lds     si, dword ptr [si].MP_MACsc_off
    add     si, MscCurrStnAdr               ;  service specific char. table.
    add     di, ax
    mov     ax, cx
    rep movsb

    pop     di
    mov     cx,ax
    mov     ax, 0FFh
    add     di, bx
    rep stosb

    pop     si
    pop     ds

    pop     di
    pop     cx
    pop     bx
    pop     ax

    ret
setEchoAddr     endp




;----------------------------------------------------------------------------
;
; copyLookFrame - copies a lookahead frame into a buffer pointed to by ax:bx
;                   (ax:bx is a 32-bit physical address, ax is high word)
;
;----------------------------------------------------------------------------
    public  copyLookFrame
copyLookFrame   proc    near

    push        es
    push        di
    push        si
    push        ax

; call transfer data at this point
    lea     si, [RLALOC].RLALS_RxDesc ; SS:SI -> stack TDBufDesc

    ; fill in TransferData descriptor
    mov     WORD PTR ss:[si].TDDataCount, 1         ; one xfer data block
    mov     BYTE PTR ss:[si].TDDataBlk.TDRsvdByte,0 ; reserved, must be 0
    mov     cx, [bp].RLA_FrameSz
    mov     WORD PTR ss:[si].TDDataBlk.TDDataLen, cx

if OS2
	push	ds
	push	si
	lds		si, TestToolParms
	cmp 	[si].UseGDT, 0
	pop		si
	pop		ds

	jne		copyLookVirt

    mov     BYTE PTR ss:[si].TDDataBlk.TDPtrType, 0 ; physical pointer
    mov     WORD PTR ss:[si].TDDataBlk.TDDataPtr, bx
    mov     WORD PTR ss:[si].TDDataBlk.TDDataPtr+2, ax

	jmp		doneLookPtrType

copyLookVirt:
    mov     BYTE PTR ss:[si].TDDataBlk.TDPtrType, 2 ; virtual pointer
else
    mov     BYTE PTR ss:[si].TDDataBlk.TDPtrType, 0 ; DOS always 0 as ptr type
endif
    mov     WORD PTR ss:[si].TDDataBlk.TDDataPtr, di
    mov     WORD PTR ss:[si].TDDataBlk.TDDataPtr+2, es

doneLookPtrType:


    ;
    ; Then prepare the stack for the transfer data call to the MAC
    ;
    mov     ax,si
    add     ax, RLA_BytesCopied     ; Address to return bytes copied
    push    ss                      ;    "     "    "     "     "
    push    ax

    xor     ax,ax                   ; Start transferring at offset 0
    push    ax 
    push    ss                      ; Address of transfer data descripter
    push    si                      ;    "     "    "      "        "
    push    MCC.CcDataSeg           ; MAC'S data seg
    call    dword ptr MUDsTable.MudXferData_off   ; MAC'S upper dispatch

    pop     ax
    pop     si
    pop     di
    pop     es

    ret
copyLookFrame   endp


;------------------------------------------------------------------------------
;
; checkFrame - checks a frame for descending data, with the last byte being 1
;   the length of the frame is gotten from the frame itself.  It is assumed
;   that the length is the last two little-endian bytes in the header.
;
;------------------------------------------------------------------------------
    public  checkFrame
checkFrame  proc    near

    push    ax                      ; save AX and DI registers
    push    di

    push    es
    push    di
    les     di, TestToolParms       
    mov     ax, es:[di].HeaderLen   ; get length of header (to skip check upon)
    cmp     es:[di].CheckData, 0    ; check if we are supposed to check the data
    pop     di
    pop     es
    jne     checkGoAhead            ; if we are, go ahead and start check

    push    ds                      ; get pointer to shared memory area
    push    si
    lds     si, TestToolParms
    add     word ptr [si].TotalRx,1 ; else, increment total receives gotten
    adc     word ptr [si].TotalRx+2,0
    pop     si
    pop     ds

    jmp     exitCheck               ; and jmp to exit this function.

checkGoAhead:
    add     di, ax                  ; point to data
    mov     cx, es:[di]-2           ; get length of frame

    push    ds                      ; get pointer to shared memory area
    push    si
    lds     si, TestToolParms

    add     word ptr [si].TotalRx,1 ; increment total receives gotten
    adc     word ptr [si].TotalRx+2,0

    jcxz    doneCheck
dataCheckLoop:
    cmp     es:[di], cl
    je      nextCheck
    add     word ptr [si].RxErr,1   ; increment number of errors
    adc     word ptr [si].RxErr+2,0
    stc                             ; indicate that there was an error
    cmp     [si].StopOnErr, 0       ; should we stop on error?
    je      doneCheck
	int 3
    jmp     doneCheck
nextCheck:
    inc     di
    loop    dataCheckLoop

    clc                             ; indicate a success to caller

doneCheck:
    pop     si                      ; restore ds:si pointer
    pop     ds

exitCheck:
    pop     di
    pop     ax
    ret
checkFrame  endp


;-----------------------------------------------------------------------------
;
; echoStressFrame - transmits's a frame in es:di using txFrameSize as the
;                   length to send to the MAC.  The stressTxStat is modified
;                   to TXBUSY (to protect xmit_desc), and wedge common stats
;                   are updated depending upon the return code of XmitChain.
;
; Side Effects:
;       ax , cx, dx, es, di
;
;-----------------------------------------------------------------------------

    public  echoStressFrame
echoStressFrame proc    near

    mov     stressTxStat, TXBUSY

    push    es                                      ; save frame pointer
    push    di

    les     di, testToolParms
    mov     cx, es:[di].UseGDT                      ; Save the UseGDT variable
    mov     txUseGDT, cx                            ;   for later
    mov     cx, es:[di].HeaderLen                   ; CX: header length

    pop     di                                      ; restore frame pointer
    pop     es

    mov     word ptr xmit_desc.TxImmedPtr, di       ; ptr to immed. data
    mov     word ptr xmit_desc.TxImmedPtr+2, es
    mov     xmit_desc.TxImmedLen, cx                ; Immed data is header
    mov     xmit_desc.TxDataCount, 1                ; number of data blocks
    mov     xmit_desc.TDRsvdByte1, 0                ; reserved byte
    mov     dx, txFrameSize                         ; DX: length of rest of data
    sub     dx, cx                                  ;   (after the header)
    mov     xmit_desc.TDDataLen1, dx

    cmp     txUseGDT,0
    je      echoUsePhys

                                                    ; Use virt addr in es:di
    mov     xmit_desc.TDPtrType1, 2                 ; GDT type pointer
    add     di, cx                                  ; Go past immed data
                                                    ;   (header)
    mov     word ptr xmit_desc.TDDataPtr1, di       ; Pass pointer to rest of
    mov     word ptr xmit_desc.TDDataPtr1+2, es     ;   data (all after header)
    jmp     echoCallTx

echoUsePhys:                                        ; Use phys addr in ax:bx
    mov     xmit_desc.TDPtrType1, 0                 ; Phys type pointer
    add     bx, cx                                  ; Add offset to data area
    adc     ax,0                                    ;   (just after header)
    mov     word ptr xmit_desc.TDDataPtr1, bx       ; ax:bx 32-bit physical addr
    mov     word ptr xmit_desc.TDDataPtr1+2, ax     ;   (ax is high word)

echoCallTx:
    push    WCC.CcModuleID                          ; Wedge's ID
    inc     txHandle                                ; (next) handle
    push    txHandle
    push    ds                                      ; far *xmit descriptor
    mov     ax, offset DGROUP:xmit_desc
    push    ax
    push    MCC.CcDataSeg                           ; MAC'S data seg
    call    dword ptr MUDsTable.MudXmitChain_off    ; MAC'S upper dispatch

    les     di, TestToolParms                       ; setup addressability to
                                                    ;   shared data area again

    cmp     ax, SUCCESS                             ; check immediate success
    jne     echoCheckQueued
    add     word ptr es:[di].TotalTx,1              ; if so, inc total xmitted
    adc     word ptr es:[di].TotalTx+2,0
    mov     word ptr es:[di].TxOutResource,0        ; and reset out of resource
    mov     word ptr es:[di].TxOutResource+2,0      ;   count
    mov     stressTxStat, TXFREE                    ; mark txDesc as not busy
    jmp     doneEchoChecks

echoCheckQueued:
    cmp     ax, REQUEST_QUEUED                      ; if queued
    jne     echoCheckOutResource                    ; {
    mov     word ptr es:[di].TxOutResource,0        ;   reset out of resource
    mov     word ptr es:[di].TxOutResource+2,0      ;       count
                                                    ;   xmitConf will update the
                                                    ;       statistics.
    jmp     doneEchoChecks                          ; }

echoCheckOutResource:
    cmp     ax, OUT_OF_RESOURCE                     ; if out resources
    jne     echoCheckTxError
    mov     stressTxStat, TXFREE                    ; mark txDesc as not busy
    add     word ptr es:[di].TxOutResource,1        ; increment OutResource stat
    adc     word ptr es:[di].TxOutResource+2,0
    jmp     doneEchoChecks

echoCheckTxError:
    mov     stressTxStat, TXFREE                    ; mark txDesc as not busy
    add     word ptr es:[di].TxErr,1                ; all other returns are
    adc     word ptr es:[di].TxErr+2,0              ;   errors

doneEchoChecks:

    ret
echoStressFrame endp


        public  IndComplete
IndComplete     proc    far

INC_STACK       struc
                    dw      ?               ; BP  <-- SP points here
                    dd      ?               ; ret address
    INC_ProtDS      dw      ?               ; ProtDS
    INC_MACID       dw      ?               ; MACID number
INC_STACK       ends

    push    bp
    mov     bp, sp

    push    bx                              ; save bunch'o regs
    push    cx
    push    dx
    push    di
    push    si
    push    es
    push    ds

    mov     ds, [bp].INC_ProtDS             ; Setup data addressability
    mov     di, TestToolParms.addr_off      ; Get a pointer to the testtool
    mov     es, TestToolParms.addr_seg      ;   parameters

    cmp     es:[di].StressMode,1            ; If we are stress mode
    je      indCmplt_stress                 ;   jmp to transmit frames

    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      IndCmpltChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

IndCmpltChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      indCmplt_done                   ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement           ;   Array + element*sizeof(element))
    mul     bl
    add     di, ax

    mov     es:[di].IndicType,INDICATIONCOMPLETE    ; pass type of indication
                                                    ;   (no parameters though)
    jmp     indCmplt_done

indCmplt_stress:
    pushf

    cmp     es:[di].ResponseMode, SERVERMODE ; If we are not server, no need
    jne     indCmplt_done                    ;   to transmit next echo frame

    mov     es, TxGDT                       ; es:0 is transmit buffer
    xor     di,di
    mov     si, offset DGROUP:MACPtrs
    mov     ax, word ptr [si].MP_Tx_Phys    ; get physical address of tx buff
    mov     bx, word ptr [si].MP_Tx_Phys+2  ;   (AX-high, BX-low)

    cmp     stressTxStat, TXREADY
    jne     indCmplt_done
    call    echoStressFrame                 ; echo frame back out onto the wire

indCmplt_done:
    popf

    pop     ds
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    mov     sp, bp
    pop     bp
    mov     ax, SUCCESS
    ret     4

IndComplete     endp





;------------------------------------------------------------------------------
; definition for parameters on stack for RcvChain
;------------------------------------------------------------------------------
RCC_STACK       struc
                dw      ?               ; BP  <-- SP points here
                dd      ?               ; ret address
RCC_ProtDS      dw      ?               ; ProtDS
RCC_Indicate    dd      ?               ; Address of indicate flag
RCC_BufDesc     dd      ?               ; Virtual Address of receive descriptor
RCC_ReqHandle   dw      ?               ; Unique handle for this request
RCC_FrameSz     dw      ?               ; Total size of frame (possible 0)
RCC_MACID       dw      ?               ; MACID number
RCC_STACK       ends
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;
; RcvChain - Called directly by the MAC to handle a received frame.  This
;               function calls either the regular or stress handlers,
;               depending upon whether StressMode in the IbmTool common area
;               is set.
;
;------------------------------------------------------------------------------

    public  RcvChain
RcvChain    proc    far

; First setup the Stack Pointer.
    push    bp
    mov     bp, sp

    push    bx                                      ; save lots'o registers
    push    cx
    push    dx
    push    di
    push    si
    push    es
    push    ds

    mov     ds, [bp].RCC_ProtDS                     ; get our DS
    mov     si, offset DGROUP:MACPtrs               ; DS:SI ptr to MACPtrs
    mov     di, TestToolParms.addr_off              ; ES:DI ptr to IbmTool data
    mov     es, TestToolParms.addr_seg

    cmp     es:[di].StressMode, 0                   ; if (!StressMode)
    jne     callStressRcvChain
    call    RegRcvChain                             ; then call Regular handler
    jmp     chainSetReturn

callStressRcvChain:
    call    StressRcvChain                          ; else call Stress handler

chainSetReturn:
    cmp     es:[di].RxWait, 0
    je      chainRetSuccess
    mov     ax, WAIT_FOR_RELEASE
    jmp     doneRcvChain
chainRetSuccess:
    mov     ax, SUCCESS

doneRcvChain:
    pop     ds                                      ; restore registers
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx

    mov     sp, bp
    pop     bp
    ret     16

RcvChain    endp



;------------------------------------------------------------------------------
;
; RegRcvChain - Handles a received frame by passing it up to IbmTool if
;               IbmTool has space.  If stress mode is active, it switches
;               the RxChainFuncPtr to point to the stress RxChain handler,
;               and then jmps into the stress mode handler.
;
;------------------------------------------------------------------------------
    public  RegRcvChain
RegRcvChain proc    near

    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      RegRxChainChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

RegRxChainChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      reg_ignore_chain                ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    push    es                              ; save TestToolParms pointer
    push    di

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement           ;   Array + element*sizeof(element))
    mul     bl
    add     di, ax

    mov     es:[di].IndicType,RECEIVECHAIN  ; pass type of indication

    mov     ax, [bp].RCC_FrameSz            ; pass given size
    mov     es:[di].IndRxChain_FrameSz, ax
    mov     ax, [bp].RCC_ReqHandle          ; pass handle       
    mov     es:[di].IndRxChain_Handle, ax

    pop     di                              ; restore ptr to shared data
    pop     es

    push    es                              ; save ptr to shared data
    push    di

    les     di, es:[di].RcvData             ; get ptr to target
                                            ;   frame buffer

    call    copyChainFrame                  ; copy frame to rcv buffer
    call    checkFrame                      ; check frame for errors

    pop     di                              ; Restore ptr to data shared
    pop     es                              ;   from IbmTool.

reg_ignore_chain:
    popf
    ret

RegRcvChain endp



;------------------------------------------------------------------------------
;
; StressRcvChain - Handles a received frame during stress mode.  First, if
;               no transmits are in progress, it saves the received frame into
;               a transmit buffer and sets a flag to start later transmision.
;               If the transmit buffer was being used to transmit, then the 
;
;------------------------------------------------------------------------------
    public  StressRcvChain
StressRcvChain  proc    near

    push    es                              ; save ptr to shared data area
    push    di

    push    ds
    push    si

    lds     si, dword ptr [bp].RCC_BufDesc  ; Get ptr to frame desc.
    add     si, RxDataBlk                   ; point to 1st block
    lds     si, [si].RxDataPtr              ; get ptr to block's data
    add     si, es:[di].HeaderLen           ; Get ptr to the data AFTER
                                            ;   the header.

    cmp     byte ptr [si], 'I'              ;   if it is not, do next check
    jne     doneChainControl                ;   otherwise (below) jmp to the
    cmp     byte ptr [si]+1, 'B'            ;   regular rcv chain, to pass the
    jne     doneChainControl                ;   frame up to IbmTool
    cmp     byte ptr [si]+2, 'M'
    jne     doneChainControl

    pop     si
    pop     ds
    pop     di                              ; restore ptr to shared data area
    pop     es

    jmp     RegRcvChain

doneChainControl:
    pop     si
    pop     ds

    push    ds                              ; save pointer to MACPtrs
    push    si
    push    es                              ; save pointer to shared memory area
    push    di

    mov     dx, es:[di].HeaderFromOffset    ; DX: source addr offset in header
    mov     cx, es:[di].NetAddrLen          ; get length of address to cmp

    les     di, dword ptr [si].MP_MACsc_off ; Get current station address from
    add     di, MscCurrStnAdr               ;  service specific char. table.

    lds     si, [bp].RCC_BufDesc            ; address of frame descriptor
    add     si, RxDataBlk                   ; point to 1st block
    lds     si, [si].RxDataPtr              ; get ptr to block's data
    add     si, dx                          ; point to source address in header

    repe    cmpsb                           ; compare our address with this
                                            ;   frame's source address
                                            ;   (repeat while equal, and CX)
    jne     doneChainLoopback               ; if they are not the same, work
                                            ;   on this frame

    pop     di                              ; restore pointer to IbmTool's
    pop     es                              ;   shared area
    pop     si                              ; restore pointer to MACPtrs
    pop     ds
    jmp     doneStressChain                 ; ignore this frame, we sent it

doneChainLoopback:
    pop     di                              ; restore pointer to IbmTool's
    pop     es                              ;   shared area
    pop     si                              ; restore pointer to MACPtrs
    pop     ds

    cmp     stressTxStat, TXFREE            ; Is transmit buffer being used?
    jne     chainJustCheck                  ;   if so, go fill the other buffer

    cmp     es:[di].ResponseMode, WKSTAMODE ; if we are a wksta, we only need
    je      chainJustCheck                  ;   to check incoming frames

    mov     cx, [bp].RLA_FrameSz            ; Save the frame size for later
    mov     txFrameSize, cx                 ;   echo transmission
    mov     es, TxGDT                       ; TxGDT:0 is buffer for later xmit
    xor     di,di
    mov     ax, word ptr [si].MP_Tx_Phys    ; get physical address of tx buff
    mov     bx, word ptr [si].MP_Tx_Phys+2  ;   (AX-high, BX-low)

    call    copyChainFrame                  ; copy frame
    mov     stressTxStat, TXREADY           ; frame is ready to echo (done in
                                            ;   indications complete)
    call    checkFrame                      ; check frame for errors
    jnc     chainSetEchoAddr
    mov     stressTxStat, TXFREE
chainSetEchoAddr:
    call    setEchoAddr                     ; put our net addr in from, and
                                            ;   broadcast in the destination
    jmp     doneStressChain

chainJustCheck:
    mov     es, RxGDT                       ; get address of place to put frame
    xor     di,di                           ;   our LOCAL rcv buf is RxGDT:0
    mov     si, offset DGROUP:MACPtrs       ; address of MAC and local ptrs
    mov     ax, word ptr [si].MP_Recv_Phys  ; get physical address of our LOCAL
    mov     bx, word ptr [si].MP_Recv_Phys+2 ;  receive buf (AX-high, BX-low)

    call    copyChainFrame                  ; copy frame to rcv buffer
    call    checkFrame                      ; check frame for errors

    cmp     stressTxStat, TXREADY           ; Has transmit buffer been waiting?
    jne     doneStressChain                 ;   if not, exit

    mov     es, TxGDT                       ; es:0 is transmit buffer
    xor     di,di
    mov     si, offset DGROUP:MACPtrs
    mov     ax, word ptr [si].MP_Tx_Phys    ; get physical address of tx buff
    mov     bx, word ptr [si].MP_Tx_Phys+2  ;   (AX-high, BX-low)
    call    echoStressFrame                 ; start this pending xmit going

doneStressChain:
    pop     di                              ; restore ptr to shared data area
    pop     es

    ret
    
StressRcvChain  endp


;------------------------------------------------------------------------------
;
; copyChainFrame - copy receive-chain frame (descriptor pointed to by bp) into
;                   the buffer pointed to by ES:DI.
;
;------------------------------------------------------------------------------
    public  copyChainFrame
copyChainFrame  proc    near
    push    cx
    push    ds
    push    si
    push    di

    lds     si, dword ptr [bp].RCC_BufDesc          ; get ptr to frame
                                                    ;   descriptor
    mov     cx, [si].RxDataCount                    ; get num of blocks
    jcxz    RCC_Exit                                ; if no blocks, exit
    lea     si, [si].RxDataBlk                      ; point to 1st block
RxChainLoop:
    push    cx                                      ; save block cnt
    push    ds                                      ; save ptr to frame
    push    si                                      ;   descriptor
    mov     cx, [si].RxDataLen                      ; get len of block
    lds     si, [si].RxDataPtr                      ; get ptr to block

    clc                                             ; Use carry bit for odd last
    rcr     cx,1                                    ;   byte.
    rep movsw                                       ; copy words
    jnc     RCC_nextBlock                           ; if (odd byte count)
    movsb                                           ;   copy last byte
    
RCC_nextBlock:                                      ; restore block ptr
    pop     si
    pop     ds
    add     si, size RxDataBlock                    ; point to next block
    pop     cx                                      ; restore block count
    loop    RxChainLoop                             ; copy next block
    
RCC_Exit:
    pop     di
    pop     si
    pop     ds
    pop     cx
    ret
copyChainFrame  endp




;------------------------------------------------------------------------------
; structure to describe parameters passed on stack to status indication handler
;------------------------------------------------------------------------------
SIN_STACK       struc
                dw      ?               ; BP  <-- SP points here
                dd      ?               ; ret address
SIN_ProtDS      dw      ?               ; ProtDS
SIN_Opcode      dw      ?               ; Opcode of status indication
SIN_Indicate    dd      ?               ; Address of indicate flag
SIN_Param1      dw      ?               ; Opcode dependent word
SIN_MACID       dw      ?               ; MACID number
SIN_STACK       ends
;------------------------------------------------------------------------------




;------------------------------------------------------------------------------
;
; StatInd - directly called by MAC to handle status indications.  If IbmTool
;           has room, the status indication is passed up to it in the data
;           area shared by IbmTool with us (Wedge).
;
;------------------------------------------------------------------------------
    public  StatInd
StatInd     proc    far

    push    bp
    mov     bp, sp

    push    bx                              ; save world (of registers)
    push    cx
    push    dx
    push    di
    push    si
    push    es
    push    ds

    mov     ds, [bp].SIN_ProtDS             ; setup data addressability
    les     di, TestToolParms               ; get a pointer to the testtool
                                            ; parameters

    mov     ax, es:[di].IndNextFree         ; AX: Next free indic element
    inc     ax
    cmp     ax, INDIC_QUEUE_LEN             ; check for wrap-around on current
    jb      StatIndChkFull
    xor     ax, ax                          ; wrap around back to 0 (start)

StatIndChkFull:
    pushf                                   ; turn off interrupts (and save)
    cli

    cmp     ax, es:[di].IndCurrent          ; if Current == (NextFree+1)%MAXELEM
    je      ignore_statind                  ;    the queue is full


    xchg    ax, es:[di].IndNextFree         ; bump up free count, and get back
                                            ;   index to element we want to fill

    les     di, es:[di].IndArray            ; get ptr to free indic element
    mov     bl, size IndicElement           ;   Array + element*sizeof(element))
    mul     bl
    add     di, ax

    mov     es:[di].IndicType,STATUSINDICATION ; pass type of indication
    mov     ax, [bp].SIN_OpCode             ; get opcode
    mov     es:[di].IndStat_Opcode, ax
    mov     ax, [bp].SIN_Param1             ; get parameter
    mov     es:[di].IndStat_Param1, ax

ignore_statind:
    popf

    pop     ds
    pop     es
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    mov     sp, bp
    pop     bp

    mov     ax, SUCCESS
    ret     12
StatInd endp

_TEXT   Ends
        END
