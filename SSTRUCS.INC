;
; File: sStrucs.inc     - Support Structures include NDIS specific.
;
; Copyright (C) 1989,1990 DWB Associates, All Rights Reserved
;
; description:
;

;-----------------------------------------------------------------------------
;
;       The following equates are the primary configuration for the driver.
;

; 
;       Definintions for the MAC Service Supported Flags.
;       Bits 0-15.
; 
BroadcastSupport        Equ     True
MulticastSupport        Equ     True
FunctionalGroupSupport  Equ     False
PromiscuousSupport      Equ     True
SetStationAddrSupport   Equ     False
StatusAlwaysCurrent     Equ     False
DiagnosticsSupport      Equ     False
LoopBackSupport Equ     False
ReceiveChainPrimary     Equ     True
IBMSourceRouting        Equ     False
ResetMACSupport Equ     True
OpenAdapterSupport      Equ     True
InterruptRequestSupp    Equ     False
SourceRoutingBridge     Equ     False
GDTAddressesSupported   Equ     True
MultipleXferDatas       Equ     False
RcvLkFrameSizeZero      Equ     False

NIC_Name                Equ     <'MAC_NIF'>     ; Common Characteristics Name.

MAC_Type                Equ     <'DIX+802.3'>   ; Specific Characteristic Type.

;
; 
; * maximum number of multicast addresses. 
; 
NUM_MCADDRS             Equ     10

MAX_PACKET              Equ     1514    ; Maximum allowable packet size.
DEF_BUFF_GRAN           Equ     256     ; Default Buffer granularity.
TX_QUEUE_DEPTH          Equ     14      ; Maximum transmit queue depth.

; 
; * Maximum number of data blocks supported in a descriptor.
; 
MAX_DATABLK             Equ     8
; 


;-----------------------------------------------------------------------------
; 
;       The following equates and structures should only be changed when
;       upgrading to a newer NDIS specification.
;

; * define the length of names and addresses in the Common Characteristics
; * and Specific Characteristics table.
; 
NAME_LEN                Equ     16
ADDR_LEN                Equ     16
ADDR_SIZE               Equ     6

; 
; * Definintions for the MAC Service Supported Flags.
; * Bits 0-14.
; 
ServiceFlags    =       00000000H 
ServiceFlags    =       ServiceFlags Or BroadcastSupport
ServiceFlags    =       ServiceFlags Or MulticastSupport Shl 1
ServiceFlags    =       ServiceFlags Or FunctionalGroupSupport Shl 2
ServiceFlags    =       ServiceFlags Or PromiscuousSupport Shl 3
ServiceFlags    =       ServiceFlags Or SetStationAddrSupport Shl 4
ServiceFlags    =       ServiceFlags Or StatusAlwaysCurrent Shl 5
ServiceFlags    =       ServiceFlags Or DiagnosticsSupport Shl 6
ServiceFlags    =       ServiceFlags Or LoopBackSupport Shl 7
ServiceFlags    =       ServiceFlags Or ReceiveChainPrimary Shl 8
ServiceFlags    =       ServiceFlags Or IBMSourceRouting Shl 9
ServiceFlags    =       ServiceFlags Or ResetMACSupport Shl 10
ServiceFlags    =       ServiceFlags Or OpenAdapterSupport Shl 11
ServiceFlags    =       ServiceFlags Or InterruptRequestSupp Shl 12
ServiceFlags    =       ServiceFlags Or SourceRoutingBridge Shl 13
ServiceFlags    =       ServiceFlags Or GDTAddressesSupported Shl 14
ServiceFlags    =       ServiceFlags Or MultipleXferDatas Shl 15
ServiceFlags    =       ServiceFlags Or RcvLkFrameSizeZero Shl 16
;

