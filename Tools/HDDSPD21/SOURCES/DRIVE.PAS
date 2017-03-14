{$M 16384, $20000, $20000}
{$X+,G+,D-,L-,S-,R-}
unit Drive;

interface

uses Objects, Service, Crt;

type
  TSector = Record
    Flag  : Byte;
    No    : Byte;
  end;

  PTrackMap = ^TTrackMap;
  TTrackMap = Array [1..256] of TSector;

  PDrive = ^TDrive;
  TDrive = Object(TObject)
    BIOSDriveNumber : Integer;
    Heads           : Byte;
    Sectors         : Byte;
    Tracks          : Word;

    Status,                             {Current operation status}
    LastError       : Integer;          {Last error code}

    constructor Init(DrvNum : Integer);
    destructor  Done; virtual;

    function  ResetController : Byte; virtual;
    function  CheckDiskStatus : Byte; virtual;
    function  ControllerDiagnostic : Byte; virtual;
    function  RecalibrateDrive : Byte; virtual;
    function  IsDriveInstalled : Byte; virtual;
    function  GetBIOSGeometry(var BIOSTracks : Word; var BIOSHeads, BIOSSectors : Byte) : Byte; virtual;
    function  ReadSectors(Track : Word; Head, StartSect, SectorsCount : Byte; Buffer : Pointer) : Byte; virtual;
    function  WriteSectors(Track : Word; Head, StartSect, SectorsCount : Byte; Buffer : Pointer) : Byte; virtual;
    function  VerifySectors(Track : Word; Head, StartSect, SectorsCount : Byte) : Byte; virtual;
    function  DetailedVerifyTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte; virtual;
    function  FormatTrack(Track : Word; Head : Byte; Buffer : Pointer) : Byte; virtual;
    function  SeekToTrack(Track : Word) : Byte; virtual;

    function  RecoverTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte; virtual;

    function  GetErrorMessage(ErrorCode : Integer) : String; virtual;
    function  GetModel : String; virtual;
    function  GetType : String; virtual;
    function  GetSize : LongInt; virtual;
    procedure ResetStatus; virtual;
  end;

function GetDrivesNumber : Byte;

implementation


