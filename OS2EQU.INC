    Subttl  OS2Equ.inc - Equates and Definitions for OS/2 Device Drivers.
;
;   Main Include file for OS/2 Device Driver functions.
;
;
TRUE            =   1   ; Set to Logical true.
FALSE           =   0   ; Set to Logical false.
;

DA_Char_Device      Equ 8000h   ; Set if device driver is character type.
DA_IDC_Cap      Equ 4000h   ; Set if device driver has IDC.
DA_IBM_Block        Equ 2000h   ; Set if NOT IBM Block device.
DA_output_Till_Busy Equ 2000h   ; Set if char device support output until busy.
DA_Shared_Access    Equ 1000h   ; Set if device support shared access checking.
DA_Removable_Media  Equ 0800h   ; Set if block device supports removable media.
DA_Open_Close       Equ 0800h   ; Set if char device supports open close.
DA_OS2_Type     Equ 0080h   ; Set to designate OS/2 device driver.
DA_Clock_Device Equ 0008h   ; Set if Driver is a clock device.
DA_Null_Device      Equ 0004h   ; Set if driver is a Null device.
DA_STDOUT_Device    Equ 0002h   ; Set if driver is Standard Out Device.
DA_STDIN_Device Equ 0001h   ; Set if driver is Standard In Device.

;
;   Equates for Device Helper Services.
;   As defined in the OS/2 Technical Reference, Vol 1, Page 8-1.
;   This does not include defs for IBM or PS/2 specific functions.
;
DH_SchedClockAddr   Equ 0   ; Get system clock routine.
DH_DevDone      Equ 1   ; Device I/O complete.
DH_Yield        Equ 2   ; Yield the CPU (to other threads).
DH_TCYield      Equ 3   ; Yield Time Critical CPU threads.
DH_Block        Equ 4   ; Block thread from execution.
DH_Run          Equ 5   ; Unblock thread.
DH_SemRequest       Equ 6   ; Claim a Semaphore.
DH_SemClear     Equ 7   ; Clear a Semaphore (release).
DH_SemHandle        Equ 8   ; Get a Semaphore Handle.
DH_PushReqPacket    Equ 9   ; Add request to list (queue).
DH_PullReqPacket    Equ 0AH ; Remove request from list (dequeue).
DH_PullParticular   Equ 0BH ; Remove a specific request from list.
DH_SortReqPacket    Equ 0CH ; Insert request in sorted order to list.
DH_AllocReqPacket   Equ 0DH ; Get a Blank Request Packet.
DH_FreeReqPacket    Equ 0EH ; Free Request Packet (return to pool).
DH_QueueInit        Equ 0FH ; Initialize character queue.
DH_QueueFlush       Equ 10H ; Clear character queue.
DH_QueueWrite       Equ 11H ; Put a character in the queue.
DH_QueueRead        Equ 12H ; Get a character from the queue.
DH_LockSeg      Equ 13H ; Lock Segment. (lock a memory segment).
DH_UnlockSeg        Equ 14H ; Unlock a previously Locked segment.
DH_PhysToVirt       Equ 15H ; Map Physical to Virtual address.
DH_VirtToPhys       Equ 16H ; Map Virtual to Physical address.
DH_PhysToUVirt      Equ 17H ; Map Physical to User Virtual address.
DH_AllocPhys        Equ 18H ; Allocate Physical memory.
DH_FreePhys     Equ 19H ; Free previously AllocPhys memory.
DH_SetROMVector     Equ 1AH ; Set software interrupt vector.
DH_SetIRQ       Equ 1BH ; Set a hardware interrupt handler.
DH_UnSetIRQ     Equ 1CH ; Reset a hardware interrupt handler.
DH_SetTimer     Equ 1DH ; Set a Timer Handler.
DH_ResetTimer       Equ 1EH ; Remove a timer handler.
DH_MonitorCreate    Equ 1FH ; Create a monitor task.
DH_Register     Equ 20H ; Install a monitor.
DH_DeRegister       Equ 21H ; Remove a monitor.
DH_MonWrite     Equ 22H ; Pass data record to monitor.
DH_MonFlush     Equ 23H ; Remove all data from stream.
DH_GetDOSVar        Equ 24H ; Return pointer to DOS variable.
DH_SendEvent        Equ 25H ; Indicate an event.
DH_ROMCritSection   Equ 26H ; ROM BIOS Critical Section Flag.
DH_VerifyAccess     Equ 27H ; Verify Memory access (valid).
DH_AllocGDTSelector Equ 2DH ; Allocate GDT Selectors.
DH_PhysToGDTSelector    Equ 2EH ; Map Physical to virtual address via GDT.
DH_RealToProt       Equ 2FH ; Switch from Real Mode to Protected Mode.
DH_ProtToReal       Equ 30H ; Switch from Protected Mode to Real Mode.
DH_EOI          Equ 31H ; Issue an End of Interrupt to the 8259.
DH_UnPhysToVirt     Equ 32H ; Mark PhysToVirt Complete.
DH_TickCount        Equ 33H ; Modify Timer.
DH_RegisterStackUsage   Equ 38H ; Register how much stack the ISR will use.
;
;
;   Equates for Category 8 and 9 generic IOCtl requests.
;   As defined in the OS/2 Technical Reference, Vol 2, 6-162  & 6-179.
;
;   Logical Disk IOCtl Commands
;
;   Note: Commands that are less than 40H are intercepted by OS/2 kernel.
;
Logical_Category    Equ 8H  ; Logical Disk IOCtl category.
Lock_Drive      Equ 0H  ; Lock the logical drive (exclude other processes).
Unlock_Drive        Equ 01H ; Unlock the previously locked drive.
Determine_Media     Equ 02H ; Regenerate the internal unit ID.
Set_Logical_Map     Equ 03H ; Set Logical to Physical Map.
Block_Removable     Equ 20H ; Return removable media flag.
Get_Logical_Map     Equ 21H ; Return Physical to Logical map.
Set_Device_Parameters   Equ 43H ; Setup the BPB for this device.
Write_Track     Equ 44H ; Write Track.
Format_Verify_Track Equ 45H ; Format and verify track.
Get_Device_Parameters   Equ 63H ; Return to BPB for this device.
Read_Track      Equ 64H ; Read track.
Verify_Track        Equ 65H ; Verify track.
;
;   Physical Disk Control IOCtl Commands
;
;   Note: Commands that are less than 40H are intercepted by OS/2 kernel.
;
Physical_Category   Equ 09H ; Physical Disk IOCtl category.
Lock_Phys_Drive     Equ 00H ; Lock the physical drive (exclude other processes).
Unlock_Phys_Drive   Equ 01H ; Unlock a previously locked physical drive.
Phys_Write_Track    Equ 44H ; Physical Write Track.
Get_Phys_Device_Parms   Equ 63H ; Return physical drive characteristics.
Phys_Read_Track     Equ 64H ; Physical Read Track.
Phys_Verify_Track   Equ 65H ; Physical Verify Track.
;
;
;   Request Packet Structure
;   As defined in the OS/2 Technical Reference, Vol 1 7-38.
;
Request_Packet      Struc
PCKT_Len        DB  0   ; Packet request length.
PCKT_Unit       DB  0   ; Device or Unit number.
PCKT_Command        DB  0   ; Command / Function code number.
PCKT_Status     DW  0   ; Packet Status code.
EPCKT_RQ_PTR        DD  0   ; Reserved area per IBM & Microsoft.
PCKT_Link       DD  0   ; Reserved for Queue Linkage.
Request_Packet      Ends