; 
; * NDIS protocol levels, interface type
; 
MACLvl                  Equ     1
MACTyp                  Equ     1
ProtLvl                 equ     2       ;data link
ProtTyp                 equ     -1      ;undefined
; 
; * the minimum lookahead defaults to 64, maximum is 256 bytes.
; 
MIN_LOOKAHEAD_DEFAULT   Equ     64
MAX_LOOKAHEAD           Equ     256
; 
; * Device driver CONFIG.SYS lines are a maximum of 132 bytes.
; 
DEVINIT_LEN             Equ     132
; 
; * All possible return error codes that are defined by the NDIS Spec. 2.0.1
; 
SUCCESS         Equ     0000H
WAIT_FOR_RELEASE        Equ     0001H
REQUEST_QUEUED          Equ     0002H
FRAME_NOT_RECOGNIZED    Equ     0003H
FRAME_REJECTED          Equ     0004H
FORWARD_FRAME           Equ     0005H
OUT_OF_RESOURCE Equ     0006H
INVALID_PARAMETER       Equ     0007H
INVALID_FUNCTION        Equ     0008H
NOT_SUPPORTED           Equ     0009H
HARDWARE_ERROR          Equ     000AH
TRANSMIT_ERROR          Equ     000BH
NO_SUCH_DESTINATION     Equ     000CH
ALREADY_STARTED Equ     0020H
INCOMPLETE_BINDING      Equ     0021H
DRIVER_NOT_INITIALIZED  Equ     0022H
HARDWARE_NOT_FOUND      Equ     0023H
HARDWARE_FAILURE        Equ     0024H
CONFIGURATION_FAILURE   Equ     0025H
INTERRUPT_CONFLICT      Equ     0026H
INCOMPATIBLE_MAC        Equ     0027H
INITIALIZATION_FAILED   Equ     0028H
GENERAL_FAILURE Equ     00FFH

; 
; * Packet filter bit definitions.
; 
FLTR_DIRECTED           Equ     01H
FLTR_BRDCST             Equ     02H
FLTR_PRMSCS             Equ     04H
FLTR_SRC_RTG            Equ     08H

; 
; * MAC status bits in the MAC Specific Characteristics table.
; * Bits 0-2 are coded to reflect the hardware status.
; 
HW_MISSING              Equ 0000H
HW_BUD_ERR              Equ 0001H
HW_CFG_ERR              Equ 0002H
HW_FAULT                Equ 0003H
HW_SOFT_ERR             Equ 0004H
HW_OK                   Equ 0007H
MS_HW_MASK              Equ HW_OK

MS_BOUND                Equ 0008H
MS_OPEN                 Equ 0010H
MS_DIAGS_ON             Equ 0020H

;
; Protocol Manager opcodes used by the generic model
;
GetPMInfo               Equ     1
RegisterModule          Equ     2
BindAndStart            Equ     3
GetPMLinkage            Equ     4

;-----------------------------------------------------------------------------
;
;       Structures defined in the NDIS specification.
;
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; 
; * NDIS Common Characteristics table
; 
CommChar        Struc

CcSize          DW      Size CommChar       ;01 Table size
CcLvl           DB      02,00               ;02 Level of table
CcSpLvl         DW      0                   ;03 Level of spec tables (reserved)
CcMjrVer        DB      MAJOR_VERSION       ;04 Module Major version number
CcMnrVer        DB      MINOR_VERSION       ;05 Module Minor version number
CcBindFnc       DD      3                   ;06 Binding at upper/lower supported
CcName          DB      NIC_Name            ;06 Module name ASCIIZ
                DB      NAME_LEN - ($ - CcName) dup(0) ; Pad for Module Name
CcUPLevel       DB      5                   ;07 Upper protocol level- we bind to
CcUIType        DB      1                   ;08 Upper interface type    session
CcLPLevel       DB      1                   ;09 Lower protocol level- we bind to
CcLIType        DB      1                   ;10 Lower interface type    a MAC
CcModuleID      DW      0                   ;11 Module ID (supplied by PM)
CcDataSeg       DW      DGROUP              ;12 Module Data Segment
; 
;        * System request function pointer
;        
CcSysReq_off    DW      0                   ;13
CcSysReq_Seg    DW      CGROUP              ;14
; 
; links to other NDIS characteristics tables.
;        
CcSCp_off       DW      0                   ;15
CcSCp_seg       DW      DGROUP              ;16
CcSSp_off       DW      0                   ;17
CcSSp_seg       DW      DGROUP              ;18
CcUDp_off       DW      0                   ;19
CcUDp_seg       DW      DGROUP              ;20
CcLDp_off       DW      0                   ;21
CcLDp_seg       DW      DGROUP              ;22

