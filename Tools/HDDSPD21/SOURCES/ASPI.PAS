{$X+,G+,D-,L-,S-,R-}
unit ASPI;

interface

uses Objects, Drivers, Service;

const

    {Valid ASPI Command Codes:}
    SC_HostInquiry    = $00;   {Host Adapter Inquiry}
    SC_GetDeviceType  = $01;   {Get Device Type}
    SC_ExecuteIO      = $02;   {Execute SCSI I/O Command}
    SC_AbortIO        = $03;   {Abort SCSI I/O Command}
    SC_ResetDevice    = $04;   {Reset SCSI Device}
    SC_SetHostParams  = $05;   {Set Host Adapter Parameters}
    SC_GetDriveInfo   = $06;   {Get Disk Drive Information}

    {ASPI Status Bytes:}
    SS_PENDING       = $00;  {SCSI Request in Progress               }
    SS_COMP          = $01;  {SCSI Request Completed Without Error   }
    SS_ABORTED       = $02;  {SCSI Request Aborted by Host           }
    SS_ERR           = $04;  {SCSI Request Completed With Error      }
    SS_INVALID_CMD   = $80;  {Invalid SCSI Request                   }
    SS_INVALID_HA    = $81;  {Invalid Host Adapter Number            }
    SS_NO_DEVICE     = $82;  {SCSI Device Not Installed              }

    SR_ExtReqAsk     = $AA55;
    SR_ExtReqOK      = $55AA;

    Ext_Residual     = $02;  {Residual byte length reported}
    Ext_Wide32       = $04;  {Wide SCSI 32-bit Host Adapter}
    Ext_Wide16       = $08;  {Wide SCSI 16-bit Host Adapter}

    Drv_NoInt13Access    = 0;
    Drv_Int13DOSAccess   = 1;
    Drv_Int13NoDOSAccess = 2;

    SCSI_DevType : Array [0..9] of String[25] =
    (
     'Disk Drive',
     'Tape Drive (Streamer)',
     'Printer',
     'Processor',
     'WORM Drive',
     'CD-ROM Drive',
     'Scanner',
     'Optical Drive',
     'Medium Changer',
     'Communications Device'
    );

type

   TSRB = Record
     Command     : Byte;
     Status      : Byte;
     HostAdapter : Byte;
     Request     : Byte;
     Reserved    : Array [1..4] of Byte;
   end;

   TInquirySRB = Record
     Command     : Byte;                {W:Command Code = 0}
     Status      : Byte;                {R:Command Status. This byte always returns with a non-zero code}
     HostAdapter : Byte;
     RequestFlags: Byte;
     ExtRequest  : Word;
     BufLength   : Word;
     HostsCount  : Byte;
     HID         : Byte;
     ManagerID   : Array [1..16] of Char;
     HostID      : Array [1..16] of Char;
     HostUnique  : Array [1..16] of Byte;
     Extensions  : Word;
   end;


   TGetDeviceTypeSRB = Record
     Command     : Byte;                {W:Command Code = 0}
     Status      : Byte;                {R:Command Status. This byte always returns with a non-zero code}
     HostAdapter : Byte;
     RequestFlags: Byte;
     Reserved    : Array [1..4] of Byte;
     TargetID    : Byte;
     LUN         : Byte;
     DeviceType  : Byte;
   end;

   TGetDriveInfoSRB = Record
     Command     : Byte;                {W:Command Code = 0}
     Status      : Byte;                {R:Command Status. This byte always returns with a non-zero code}
     HostAdapter : Byte;
     RequestFlags: Byte;
     Reserved    : Array [1..4] of Byte;
     TargetID    : Byte;
     LUN         : Byte;
     DriveFlags  : Byte;
     Int13Drive  : Byte;
     PreferHead  : Byte;
     PreferSect  : Byte;
     Reserved0   : Byte;
   end;

  PSCSICollection = ^TSCSICollection;
  TSCSICollection = Object(TCollection)
    constructor Init;
    procedure   FreeItem(Item: Pointer); virtual;
  end;

var
  ASPIEntryPoint : Pointer;
  ASPI_Ok        : Boolean;
  InqSRB         : TInquirySRB;
  DevTypeSRB     : TGetDeviceTypeSRB;
  DrvInfoSRB     : TGetDriveInfoSRB;

function  ASPIInit : Boolean;
procedure ASPICall(SRB : Pointer);
function  ASPIHostAdapterInquiry : Boolean;
function  ASPIGetDeviceType(Host,Target,LUN : Byte) : Boolean;
function  ASPIGetDriveInfo(Host,Target,LUN : Byte) : Boolean;

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function GetASPIHandle : Word; assembler;
const
   SCSIMgrName : Array [0..8] of Char = 'SCSIMGR$'#0;