;
Media_Request_Packet    Struc
            DB  (TYPE Request_Packet) DUP (0)
Media_Descriptor    DB  0   ; Return media descriptor.
Media_Request_Packet    Ends

;
INIT_Packet     Struc
            DB  (TYPE Request_Packet) DUP (0)
Data_1          DB  0   ; Number of devices.
Pointer_1       DD  0   ; Ptr to DevHlp services.
Pointer_2       DD  0   ; Ptr to Initialaztion arguments.
Data_2          DB  0   ; First device number.
INIT_Packet     Ends

;
;
MEDIA_CHECK_Packet  Struc
            DB  (TYPE Media_Request_Packet) DUP (0)
Return_code     DB  0   ; Status code on completion.
Previous_Volume     DD  0   ; Ptr to Previous volume.
MEDIA_CHECK_Packet  Ends

;
;
BUILD_BPB_Packet    Struc
            DB  (TYPE Media_Request_Packet) DUP (0)
Transfer_Address    DD  0   ; Address of source BPB.
BPB_Table_Ptr       DD  0   ; Ptr to BPB Table.
Drive_Number        DB  0   ; Device drive number.
BUILD_BPB_Packet    Ends

;
;
RWV_Packet      Struc
            DB  (TYPE Media_Request_Packet) DUP (0)
AP_Buffer_Address   DD  0   ; Application Buffer address.
Sector_count        DW  0   ; Request sector count.
Start_sector        DD  0   ; Logical start sector.
RWV_File_Number     DW  0   ; System File Number (Handle).
RWV_Packet      Ends

;
;
STATUS_Packet       Struc
            DB  (TYPE Request_Packet) DUP (0)
STATUS_Packet       Ends

;
;
FLUSH_Packet        Struc
            DB  (TYPE Request_Packet) DUP (0)
FLUSH_Packet        Ends

;
;
OPEN_CLOSE_Packet   Struc
            DB  (TYPE Request_Packet) DUP (0)
OC_File_Number      DW  0   ; System file number (Handle).
OPEN_CLOSE_Packet   Ends

;
;
REMOVABLE_MEDIA_Packet  Struc
            DB  (TYPE Request_Packet) DUP (0)
REMOVABLE_MEDIA_Packet  Ends

;
;
GENERIC_IOCtl_Packet    Struc
            DB  (TYPE Request_Packet) DUP (0)