CcRsv1          DD      0                   ;23 reserved 
CcRsv2          DD      0                   ;24 reserved 

CommChar ends


;-----------------------------------------------------------------------------
; 
; * MAC Service Specific characteristics table
; 

MACSpecChar     Struc
MscSize         DW      Size MACSpecChar        ; Table size
MscType         DB      MAC_Type
                DB      NAME_LEN-($-MscType) dup(0) ; Module Type + Pad
MscStnAdrSz     DW      ADDR_SIZE               ; Station address length
MscPermStnAdr   DB      ADDR_LEN dup(0)         ; Permanent station address
MscCurrStnAdr   DB      ADDR_LEN dup(0)         ; Current station address
MscCurrFncAdr   DD      0                       ; Current functional address
MscMCp_off      DW      0
MscMCp_seg      DW      DGROUP
MscLinkSpd      DD      10000000                ; Link speed (bits/sec)
MscService      DD      ServiceFlags            ; Services supported flags
MscMaxFrame     DW      MAX_PACKET              ; Maximum frame size
MscTBufCap      DD      MAX_PACKET              ; Transmit buffer capacity
MscTBlkSz       DW      DEF_BUFF_GRAN           ; Transmit buf block size
MscRBufCap      DD      MAX_PACKET              ; Receive buffer capacity
MscRBlkSz       DW      DEF_BUFF_GRAN           ; Receive buf alloc block size
MscVenCode      DB      3 Dup(-1)               ; Vendor code 
MscVenAdapter   DB      0                       ; Vendor adapter code
MscVenAdaptDesc_off DW  0                       ; Ptr to vendor adapter desc
MscVenAdaptDesc_seg DW  DGROUP                  ; Ptr to vendor adapter desc
MscInterrupt    DW      0                       ; Interrupt level used
MscTxQDepth     DW      TX_QUEUE_DEPTH          ; Transmit Queue Depth
MscMaxDataBlocks DW     MAX_DATABLK             ; Max buff descriptor data
                                                ;   blocks      

MACSpecChar     Ends



;-----------------------------------------------------------------------------
; 
; * MAC service-specific status table
; 
;  Note: Items with ### are mandatory, Items with *** are obsolete on 2.01.
;

MACSpecStat     Struc
MssSize DW      Size MACSpecStat ;  Table size                                                  
MssDiagDT       DD      -1              ; Last diagnostic Date/Time
MssStatus       DD      0               ; MAC status - bit mask
MssFilter       DW      0               ; Current packet filter

MssM8Sp_off     DW      0
MssM8Sp_seg     DW      DGROUP

MssClearDT      DD      -1              ; Last clear stats Date/Time
MssFR           DD      -1              ; Frames received: total ###
MssRFCRC        DD      -1              ; Receive fail: CRC error ###
MssFRByt        DD      -1              ; Frames received: total bytes
MssRFLack       DD      -1              ; Receive fail: lack of buffers
MssFRMC         DD      -1              ; Frames received: multicast
MssFRBC         DD      -1              ; Frames received: broadcast
MssRFErr        DD      -1              ; rcv fail: errors in general ***
MssRFMax        DD      -1              ; rcv fail: exceeds max size ***
MssRFMin        DD      -1              ; rcv fail: less than min size ***
MssFRMCByt      DD      -1              ; Frames rcvd: multicast bytes ***
MssFRBCByt      DD      -1              ; Frames rcvd: broadcast bytes ***
MssRFHW         DD      -1              ; rcv fail: hardware error
MssFS           DD      -1              ; Frames sent: total ###
MssFSByt        DD      -1              ; Frames sent: total bytes
MssFSMC         DD      -1              ; Frames sent: multicast
MssFSBC         DD      -1              ; Frames sent: broadcast
MssFSBCByt      DD      -1              ; Frames sent: broadcast bytes ***
MssFSMCByt      DD      -1              ; Frames sent: multicast bytes ***
MssSFTime       DD      -1              ; Send fail: time-out
MssSFHW         DD      -1              ; Send fail: hardware error
MACSpecStat     Ends



