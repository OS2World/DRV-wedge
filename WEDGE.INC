;
; File: Wedge.inc - NDIS and Generic Model Structures and equates.
;
; Copyright (C) 1989,1990, 1991 DWB Associates, All Rights Reserved
;
; Functional Description
;   NDIS and Generic Model Structures and equates.
;

_BIND               equ 2
ETHER_ADDR_LEN      equ 6
ETHERNET_HEADER     equ 12
TOKENRING           equ 2
AC_FC               equ 2
SAP_LEN             equ 6
RXDATASIZE          equ 6
NAME_LEN            equ 16
MAX_ETH_FRAME       equ 1514
MAX_TR_FRAME        equ 4000

; Indications
TRANSMITCONFIRM     equ 0001h
RECEIVELOOKAHEAD    equ 0002h
INDICATIONCOMPLETE  equ 0004h
RECEIVECHAIN        equ 0008h
STATUSINDICATION    equ 0010h
GENERALREQUEST      equ 0020h

; Ethernet frame structure for extracting the protocol type and destination 
; addresses to filter the frames during the receives.

Ethernet_Frame  struc
    E_Dest_Addr     db  ETHER_ADDR_LEN dup(?)
    E_Source_Addr   db  ETHER_ADDR_LEN dup(?)
    E_Prot_Type     dw  ?
Ethernet_Frame  ends

;
;  Protocol type Array for storing the address of the receive buffer for
;  each protocol type registered with the protocol driver.
;
ProtoTypeStruc  Struc
    ProtoType       dw  ?
    RxPhysHi        dw  ?
    RxPhysLo        dw  ?
    PTHandle        dw  ?
    PTTypeSave      dw  ?
ProtoTypeStruc  Ends

MAC_Ptrs_struc  Struc
    MP_CommChar     dd  ?           ; 00 - Ptr to Common Char Table of MAC
    MP_ModuleID     dw  ?           ; 04 - Module ID of Wedge
    MP_MACDS        dw  ?           ; 06 - MAC's Data Segment
    MP_UpDisp_off   dw  ?           ; 08 - MAC's upper Dispatch Table
    MP_UpDisp_Seg   dw  ?           ; 0A - 
    MP_MACsc_off    dw  ?           ; 0C - MAC's Service Char Table
    MP_MACsc_seg    dw  ?           ; 0E - 
    MP_Recv_Phys    dd  ?           ; 10 - Receive buffer physical address
    MP_Tx_Phys      dd  ?           ; 14 - Transmit buffer physical address
MAC_Ptrs_struc  Ends

MAC_SSC_struc   Struc
    SSC_Len         dw  ?
    SSC_name        dd  ?
    SSC_point       db  ?
MAC_SSC_struc   ends

Addr_Storeage_Struc   Struc
    addr_off        dw  ?
    addr_seg        dw  ?
Addr_Storeage_Struc   Ends

GenReqStruc     struc
    RequestHandle   dw  ?
    Param1          dw  ?
    Param2          dw  ?
    Param3          dw  ?
    GenReqArg       dw  ?
GenReqStruc     ends

BindStruc     struc 
    IndCurrent      dw  ?               ; 0x00 Current indication for IbmTool
    IndNextFree     dw  ?               ; 0x02 Next free slot to fill for Wedge

    IndArrayLDT     dd  ?               ; 0x04 Array of slots for indications
	IndArray		dd	?				; 0x08 GDT pointer to above array
    RcvDataLDT      dd  ?               ; 0x0C Buffer for received frames
	RcvData			dd	? 				; 0x10 GDT pointer to above array
    RcvPhysAddr     dd  ?               ; 0x14 physical address of buffer

    RxWait          dw  ?               ; 0x18 Whether RxChain returns
                                        ;         WAIT_FOR_RELEASE
    ResponseMode    dw  ?               ; 0x1A PEEPER, WKSTA, SERVER
    StressMode      dw  ?               ; 0x1C Whether in stress test or not.

    TotalRx         dd  ?               ; 0x1E Good frames Rx'ed in stress test
    TotalTx         dd  ?               ; 0x22 Good frames Tx'ed in stress test
    RxErr           dd  ?               ; 0x26 Data check errors on Rx in stress
    TxErr           dd  ?               ; 0x2A TxChain errors in stress test
    TxOutResource   dd  ?               ; 0x2E OutOfResource in stress test
    StressCount     dd  ?               ; 0x32 frames to xmit in stress test

    ServerAddress   db  16 dup (?)      ; 0x36 address of server for wksta

    CheckData       dw  ?               ; 0x46 Whether to check Rx frames
    StopOnErr       dw  ?               ; 0x48 Whether to stop when data errors
    HeaderLen       dw  ?               ; 0x4A Length of header for a frame
    NetAddrLen      dw  ?               ; 0x4C Length of a network address
    HeaderToOffset  dw  ?               ; 0x4E Offset of Dest. in frame header
    HeaderFromOffset dw ?               ; 0x50 Offset of Source in frame header
    UseGDT          dw  ?               ; 0x52 Whether to use GDT's with MAC
BindStruc     ends 


;
; Status of transmit echo for stress test
;

TXFREE      equ     0                   ; transmit buffer is ready to fill
                                        ;   set in XmitConfirm
TXREADY     equ     1                   ; transmit buffer is full, ready to xmit
                                        ;   set in StressRcvLkAhead and Chain
TXBUSY      equ     2                   ; transmit buffer is full, and xmitting
                                        ;   set in IndicationComplete

;
; Response modes of Wedge
;
PEEPERMODE  equ     0
WKSTAMODE   equ     1
SERVERMODE  equ     2


;
; Number of locks simultaneously available for a user-mode IbmTool
;
MAX_LOCKS       equ     8

INDIC_QUEUE_LEN equ     32


IndicElement    struc
    IndicType       dw  ?                   ; type of indication
    IndicParm1      dw  ?                   ; parameter for indication
    IndicParm2      dw  ?                   ; parameter for indication
    IndicParm3      dw  ?                   ; parameter for indication
IndicElement    ends


;
; Definitions for Indication specific parameters
;
IndReqC_Handle      equ IndicParm1          ; Handle of queued general request
IndReqC_Status      equ IndicParm2          ; Status of queued general request
IndReqC_Opcode      equ IndicParm3          ; Opcode of queued general request

IndTxC_Handle       equ IndicParm1          ; Handle of queued transmit
IndTxC_Status       equ IndicParm2          ; Status of queued transmit

IndRxLk_FrameSz     equ IndicParm1          ; Size of received frame
IndRxLk_BytesAvail  equ IndicParm2          ; Bytes available in Lookahead data

IndRxChain_FrameSz  equ IndicParm1          ; Size of received frame
IndRxChain_Handle   equ IndicParm2          ; Bytes available in Lookahead data

IndStat_Param1      equ IndicParm1          ; Handle of queued general request
IndStat_Opcode      equ IndicParm2          ; Status of queued general request

; Indication complete has no parameters