{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function GetDrivesNumber : Byte; assembler;
asm
  mov   ah,08h
  mov   dl,80h
  int   13h
  mov   al,0
  jc    @1
  mov   al,dl
@1:
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TDrive.Init(DrvNum : Integer);
begin
  inherited Init;
  BIOSDriveNumber := DrvNum;
  GetBIOSGeometry(Tracks, Heads, Sectors);
  If (Tracks = 1) or (Heads = 1) or (Sectors = 0) Then Status := -1;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
destructor TDrive.Done;
begin
  inherited Done;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.ResetController : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov ah,0
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; ResetController := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.CheckDiskStatus : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov ah,1
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; CheckDiskStatus := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.ControllerDiagnostic : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov ah,14h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; ControllerDiagnostic := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.RecalibrateDrive : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov ah,11h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; RecalibrateDrive := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.IsDriveInstalled : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov ah,15h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; IsDriveInstalled := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.GetBIOSGeometry(var BIOSTracks : Word; var BIOSHeads, BIOSSectors : Byte) : Byte;
var
  Drive : Byte;
  MaxHead,
  MaxSector : Byte;
  MaxTrack  : Word;
  Stat      : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  MaxTrack := 0; MaxHead := 0; MaxSector := 0;
  asm
     mov ah,8
     mov dl,Drive
     int 13h
     jnc @1
     mov Stat,ah
     jmp @2
  @1:
     dec dl
     or dl,80h
     cmp dl,BIOSDriveNumber
     jc @2
     mov MaxHead,dh
     mov al,cl
     and al,$3f
     mov MaxSector,al
     xor ax,ax
     and cl,$C0
     mov al,cl
     shl ax,2
     mov al,ch
     mov MaxTrack,ax
  @2:
  end;
  BIOSTracks := MaxTrack+1; BIOSHeads := MaxHead+1; BIOSSectors := MaxSector;
  Status := Stat; GetBIOSGeometry := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.ReadSectors(Track : Word; Head, StartSect, SectorsCount : Byte; Buffer : Pointer) : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov dh,Head
     mov cx,Track
     xchg cl,ch
     shl cl,6
     add cl,StartSect
     les bx,Buffer
     mov al,SectorsCount
     mov ah,02h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; ReadSectors := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.WriteSectors(Track : Word; Head, StartSect, SectorsCount : Byte; Buffer : Pointer) : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov dh,Head
     mov cx,Track
     xchg cl,ch
     shl cl,6
     add cl,StartSect
     les bx,Buffer
     mov al,SectorsCount
     mov ah,03h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; WriteSectors := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.VerifySectors(Track : Word; Head, StartSect, SectorsCount : Byte) : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov dh,Head
     mov cx,Track
     xchg cl,ch
     shl cl,6
     or cl,StartSect
     mov al,SectorsCount
     mov ah,04h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; VerifySectors := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.DetailedVerifyTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte;
var
   i : Word;
   Errors : Byte;
begin
  Errors := 0;
  for i := 1 to Sectors do
    With TrackMap[i] do
    begin
      Flag := VerifySectors(Track, Head, i, 1);
      If Flag <> 0 Then Inc(Errors);
      No   := i;
    end;
  DetailedVerifyTrack := Errors;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.FormatTrack(Track : Word; Head : Byte; Buffer : Pointer) : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov dh,Head
     mov cx,Track
     xchg cl,ch
     shl cl,6
     add cl,1
     les bx,Buffer
     mov ah,05h
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; FormatTrack := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.SeekToTrack(Track : Word) : Byte;
var
  Drive : Byte;
  Stat  : Byte;
begin
  Drive := BIOSDriveNumber; Stat := 0;
  asm
     mov dl,Drive
     mov dh,0
     mov cx,Track
     xchg cl,ch
     shl cl,6
     or cl,1              {???}
     mov ah,0Ch
     int 13h
     jnc @1
     mov Stat,ah
  @1:
  end;
  Status := Stat; SeekToTrack := Stat;
  If Stat <> 0 Then LastError := Stat;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.RecoverTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte;
type
  PTrackBuf = ^TTrackBuf;
  TTrackBuf = Array [1..64] of Array [0..511] of Byte;
var
  k       : Byte;
  Buffer  : PTrackBuf;
  Defects : Byte;
begin
  RecoverTrack := $FF;
  MemAlloc(Pointer(Buffer), 64*1024 div 16); {16 byte paragraphs}
  If Buffer = Nil Then Exit;

  Defects := 0;
  for k := 1 to Sectors do
    With TrackMap[k] do
    begin
      {20h - unassign alternate, 40h - assign alternate}
      If Flag = 0
        Then ReadSectors(Track, Head, k, 1, @Buffer^[k])
        Else begin
               Inc(Defects);
               FillChar(Buffer^[k], 512, #0);
               Flag := $40;

               {Try to use write auto-reassignment}
               WriteSectors(Track, Head, k, 1, @Buffer^[k]);
               If VerifySectors(Track, Head, k, 1) = 0 Then
               begin
                 Dec(Defects);
                 Flag := 0;
               end;
             end;
      No   := k;
    end;

  If Defects > 0 Then
  begin
    FormatTrack(Track, Head, @TrackMap);

    ResetStatus;
    for k := 1 to Sectors do
      WriteSectors(Track, Head, k, 1, @Buffer^[k]);

    MemFree(Pointer(Buffer));
    RecoverTrack := LastError;
  end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TDrive.GetErrorMessage(ErrorCode : Integer) : String;
begin
  Case ErrorCode of
     -1 : GetErrorMessage := 'Specified drive not exist';
     -2 : GetErrorMessage := 'Can''t allocate '+IntToStr(Sectors div 2)+'Kb of conventional memory for test buffer';
     -3 : GetErrorMessage := 'Can''t allocate '+IntToStr(Heads*Sectors div 2+1)+'Kb of XMS memory for cylinder buffer';
    $00 : GetErrorMessage := 'No error on last operation';
    $01 : GetErrorMessage := 'Bad command: invalid request to controller';
    $02 : GetErrorMessage := 'Bad address mark';
    $03 : GetErrorMessage := 'Attempted to write on write-protected disk';
    $04 : GetErrorMessage := 'Sector ID bad or not found';
    $05 : GetErrorMessage := 'Reset failed';
    $07 : GetErrorMessage := 'Drive parameter activity failed';
    $08 : GetErrorMessage := 'DMA failure';
    $09 : GetErrorMessage := 'DMA overrun: can''t write across 64K bound';
    $0A : GetErrorMessage := 'Bad sector flag detected';
    $0B : GetErrorMessage := 'Bad cylinder detected';
    $0D : GetErrorMessage := 'Invalid umber of sectors in format';
    $0E : GetErrorMessage := 'Control data address mark detected';
    $0F : GetErrorMessage := 'DMA arbitration level out of range';
    $10 : GetErrorMessage := 'Uncorrectable ECC or CRC';
    $11 : GetErrorMessage := 'ECC corrected data error';
    $20 : GetErrorMessage := 'Hard disk controller failure';
    $40 : GetErrorMessage := 'Bad seek: requested track not found';
    $80 : GetErrorMessage := 'Time-out';
    $AA : GetErrorMessage := 'Drive not ready';
    $BB : GetErrorMessage := 'Undefined error';
    $CC : GetErrorMessage := 'Write fault on selected drive';
    $E0 : GetErrorMessage := 'Status error/error register 0';
    $FF : GetErrorMessage := 'Sense operation failed';
    Else  GetErrorMessage := 'Unknown error';
  end
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.GetModel : String;
begin
  GetModel := 'Non-IDE Drive';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.GetType : String;
begin
  GetType := 'Unknown Type';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TDrive.GetSize : LongInt;
{Size in MBytes}
begin
  GetSize := LongInt(Tracks)*LongInt(Heads)*LongInt(Sectors) div 2048;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TDrive.ResetStatus;
begin
  Status := 0; LastError := 0;
end;

begin
end.