;-----------------------------------------------------------------------------
; 
; * 802.3 (EtherNet) status table
; 
MAC8023Stat     Struc
M83sSize        DW      Size MAC8023Stat ; Table size                                                  
M83sVer         DW      1               ; Version
M83sRFAln       DD      0               ; Receive fail: Alignment error ###
M83sRMask       DD      -1              ; Receive fail bit mask (below) ***
M83sRFOvrn      DD      0               ; Receive fail: Overrun
M83sFSCols      DD      -1              ; Frames sent: after collisions ***
M83sFSDfr       DD      0               ; Frames sent: after deferring
M83sSFColMx     DD      0               ; Frames not sent: Max collisions
M83sTotCol      DD      -1              ; Total collision during tran ***
M83sTotLCol     DD      0               ; Total late collisions
M83sFSCol1      DD      0               ; Frames sent: after 1 collision ###
M83sFSColM      DD      0               ; Frames sent: multpl collisions ###
M83sFSHrtB      DD      0               ; Frames sent: CD heart beat
M83sJabber      DD      -1              ; Jabber errors ***
M83sLostCS      DD      0               ; Lost carrier sense during tran
M83sTMask       DD      -1              ; Transmit fail bit mask (below) ***
M83sTotUndrn    DD      0               ; Total Number of Underruns (V 2.01 >)
MAC8023Stat     Ends



;-----------------------------------------------------------------------------
; 
; * 802.5 (Token Ring) status table
; 
MAC8025Stat     Struc
M85sSize        DW      Size MAC8025Stat ;  Table size
M85sVer         DW      1               ;  Version
M85sFCS         DD      0               ;  FCS or repeat frame code error ###
M85sRMask       DD      -1              ;  Receive fail bit mask (below) ***
M85s5hbtt       DD      0               ;  "5 half-bit transition" errors.
M85sACerr       DD      0               ;  Access Control errors
M85sFsAbrtD     DD      0               ;  Frames sent: w/ abort delimiter
M85sFsNrcv      DD      0               ;  Frames sent: Not received. ###
M85sFrNoBuf     DD      0               ;  Frames recognized, no buffers
M85sFcopyErr    DD      0               ;  Frame copy errors
M85sFreqErr     DD      0               ;  Frequency errors
M85sMonRegen    DD      0               ;  Active Monitor regeneration count.   
M85sRsrvd1      DD      -1              ;  reserved
M85sRsrvd2      DD      -1              ;  reserved
M85sRsrvd3      DD      -1              ;  reserved
M85sTMask       DD      -1              ;  Transmit fail bit mask (below) ***
M85sTotUndrn    DD      0               ; Total Number of Underruns (V 2.01 >).
MAC8025Stat ends


;-----------------------------------------------------------------------------
; 
; * MAC upper dispatch table
; 
MACUprDisp      Struc
MudCCp_off      DW      0
MudCCp_Seg      DW      DGROUP
; 
;        * MAC entry points, all are assembly functions that conform to the 
;        * Microsoft FAR PASCAL calling conventions.
;        
MudGReq_off     DW      0
MudGReq_seg     DW      CGROUP

MudXmitChain_off DW     0
MudXmitChain_seg DW     CGROUP

MudXferData_off DW      0
MudXferData_seg DW      CGROUP

MudRcvRelease_Off DW    0
MudRcvRelease_seg DW    CGROUP

MudIndOn_off    DW      0
MudIndOn_seg    DW      CGROUP

MudIndOff_off   DW      0
MudIndOff_Seg   DW      CGROUP
MACUprDisp      Ends

