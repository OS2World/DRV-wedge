;
; Copyright (C) 1989, 1990, 1991 DWB Associates, All Rights Reserved
;

;***    Segments.inc -- Segment definitions, order, and macros
;
; Functional Description
;   This file defines the segments used by a MAC driver and the order
;   in which they are loaded. The groups DGROUP (for data) and CGROUP
;   (for code) are also defined, as are macros to opan and close
;   segments (which also set up the default segment assumptions).
;
;-----------------------------------------------------------------------

;** Group Definitions

;** Segment Definitions - order counts!
; Device driver header segment - The device driver header is given its
; own segment so that it can be forced to the front of the image.
;
; DOS Order:
;       DGROUP
;           DevHeaderSeg
;           _DATA 
;           IDATA
;           CONST
;           _BSS
;       CGROUP
;           _TEXT
;                   ; Code and data will be cut off here.
;           ICODE
;
;
; OS2 Order:
;       DGROUP
;           DevHeaderSeg
;           _DATA 
;           IDATA
;       CGROUP 
;           _TEXT
;           ICODE

If  DOS ; -------------------------------------------------------------

DevHeaderSeg    segment word public 'DATA'
DevHeaderSeg    ends

; Resident Data segment - things put here will remain in memory after
; init time. At the present time, this is in low memory, so data that is
; not used after init time should NOT be put in this segment.
;
_DATA       segment word public 'DATA'
_DATA       ends

CONST       segment word public 'CONST'
CONST       ends
_BSS        segment word public 'BSS'
_BSS        ends


; Resident Code segment - code that is used after init time
; (unfortunately, this includes code to bind another driver, and
; initializations that take place at bind time) should be placed in this
; segment.
;
_TEXT       segment word public 'CODE'
_TEXT       ends

; Discardable Code segment - code that is only used at DOS init time
; should be placed in this segment so that the space it occupies can be
; recovered by the operating system after initializing the driver.
;
ICODE       segment word public 'INIT'
ICODE       ends

; Discardable Data segment - data that is only used at init time should
; be put in this segment (most strings, pre-defined data structures
; copied into adapter RAM at init time, etc.).
;
IDATA       segment word public 'INIT'
IDATA       ends

Else    ; OS/2 ----------------------------------------------------------------

DevHeaderSeg    segment word public 'DATA'
DevHeaderSeg    ends

; Resident Data segment - things put here will remain in memory after
; init time. At the present time, this is in low memory, so data that is
; not used after init time should NOT be put in this segment.
;
_DATA       segment word public 'DATA'
_DATA       ends

CONST       segment word public 'CONST'
CONST       ends
_BSS        segment word public 'BSS'
_BSS        ends

; Discardable Data segment - data that is only used at init time should
; be put in this segment (most strings, pre-defined data structures
; copied into adapter RAM at init time, etc.).
;
IDATA       segment word public 'DATA'
IDATA       ends

; Resident Code segment - caode that is used after init time
; (unfortunately, this includes code to bind another driver, and
; initializations that take place at bind time) should be placed in this
; segment.
;
_TEXT       segment word public 'CODE'
_TEXT       ends

; Discardable Code segment - code that is only used at DOS init time
; should be placed in this segment so that the space it occupies can be
; recovered by the operating system after initializing the driver.
;
ICODE       segment word public 'ICODE'
ICODE       ends

Endif       ; -------------------------------------------------------------


; Make sure the segment order defined in this file is respected.

.SEQ                    


If  DOS ; ------------------------------------------------------------

.8086

DGROUP      group   DevHeaderSeg, _DATA, CONST, _BSS,_TEXT, IDATA,ICODE
CGROUP      equ     DGROUP  

;** Default Assume Directive

DefAssume   Macro
        Assume  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:NOTHING
        Endm

    Assume  CS:DGROUP, DS:DGROUP, ES:NOTHING, SS:NOTHING


Else    ; OS/2 ---------------------------------------------------------------

.286p

DGROUP      group   DevHeaderSeg, _DATA, CONST, _BSS, IDATA
CGROUP      group   _TEXT, ICODE

;** Default Assume Directive

DefAssume   Macro
        Assume  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:NOTHING
        Endm

    Assume  CS:CGROUP, DS:DGROUP, ES:NOTHING, SS:NOTHING

Endif       ; ------------------------------------------------------------

