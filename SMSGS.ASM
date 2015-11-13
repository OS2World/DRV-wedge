    Title   sMsgs.Asm - Contains Generic Model and Hardware specific messages.
    Page    , 132
;
; Copyright (C) 1989, 1990, 1991 DWB Associates, All Rights Reserved
;
;   All messages must reside in this file.
;

.xlist
; Build Configuration Information.
    Include Build.Cfg

; standard segment definitions
    Include Segments.inc
.list

;
; Messages used by the Generic Model.
;

Cr      Equ 13
Lf      Equ 10

_Data   Segment

    Public  AdapterMsg
AdapterMsg  DB  "NDIS Wedge driver, version "
        DB  MAJOR_VERSION_STR, ".", MINOR1_VERSION_STR, MINOR2_VERSION_STR, ".", Cr, Lf, 0

    Public  EnvInitFail
EnvInitFail DB  "Failure: Environment invalid, Driver not loaded.", Cr, Lf, 0

    Public  NDISInitFail
NDISInitFail    DB  "Failure: NDIS environment invalid, Driver not loaded.", Cr, Lf, 0

    Public  AllocBufFail
AllocBufFail    DB  "Failure: Unable to Allocate Buffers, Driver not loaded.", Cr, Lf, 0

    Public  NoProtoIniMatch
NoProtoIniMatch DB  "Failure: Protocol.Ini does not have an entry for MAC_NIF.", Cr, Lf, 0

    Public  NoDrvrNameKW
NoDrvrNameKW    DB  "Failure: Protocol.Ini does not have an DRIVERNAME = ADAPT.", Cr, Lf, 0

    Public  NoKeyWordFound
NoKeyWordFound  DB  "Warning: Protocol.Ini Is missing a Key Entry or is incorrect type.", Cr, Lf, 0

    Public  ProtMgrErr
ProtMgrErr  DB  "Failure: Protocol Manager did not accept MAC driver.", Cr, Lf, 0

    Public  GDTAllocFail
GDTAllocFail DB "Failure: Wedge failed to allocate transmit and receive GDT selectors.", Cr, Lf, 0


;
; Messages unique to the Hardware specific code.
;


_Data   Ends

    End

