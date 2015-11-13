    Title   sData.Asm - NDIS and Generic Model data.
    Page    , 132
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Functional Description
;   NDIS and Generic Model data initialization.
;

;.xlist
; Build Configuration Information.
    Include build.cfg

; standard segment definitions
    Include segments.inc

; NDIS specific structures and Generic Model Structures
    Include sstrucs.inc

; Wedge specific structures and Generic Model Structures
    Include wedge.inc

;.list
;
;-----------------------------------------------------------------------------
;

; Routines in sysreq.asm
    Extrn   SystemRequest:far
    Extrn   LogBindings:near

; Routines in genreq.asm
    Extrn   ReqConfirm:near
    Extrn   XmitConfirm:near
    Extrn   RcvLookAhead:near
    Extrn   IndComplete:near
    Extrn   RcvChain:near
    Extrn   StatInd:near

; Routines in maccalls.asm
    extrn   WGenReq:near
    extrn   WXmitChain:near
    extrn   WXferData:near
    extrn   WRcvRelease:near
    extrn   WIndOff:near
    extrn   WIndOn:near

_DATA   segment


    Public  GDT_table, RxGDT, TxGDT, num_gdt, xmit_desc, txHandle, tmpBindStruc
GDT_table   equ     $                       ; table of GDT's used by Wedge
RxGDT       dw      ?                       ; GDT for recieve buffer area
TxGDT       dw      ?                       ; GDT for transmit buffer area
num_gdt     dw      ($-GDT_table) / 2       ; Number of GDT's in table
xmit_desc   db      size TxBufDesc dup(0)   ; Transmit chain desc. protected by
                                            ;   stressTxStat
txHandle    dw      0                       ; txChain handle, used by stress
                                            ;   transmits
tmpBindStruc db     size BindStruc dup(0)   ; bind structure to use when not
                                            ;   bound to IbmTool


    Public  AdapterDescr
AdapterDescr    DB  'IBM NDIS Wedge Driver', 0

    Public  Address_Length
Address_Length  DB  ADDR_LEN

    Public  MCBuff
MCBuff  MCastBuf <NUM_MCADDRS, 0>

    Public  WCC
WCC CommChar <,,,,,,,,,,,,,,Offset CGROUP:SystemRequest,,Offset DGROUP:WSC ,,Offset  DGROUP:MSS,,Offset DGROUP:WUD,, Offset DGROUP:WLD>

    Public  WSC
WSC MACSpecChar <,,,,,,,Offset DGROUP:MCBuff,,,,,,,,,,,Offset DGROUP:AdapterDescr>

    Public  WLD
WLD ProtLwrDisp <offset DGROUP:WCC,,, offset CGROUP:ReqConfirm,, offset CGROUP:XmitConfirm,, \
    offset  CGROUP:RcvLookAhead,, offset CGROUP:IndComplete,, offset CGROUP:RcvChain,, \
    offset  CGROUP:StatInd,>

    Public  WUD
WUD MACUprDisp <offset DGROUP:WCC,, offset CGROUP:WGenReq,, offset CGROUP:WXmitChain,, \
    offset  CGROUP:WXferData,, offset CGROUP:WRcvRelease,, offset CGROUP:WIndOn,, \
    offset  CGROUP:WIndOff, >


;-----------------------------------------------------------------------------
;
;   Protocol structures - Filled in at Bind time.
;      (Structures that let us act as a protocol to *our* MAC.)

    public  PCC
PCC         CommChar <>                 ; Protocol's Common Characteristics

    public  MCC                         ; MAC's Common Characteristics
MCC         CommChar <>

    public  MUDsTable
MUDsTable   MACUprDisp  <>              ; MAC's upper dispatch table

    public  PLDsTable
PLDsTable   ProtLwrDisp <>              ; Protocol lower dispatch table

    Public  MACPtrs 
MACPtrs DB  size MAC_Ptrs_struc dup (0) ; MAC pointers and information


    Public  MSS
MSS     MACSpecStat <, , , , Offset DGROUP:M85S>

    Public  M85S
M85S    MAC8025Stat <>

        db  'DWB WAS HERE'
; a list of the MAC modules that we will want to bind to
    public  BindingsList
BindingsList    Label   Word
    public  NumBindings
NumBindings dw  0
    public  ModuleNames
ModuleNames dw  4 dup(8 dup(0))
    public  MACsBound
MACsBound   dw  0

; the protocol has a notion of minimum lookahead data. it can call down
; to change it at will.
;    
    Public  minLookAhead
minLookAhead    DW  MIN_LOOKAHEAD_DEFAULT
; 
; indications are tracked using a nesting level byte. If this byte is 
; non-zero, then indications are disabled.
;    
    Public  indicationNestLevel
indicationNestLevel DB  0
; 
; 
; this flag is 0 during init time, non-zero at ring 0 time. The most
; important use is for debug after init time. Character output after
; init time must go direct to the UART, not to DOSWRITE.
;    
    Public  Ring0
Ring0       DB  0

; 
; Specifies which adapter must be used. This number may be non-zero if 
; there are multiple adapters in the box. The current generic model
; requires one driver per adapter. In the future, one driver should
; be able to manage multiple adapters.
;    
    Public  adapterNum
adapterNum  DW  0
; 
; remember the processor type
;    
    Public  procType
procType    DW  ?
; 
; store the device= string here at init time.
;    
    Public  devInitStr
devInitStr  DB  DEVINIT_LEN dup(0)

;   All strings must be zero terminated.
;
    Public  drvrDevName
drvrDevName DB  "\DEV\WEDGE$ ", 0 ; Leave a space for adding a number.

    Public  ProtNameKW
ProtNameKW  DB  "WEDGE", 0

;
    Public  StartPI
StartPI Label   Word
    BINDing PI_Record <'BINDINGS', 1, 0, Offset CGROUP:LogBindings>

    Public  PI_Count
PI_Count    Equ ($ - StartPI) / Size PI_Record

_DATA   Ends

    End

