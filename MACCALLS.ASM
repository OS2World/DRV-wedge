    Title   maccalls.asm - Dummy upper dispatch points
    Page    , 132
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Description: This file contains the Wedge's dummy upper dispatch functions
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

; Standard IOCTL equates.
    Include wedge.inc

; Standard DOS and OS/2 Driver header equates.
    Include devhdr.inc

; Standard IOCTL equates.
    Include ioctl.inc

.list

_DATA   Segment

    extrn   MCC:byte
    extrn   MUDsTable:byte
    extrn   WCC:byte

_DATA   ends
_TEXT   Segment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The following procedures are called by the protocol to request various 
; services from the MAC, or to control the MAC in some way.  They pass 
; control directly to the MAC through the saved copy of the MAC's upper 
; dispatch table.
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    assume  es:DGROUP

    public  WGenReq
WGenReq proc    near
    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    WCC.CcModuleID
    push    es:[bx].RequestHandle       ; Req. Handle
    push    es:[bx].Param1              ; Parameter 1
    push    es:[bx].Param3              ; Parameter 2
    push    es:[bx].Param2              ; is a double word parameter
    push    es:[bx].GenReqArg           ; Request Arg.
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudGReq_off   ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret

WGenReq endp

;--------------------------- TRANSMIT CHAIN ---------------------------------
    public  WXmitChain
WXmitChain  proc    near
    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    WCC.CcModuleID
    push    es:[bx].RequestHandle       ; Req. Handle
    push    es:[bx].Param2              ; Double word pointer to the 
    push    es:[bx].Param1              ; transmit descriptor.
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudXmitChain_off   ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret
WXmitChain  endp

;-------------------------- TRANSFER DATA -----------------------------------
    public  WXferData
WXferData   proc    near
    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    es:[bx].Param1              ; Bytes copied is a double word
    push    es:[bx].RequestHandle       ; pointer to memory.
    push    es:[bx].Param2              ; Starting offset into frame.
    push    es:[bx].GenReqArg           ; Double word pointer to transfer
    push    es:[bx].Param3              ; data descriptor.
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudXferData_off ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret
WXferData   endp

;-------------------------- RECEIVE RELEASE ---------------------------------
    public  WRcvRelease
WRcvRelease proc    near

    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    es:[bx].RequestHandle       ; Req. Handle
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudRcvRelease_Off ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret

WRcvRelease endp

;-------------------------- INDICATIONS OFF ---------------------------------
    public  WIndOff
WIndOff proc    near
    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudIndOff_off ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret
WindOff endp

;-------------------------- INDICATIONS ON ----------------------------------
    public  WIndOn
WindOn  proc    near
    push    es
    push    bx
    les     bx, es:[bx].data_from
    push    MCC.CcDataSeg               ; MAC'S data seg
    call    dword ptr MUDsTable.MudIndOn_off ; MAC'S upper dispatch
    pop     bx
    pop     es
    mov     es:[bx].ioctl_cmd, ax
    ret
WIndOn  endp

    public  WSystem
WSystem proc    far
    mov ax, DGROUP
    mov es, ax
    les bx, dword ptr es:MCC
    jmp dword ptr es:[bx].CcSysReq_off
WSystem endp

_TEXT   Ends
    END