asm
   push ds
   mov  ax,Seg SCSIMgrName
   mov  ds,ax
   mov  dx,Offset SCSIMgrName
   mov  ax,3D00h
   int  21h
   jnc  @1
   xor  ax,ax
@1:
   pop  ds
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function GetASPIEntryPoint(Handle : Word) : Pointer; assembler;
asm
   push ds
   mov  ax,Seg ASPIEntryPoint
   mov  ds,ax
   mov  dx,Offset ASPIEntryPoint
   mov  ax,4402h
   mov  cx,4
   mov  bx,Handle
   int  21h
   mov  si,Offset ASPIEntryPoint
   mov  ax,[si]
   mov  dx,[si+2]
   pop  ds
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure CloseFile(Handle : Word); assembler;
asm
   mov  bx,Handle
   mov  ah,3Eh
   int  21h
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function ASPIInit : Boolean;
var
  Handle : Word;
begin
  ASPI_Ok := False; ASPIInit := False;
  Handle := GetASPIHandle;
  If Handle = 0 Then Exit;
  If GetASPIEntryPoint(Handle) = Nil Then Exit;
  CloseFile(Handle);
  ASPIInit := True; ASPI_Ok := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure ASPICall(SRB : Pointer); assembler;
asm
  mov     ax,word ptr SRB+2
  push    ax                  {Push SRB's segment}
  mov     ax,word ptr SRB
  push    ax                  {Push SRB's offset}
  call    ASPIEntryPoint      {Call ASPI}
  add     sp,4                {Restore the stack}
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function ASPIHostAdapterInquiry : Boolean;
begin
  ASPIHostAdapterInquiry := False;
  InqSRB.Command := SC_HostInquiry;
  InqSRB.HostAdapter := 0;
  InqSRB.RequestFlags := 0;
  InqSRB.ExtRequest := SR_ExtReqAsk;
  InqSRB.BufLength := 4;

  ASPICall(@InqSRB);
  ASPIHostAdapterInquiry := InqSRB.Status = SS_COMP;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function ASPIGetDeviceType(Host,Target,LUN : Byte) : Boolean;
begin
  ASPIGetDeviceType := False;
  DevTypeSRB.Command := SC_GetDeviceType;
  DevTypeSRB.HostAdapter := Host;
  DevTypeSRB.TargetID := Target;
  DevTypeSRB.LUN := LUN;

  ASPICall(@DevTypeSRB);
  ASPIGetDeviceType := DevTypeSRB.Status = SS_COMP;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function ASPIGetDriveInfo(Host,Target,LUN : Byte) : Boolean;
begin
  ASPIGetDriveInfo := False;
  DrvInfoSRB.Command := SC_GetDriveInfo;
  DrvInfoSRB.HostAdapter := Host;
  DrvInfoSRB.TargetID := Target;
  DrvInfoSRB.LUN := LUN;

  ASPICall(@DrvInfoSRB);
  ASPIGetDriveInfo := DrvInfoSRB.Status = SS_COMP;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                         TSCSICollection.'s Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TSCSICollection.Init;
const
  FStr = '%-17s %s';
var
  Host, Target, LUN : Byte;
  S, HTL, D : String;

  FormatRec : Record
    HTL     : PString;
    Device  : PString;
  end;

begin
  inherited Init(8,1);

  If not ASPIInit Then Exit;
  If not ASPIHostAdapterInquiry Then Exit;

  for Host := 0 to InqSRB.HostsCount-1 do
  begin
    For Target := 0 to 7 do
    begin
      LUN := 0;
      While ASPIGetDeviceType(Host,Target,LUN) and (LUN <=7) and (DevTypeSRB.DeviceType < $7F) do
      begin
        HTL := IntToStr(Host)+'/'+IntToStr(Target)+'/'+IntToStr(Lun);

        If DevTypeSRB.DeviceType in [0..9]
          Then D := SCSI_DevType[DevTypeSRB.DeviceType]
          Else D := 'Unknown (Type '+ByteToHexStr(DevTypeSRB.DeviceType)+'h)';

        FormatRec.HTL := @HTL;
        FormatRec.Device := @D;
        FormatStr(S, FStr, FormatRec);

        Insert(NewStr(S));

        Inc(LUN);
      end;
    end;
  end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TSCSICollection.FreeItem(Item: Pointer);
begin
  If Item <> Nil then DisposeStr(Item);
end;

begin
end.