;-----------------------------------------------------------------------------
; 
; * Protocol Lower Dispatch table
;       Filled in at Bind time from the Protocol.
; 
ProtLwrDisp     Struc
PldCCp_off      DW      0
PldCCp_Seg      DW      DGROUP

PldIFF          DD      ?               ;  Interface flags
; 
;        * Protocol stack entry points.
;        
PldReqConfirm_off       DW      0        
PldReqConfirm_seg       DW      CGROUP
         
PldXmitConfirm_off      DW      0
PldXmitConfirm_seg      DW      CGROUP

PldRcvLkAhead_off       DW      0
PldRcvLkAhead_seg       DW      CGROUP

PldIndComplete_off      DW      0
PldIndComplete_seg      DW      CGROUP

PldRcvChain_off         DW      0
PldRcvChain_seg         DW      CGROUP

PldStatInd_off          DW      0
PldStatInd_seg          DW      CGROUP

ProtLwrDisp     Ends

;-----------------------------------------------------------------------------
; 
; * multicast address structure is ADDR_LEN bytes long
; 
MCastAddr       Struc
mAddr           DB      ADDR_LEN dup(0)
MCastAddr       Ends

; 
; * the multicast address buffer manages NUM_MCADDRS multicast address
; * structures.
; 
MCastBuf        Struc
McbMax          DW      ?                   ;  max # of multicast addresses
McbCnt          DW      ?                   ;  curr# "              "
McbAddrs        DB      size MCastAddr*NUM_MCADDRS dup(0)
MCastBuf        Ends


;-----------------------------------------------------------------------------
;
;       Structures defined by the NDIS specification and used by the generic
;       model.
;
;-----------------------------------------------------------------------------
; * immediate data buffer length cannot exceed 64 bytes.
; 
MAX_IMMED_LEN           Equ     64
; 
; * Maximum number of data blocks supported in a Tx descriptor.
; 
MAX_TX_DATABLK          Equ     MAX_DATABLK
; 
; * Max number of TransferData blocks
; 
MAX_TD_DATABLK          Equ MAX_DATABLK
; 
; * MAx number of ReceiveChain data blocks
; 
MAX_RX_DATABLK          Equ     MAX_DATABLK

; 
; * Data structures for TransmitChain (Tx), TransferData (TD), and
; * ReceiveChain (Rx).
; 
TxDataBlock     Struc
TxPtrType       DB      ?               ; 0 = Physical pointer, 1 = GDT pointer
TxRsvdByte      DB      ?               ; Reservered, must be zero.
TxDataLen       DW      ?               ; Data block length in bytes.
TxDataPtr       DD      ?               ; Far pointer to data block.
TxDataBlock     Ends

; 
; * TransmitChain descriptor structure definition
; 
TxBufDesc       Struc
TxImmedLen      DW      ?               ; Bytes of immediate data (max = 64)
TxImmedPtr      DD      ?               ; Virtual address of Immediate data
TxDataCount     DW      ?               ; Number of Data Blocks (max = 8)
TDPtrType1      DB      ?               ; 0 = Physical pointer, 1 = GDT pointer
TDRsvdByte1     DB      ?               ; Reservered, must be zero.
TDDataLen1      DW      ?               ; Data block length in bytes.
TDDataPtr1      DD      ?               ; Far pointer to data block.
TDPtrType2      DB      ?               ; 0 = Physical pointer, 1 = GDT pointer
TDRsvdByte2     DB      ?               ; Reservered, must be zero.
TDDataLen2      DW      ?               ; Data block length in bytes.
TDDataPtr2      DD      ?               ; Far pointer to data block.
TxBufDesc       Ends

TxBufDescrSize  Equ     Size TxImmedLen + Size TxImmedPtr + Size TxDataCount

; 
; * TransferData data block description
; 
TDDataBlock     Struc
TDPtrType       DB      ?               ; 0 = Physical pointer, 1 = GDT pointer
TDRsvdByte      DB      ?               ; Reservered, must be zero.
TDDataLen       DW      ?               ; Data block length in bytes.
TDDataPtr       DD      ?               ; Far pointer to data block.
TDDataBlock     Ends