Category            DB  0   ; Function Category.
Function_Code       DB  0   ; IOCtl Function Code.
Parm_Buffer_address DD  0   ; Parameter buffer address.
Data_Buffer_address DD  0   ; Data Buffer address.
IOCtl_File_Number   DW  0   ; System File Number (handle).
GENERIC_IOCtl_Packet    Ends

;
IOCTl_TrackRWV_PP   Struc
RWV_Cmd_Info        DB  0   ; Type of Sector IO to do.
RWV_Head        DW  0   ; Physical drive head.
RWV_Cylinder        DW  0   ; Physical cylinder of the drive.
RWV_First_Sector    DW  0   ; Physical first sector of IO.
RWV_No_Sectors      DW  0   ; No of sectors in this IO.
RWV_Sector_Table    DW  0   ; Beginning of sector layout table
IOCTl_TrackRWV_PP   Ends

;
IOCTl_Format_PP     Struc
Format_type_Cmd     DB  0   ; Type of format to do.
Format_Head     DW  0   ; Head to format.
Format_Cylinder     DW  0   ; Cylinder to format.
            DW  0   ; Reserved.
Format_Sector_Count DW  0   ; No of sectors per track.
Format_Track_Table  DB  0   ; Beginning of format table.
IOCTl_Format_PP     Ends

;
;
RESET_MEDIA_Packet  Struc
            DB  (TYPE Request_Packet) DUP (0)
RESET_MEDIA_Packet  Ends

;
;
LOGICAL_DRIVE_Packet    Struc
            DB  (TYPE Request_Packet) DUP (0)
LOGICAL_DRIVE_Packet    Ends

;
;
PARTITION_Packet    Struc
            DB  (TYPE Request_Packet) DUP (0)
Partition_Count     DB  0   ; Number of partitions for this device.
            DW  0   ; Reserved by IBM & Microsoft.
            DW  0   ; Reserved by IBM & Microsoft.
PARTITION_Packet    Ends

;
;
GET_UNIT_MAP_Packet Struc
            DB  (TYPE Request_Packet) DUP (0)
Units_Supported_Mask    DD  0   ; Bit map mask of supported units.
            DW  0   ; Reserved by IBM & Microsoft.
            DW  0   ; Reserved by IBM & Microsoft.
GET_UNIT_MAP_Packet Ends

;
;   Status Error Codes.
;
STERR       Equ 8000h       ; Bit 15 - Error.
STDON       Equ 0100h       ; Bit  8 - Done.
GENERR      Equ 31          ; general error.
INVFUN      Equ 1           ; INVALID FUNCTION.
STECODE     Equ 00FFh       ; Error code:
UNK_CMD     Equ 0003h       ; Unknown command.


;
BPB_Struc       Struc
Bytes_Per_Sector    DW  0   ; Total bytes for 1 sector.
Sectors_Per_Cluster DB  0   ; Number of sectors in a cluster.
Reserved_Sectors    DW  0   ; Number of Reserved Sectors.
Number_of_FATS      DB  0   ; Number of FAT tables.
Root_DIR_Entries    DW  0   ; Number of root directory entries.
Total_Sectors       DW  0   ; Total Number of sectors.
BPB_Media_Descriptor    DB  0   ; Media Descriptor byte.
Sectors_Per_FAT     DW  0   ; Number of sectors used by FAT table.
Sectors_Per_Track   DW  0   ; Number of physical sector per track.
Number_of_Heads     DW  0   ; Number of physical drive heads.
Hidden_Sectors      DD  0   ; Number of sectors hidden for OS.
Large_Total_Sectors DD  0   ; Over 32mb count of sectors.
; Extended BPB area
Physical_Drive_No   DB  0   ; Physical Drive number.
BPB_Reserved1       DB  0   ; Reserved field.
Signature_Byte      DB  0   ; Signature byte should be 29H.
Volume_Serial_No    DD  0   ; Volume serial number.
BPB_Struc       Ends

;
;
StackUsage      Struc
SU_No_Bytes     DW  14D ; Set length of packet.
SU_Flags        DW  0001H   ; Set to indicate enabling of interrupts.
SU_IRQ          DW  0   ; Set to the IRQ number.
SU_StackCLI     DW  0   ; Size of stack usage during CLI.
SU_StackSTI     DW  0   ; Size of stack usage during STI.
SU_StackEOI     DW  0   ; Size of stack after EOI.
SU_Nest         DW  0   ; Nesting level of ISR.
StackUsage      Ends
;

;
GDT_Desc        Struc
Seg_Limit0_15       DW  0   ; Low word of segment limit.
Seg_Base0_15        DW  0   ; Low word of physical segment base.
Seg_Base16_23       DB  0   ; Segment base bits 16 - 23.
Type_DPL        DB  0   ; Type and DPL fields.
Gran_Limit16_19 DB  0   ; Granularity and Limit 16 - 19 bits.
Seg_Base24_31       DB  0   ; Segment base bits 24 - 31.
GDT_Desc        Ends
;

STDOUT      Equ 1       ; Handle for Standard Out device.