; 
; * TransferData descriptor structure
; 
TDBufDesc       Struc
TDDataCount     DW      ?               ; Number Data Blocks (max 8 for V1.01).
TDDataBlk       DB      size TDDataBlock*MAX_TD_DATABLK dup(0)
TDBufDesc       Ends

; 
; * ReceiveChain data block structure definition
; 
RxDataBlock     Struc
RxDataLen       DW      ?               ; Length of the Data Block
RxDataPtr       DD      ?               ; Far Pointer to Data Block
RxDataBlock     Ends

; 
; * ReceiveChain descriptor structure definition
; 
RxBufDesc       Struc
RxDataCount     DW      ?               ; Num Data Blocks. (max 8 for V1.01).
RxDataBlk       DB      size RxDataBlock*MAX_RX_DATABLK dup(0)
RxBufDesc       Ends


;-----------------------------------------------------------------------------
; 
;       Structures used in Protocol.Ini parsing.
;
;  
; * Data structures for the "Module Configuration" structure parsed from
; * the PROTOCOL.INI file. see NDIS spec for details.
; 
Param           Struc
ParamType       DW      ?       ; 0 => 31 bit signed integer, 1 => string       
ParamLen        DW      ?       ; String length (including null) or 4.          
ParmStart       DB      ?       ; Start of actual parameter.
Param ends

KeywordEntry    Struc
NextKeywordEntry DD     ?       ;  Forward pointer              
PrevKeywordEntry DD     ?       ;  Back Pointer                 
KeyWord DB      NAME_LEN Dup(?) ;  Keyword on left side of "="                          
NumParams       DW      ?       ;  Number of parameters on r. side of "="       
Params          DB      Size Param dup(?) ;  Actual size depends on NumParams                   
KeywordEntry ends


ModCfg          Struc
NextModCfg      DD      ?       ;  Module config images are in a                
PrevModCfg      DD      ?       ;  double-linked list.
ModName DB      NAME_LEN Dup(?) ;  Bracketed Module Name.
KE              DB      Size KeywordEntry Dup(?) ;  Head of Keyword list
ModCfg          Ends

ProIni          Struc
MC              DB      Size ModCfg*1 dup(?)  ; Head of Module config list.
ProIni          Ends


PI_Record       Struc
Srchkeyword     DB      '                ' ; keyword.
SrchParmType    DW      ?       ; 0 - numeric, 1 - string. see below.
ParamField      DD      ?       ; If numeric will contain value, If string
                                ; will contain the pointer to the string.
SetFCN          DW      ?       ; Offset to Parser function.
PI_Record       Ends

;
; request block structure used to register a module
;
RqBlk           Struc
Opcode          DW      ?
Status          DW      ?
Pointer1        DD      ?
Pointer2        DD      ?
Word1           DW      ?
RqBlk           Ends


;-----------------------------------------------------------------------------
;
; a transmit buffer structure must contain at least enough space for a 
; Transmit Chain descriptor. 
; 
txBuff          Struc
;
; Use this link to maintain free, pending and busy queues. This must be the
; first item in the structure.
;
Next            DW      ?
;
; Transmit buffer descriptor
;
tx              DB      size TxBufDesc dup(0)
;
; Protocol ID and request handle.
;
reqHandle       DW      ?
protID          DW      ?
;
; Buffer for immediate data
;
immed           DB      MAX_IMMED_LEN

;
; **************************************************************************
; **************************************************************************
; *                                                                         *
; * this section of the transmit buffer is driver and hardware dependent.  *
; *                                                                         *
; **************************************************************************
; **************************************************************************
;
; keep the physical address of the immediate data around in Motorola
; format. it is calculated at init time.
;
;immedPhysAddr  DD      ?
;
txBuff          Ends

;
;
ListHead        Struc
Head            DW      ?               ; First queue offset.
Tail            DW      ?               ; Last queue offset
ListHead        Ends

