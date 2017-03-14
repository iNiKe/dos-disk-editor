{$X+,G+,D-,L-,S-,R-}
{*$DEFINE DEBUG}
unit IDE;

interface

uses Service;

const
   ON  = True;
   OFF = False;

   Enabled  = True;
   Disabled = False;

   mLBA    = 0;
   mCHS    = 1;

   dMaster = 0;
   dSlave  = 1;

   chPrimary    = 0;
   chSecondary  = 1;
   chTertiary   = 2;
   chQuaternary = 3;

   Channel   : Array [0..3] of String[15] = ('Primary','Secondary','Tertiary','Quaternary');
   ChannelN  : Array [0..3] of Word = ($1F0, $170, $1E8, $168);
   Disk      : Array [0..1] of String[15] = ('Master','Slave');
   DriveMode : Array [0..1] of String[6] = ('LBA','CHS');

   hdcDataReg         = 0;
   hdcErrorReg        = 1;
   hdcFeaturesReg     = 1;
   hdcSectorsCountReg = 2;


   mwDMA0    = $20;
   mwDMA1    = $21;
   mwDMA2    = $22;
   UltraDMA0 = $40;
   UltraDMA1 = $41;
   UltraDMA2 = $42;

   feLBA                = $01;
   feDMA                = $02;
   feBlockMode          = $04;
   fePowerManagement    = $08;
   feSMART              = $10;

   IODelay = 10;

   hdcBSY  = $80;
   hdcDRDY = $40;
   hdcDRQ  = $08;
   hdcERR  = $01;

   hdcABRT = $40;

   sfCritical     = $01;
   sfPerformance  = $04;
   sfErrorRate    = $08;
   sfEventCount   = $10;
   sfSelfPreserve = $20;

type

  PIDEInfo = ^TIDEInfo;                  {Comments between *STARS* describes current
                                          field status in ATA/ATAPI-5 working draft rev. C}
  TIDEInfo = Record
    Config      : Word;                  {0: General configuration bit-significant information}
    Cyls        : Word;                  {1: Number of logical cylinders}
    Specific    : Word;                  {2: Vendor-specific configuration}
    Heads       : Word;                  {3: Number of logical heads}
    BPT         : Word;                  {4: *RETIRED* Number of unformatted bytes per track}
    BPS         : Word;                  {5: *RETIRED* Number of unformatted bytes per sector}
    SPT         : Word;                  {6: Number of logical sectors per logical track}
    Vendor      : Array [0..2] of Word;  {7-9: Vendor specific}
    Serial      : Array [1..20] of Char; {10-19: Serial number. 20 ASCii characters, 0000H=not specified}
    BufType     : Word;                  {20: *RETIRED* Buffer type}
    BufSize     : Word;                  {21: *RETIRED* Buffer size in 512 byte increments. 0000H=not specified}
    ECC         : Word;                  {22: *OBSOLETE* Number of ECC bytes avail on read/write long cmds. 0000H=not spec.}
    Revision    : Array [1..8] of Char;  {23-26: Firmware revision. 8 ASCii characters. 0000H=not specified}
    Model       : Array [1..40] of Char; {27-46: Model number. 40 ASCii characters. 0000H=not specified}
    Features    : Word;                  {47: Features information}
    DwordIO     : Word;                  {48: *RESERVED* 0001H=Can perform doubleword I/O}
    Capabil     : Word;                  {49: Capabilities}
    Capabil2    : Word;                  {50: Capabilities}
    PIO         : Word;                  {51: PIO data transfer information}
    DMA         : Word;                  {52: *RETIRED* DMA data transfer information}
    ExtValid    : Word;                  {53: Extended data validation information}
    CurrCyls    : Word;                  {54: Number of current logical cylinders}
    CurrHeads   : Word;                  {55: Number of current logical heads}
    CurrSect    : Word;                  {56: Number of current logical sectors per track}
    Capacity    : LongInt;               {57-58: Current capacity in sectors}
    BlockMode   : Word;                  {59: Multiple sectors transfer information}
    LBACapacity : LongInt;               {60-61: Total number of user addressable sectors. LBA mode only}
    SingleDMA   : Word;                  {62: *RETIRED* Single word DMA transfer information}
    MultiDMA    : Word;                  {63: Multiword DMA transfer information}
    AdvancedPIO : Word;                  {64: Advanced PIO Transfer information}
    MinDMACycle : Word;                  {65: Minimum Multiword DMA Transfer Cycle Time Per Word in nsecs}
    RecDMACycle : Word;                  {66: Manufacturer Recommended Multiword DMA Transfer Cycle Time}
    MinPIOCycle : Word;                  {67: Minimum PIO Transfer Cycle Time Without Flow Control in nsecs}
    MinIORDYPIOCycle : Word;             {68: Minimum PIO Transfer Cycle Time With IORDY Flow Control in nsecs}
    ReservedOQ  : Array [0..1] of Word;  {69-70: Reserved for overlap & queuing}
    ReservedIPD : Array [0..3] of Word;  {71-74: Reserved for IDENTIFY PACKET DEVICE}
    QueueDepth  : Word;                  {75: Queue depth}
    Reserved    : Array [0..3] of Word;  {76-79: Reserved}
    MajorVer    : Word;                  {80: Major version of supported standard}
    MinorVer    : Word;                  {81: Minor version of supported standard}
    CommandSupp  : Word;                 {82: Command set supported. If words 82 and 83 = 0000 or ffffh -> field not supported}
    CommandSupp2 : Word;                 {83: Command set supported}
    CommandSupp3 : Word;                 {84: Command set supported. If 82,83 and 84 = 0000 or ffffh -> field not supported}
    CommandEn    : Word;                 {85: Command set/feature enabled. If 85,86 and 87 = 0000 or ffffh -> not supported}
    CommandEn2   : Word;                 {86: Command set/feature enabled. If 85,86 and 87 = 0000 or ffffh -> not supported}
    CommandDef   : Word;                 {87: Command set/feature default. If 85,86 and 87 = 0000 or ffffh -> not supported}
    UltraDMA     : Word;                 {88: UltraDMA modes supported/selected}
    EraseTime    : Word;                 {89: Time required for security erase unit completion}
    EnhEraseTime : Word;                 {90: Time required for Enhanced security erase unit completion}
    APMValue     : Word;                 {91: Current advanced power management value}
    MasterPass   : Word;                 {92: Master password revision code}
    ResetResult  : Word;                 {93: Hardware reset result}
    Reserved2    : Array [94..126] of Word;  {94-126: Reserved}
    Removable    : Word;                 {127: Removable media status notification set support}
    Security     : Word;                 {128: Security status}
    Vendor2      : Array [129..159] of Word; {129-159: Vendor specific}
    Reserved3    : Array [160..254] of Word; {160-254: Reserved}
    Integrity    : Word;                 {255: Entegrity word - checksum & signature}
  end;

  Sector = Array [0..511] of Byte;
  PByte  = ^Byte;

  PIDEDrive = ^TIDEDrive;
  TIDEDrive = Object
    BasePort        : Word;
    DiskNo          : Byte;
    UnitNo          : Byte;
    DiskMode        : Word;
    IDEInfo         : tIDEInfo;
    Features        : Word;

    InternalConfiguration : Pointer;

    constructor Init(Port : Word; DrvNo : byte; Mode : byte);
    function    GetModel : String; virtual;
    function    GetType : String; virtual;

    function    GetIDEInfo : Boolean; virtual;
    function    GetIDEDefaultSize : LongInt; virtual;
    function    GetIDECurrentSize : LongInt; virtual;

    procedure   DetectFeatures; virtual;
    function    IsLBA : Boolean; virtual;
    function    IsDMA : Boolean; virtual;
    function    IsBlockMode : Boolean; virtual;
    function    IsPowerManagement : Boolean; virtual;

    function    SetFeatures(Feature, Value: Byte) : Byte; virtual;
    function    SetReadAhead(State : Boolean) : Boolean; virtual;
    function    SetWriteCache(State : Boolean) : Boolean; virtual;
    function    SetRetries(State : Boolean) : Boolean; virtual;
    function    SetECC(State : Boolean) : Boolean; virtual;
    function    SetDefectsReassignment(State : Boolean) : Boolean;
    function    SetTransferMode(Mode : Byte) : Boolean; virtual;
    function    SetMultipleMode(BlockSize : Byte) : Byte; virtual;

    function    GetPowerMode : Integer; virtual;

    function    GetBufferSize : Word; virtual;

    function    InSector(var Data): Boolean; virtual;
    function    OutSector(var Data): Boolean; virtual;
    function    ReadInternalConfiguration(var Data): Boolean; virtual;
    function    SetInternalConfiguration(var Data; Save : Boolean): Boolean;
 end;

  implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TIDEDrive.Init;
begin
  BasePort := Port; {170h/1F0h}
  DiskNo := DrvNo;  {Master/Slave}
  UnitNo := $A0 + (DiskNo SHL 4);
  GetIDEInfo;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetIDEInfo;
var
  Ticks     : LongInt;
  InfoArray : Array [0..255] of Word absolute IDEInfo;
  i         : Word;
  F         : File;
begin
  GetIDEInfo := False;
  FillChar(InfoArray, SizeOf(InfoArray), 0);

  {Port[$3F6] := 2;}                     {Disable interrupt in control reg.}
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);

  Ticks := BIOSTimer;
  While (Port[BasePort+7] and $80 <> 0)and(BIOSTimer - Ticks <= 3) do ;
  If Port[BasePort+7] and $80 <> 0 Then Exit;

  Port[BasePort+6] := $A0 + (DiskNo SHL 4);
  Port[BasePort+7] := $EC; {Identify drive command}

  Ticks := BIOSTimer;
  While(Port[BasePort+7] <> $58) and (BIOSTimer - Ticks <= 3) do ;
  If Port[BasePort+7] <> $58 Then Exit;

  For I := 0 to 255 do InfoArray[I] := PortW[BasePort];

  for i := 9 to 19 do InfoArray[I] := Swap(InfoArray[I]);  {Correct Serial}
  for i := 23 to 46 do InfoArray[I] := Swap(InfoArray[I]); {Model & Frirmware}
  GetIDEInfo := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetType : String;

  function GetPortNumber(PortAddr : Word) : Byte;
  begin
    Case PortAddr of
      $1F0 : GetPortNumber := 0;
      $170 : GetPortNumber := 1;
      $1E8 : GetPortNumber := 2;
      $168 : GetPortNumber := 3;
    end;
  end;

begin
  If BasePort = 0 Then GetType := 'Non-IDE Drive'
                  Else GetType := 'IDE '+Channel[GetPortNumber(BasePort)]+'/'+Disk[DiskNo];
end;

function TIDEDrive.GetModel : String;
begin
  If IDEInfo.Model <> '' Then GetModel := RTrim(IDEInfo.Model)
                         Else GetModel := 'Unknown';
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TIDEDrive.DetectFeatures;
begin
   Features := 0;
   If (IDEInfo.Capabil and $0100) <> 0 Then Features := Features or feDMA;
   If (IDEInfo.Capabil and $0200) <> 0 Then Features := Features or feLBA;
   If (IDEInfo.BlockMode and $0100) <> 0 Then Features := Features or feBlockMode;
   If GetPowerMode <> -1 Then Features := Features or fePowerManagement;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.IsLBA : Boolean;
begin
  IsLBA := (Features and feLBA) <> 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.IsDMA : Boolean;
begin
  IsDMA := (Features and feDMA) <> 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.IsBlockMode : Boolean;
begin
  IsBlockMode := (Features and feBlockMode) <> 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.IsPowerManagement : Boolean;
begin
  IsPowerManagement := (Features and fePowerManagement) <> 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetIDEDefaultSize : LongInt;
{Size in MBytes}
begin
  GetIDEDefaultSize := LongInt(IDEInfo.Heads)*LongInt(IDEInfo.SPT)*LongInt(IDEInfo.Cyls) div 2048;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetIDECurrentSize : LongInt;
{Size in MBytes}
begin
  GetIDECurrentSize := LongInt(IDEInfo.CurrHeads)*LongInt(IDEInfo.CurrSect)*LongInt(IDEInfo.CurrCyls) div 2048;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.SetFeatures(Feature, Value: Byte) : Byte; assembler;
{
9.22 Set features

This command is used by the host to establish the following parameters which
affect the execution of certain drive features as shown in table 12.

            Table 12 - Set feature register definitions
+=====-=============================================================+
| 01h | Enable 8-bit data transfers (see 6.3.5)                     |
| 02h | Enable write cache *                                        |
| 03h | Set transfer mode based on value in sector count register   |
| 33h | Disable retry *                                             |
| 44h | Vendor unique length of ECC on read long/write long commands|
| 54h | Set cache segments to sector count register value *         |
| 55h | Disable read look-ahead feature                             |
| 66h | Disable reverting to power on defaults (see 9.22)           |
| 77h | Disable ECC *                                               |
| 81h | Disable 8-bit data transfers (see 6.3.5)                    |
| 82h | Disable write cache *                                       |
| 88h | Enable ECC *                                                |
| 99h | Enable retries *                                            |
| AAh | Enable read look-ahead feature                              |
| ABh | Set maximum prefetch using sector count register value *    |
| BBh | 4 bytes of ECC apply on read long/write long commands       |
| CCh | Enable reverting to power on defaults (see 9.22)            |
|-----+-------------------------------------------------------------|
|     |  *These commands are vendor-specified                       |
+===================================================================+


See 10.3 for protocol.  If the value in the register is not supported or is
invalid, the drive posts an Aborted Command error.

At power on, or after a hardware reset, the default mode is the same as that
represented by values greater than 80h.  A setting of 66h allows settings of
greater than 80h which may have been modified since power on to remain at the
same setting after a software reset.

A host can choose the transfer mechanism by Set Transfer Mode and specifying
a value in the Sector Count Register.  The upper 5 bits define the type of
transfer and the low order 3 bits encode the mode value.

    Block transfer (default)           00000  000
    Single word DMA mode x             00010  0xx
    Multiword DMA mode 0               00100  000

See vendor specification for the default mode of the commands which are
vendor-specified.
|  1  | Set features                     | O |  EFh  |  y |    |    |    |  D |
}
asm
  les   di,Self
  mov   dx,es:[di].BasePort
  add   dx,6            {1x6}
  mov   al,es:[di].DiskNo
  shl   al,4
  or    al,0A0h
  out   dx,al
  sub   dx,5            {1x1}
  mov   al,Feature
  out   dx,al
  mov   al,Value
  inc   dx              {1x2}
  out   dx,al
  add   dx,5            {1x7}
  mov   al,0EFh
  out   dx,al
  mov   cx,0F000h
@1:
  in    al,dx
  test  al,80h
  jz    @2
  loop  @1
@2:
  sub   dx,6            {1x1}
  in    al,dx
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.SetReadAhead(State : Boolean) : Boolean;
begin
  If State = ON
   Then SetReadAhead := SetFeatures($AA,0) = 0
   Else SetReadAhead := SetFeatures($55,0) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetWriteCache(State : Boolean) : Boolean;
begin
  If State = ON
   Then SetWriteCache := SetFeatures($02,0) = 0
   Else SetWriteCache := SetFeatures($82,0) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetRetries(State : Boolean) : Boolean;
begin
  If State = ON
   Then SetRetries := SetFeatures($99,0) = 0
   Else SetRetries := SetFeatures($33,0) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetECC(State : Boolean) : Boolean;
begin
  If State = ON
   Then SetECC := SetFeatures($88,0) = 0
   Else SetECC := SetFeatures($77,0) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetDefectsReassignment(State : Boolean) : Boolean;
begin
  If State = ON
   Then SetDefectsReassignment := SetFeatures($04,0) = 0
   Else SetDefectsReassignment := SetFeatures($84,0) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetTransferMode(Mode : Byte) : Boolean;
begin
  SetTransferMode := SetFeatures($03,Mode) = 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.SetMultipleMode(BlockSize : Byte) : Byte; assembler;
asm
  les   di,Self
  mov   dx,es:[di].BasePort    {1x0}
  add   dx,6                   {1x6}
  mov   al,es:[di].DiskNo
  shl   al,4
  or    al,0A0h
  out   dx,al

  sub   dx,4                   {1x2}
  mov   al,BlockSize
  out   dx,al

  add   dx,5                   {1x7}
  mov   al,0C6h
  out   dx,al
  mov   cx,1000
@1:
  in    al,dx
  test  al,80h
  jz    @2
  loop  @1
@2:
  sub   dx,6                   {1x1}
  in    al,dx
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.GetPowerMode : Integer; assembler;
asm
  les   di,Self
  mov   dx,es:[di].BasePort
  add   dx,6            {1x6}
  mov   al,es:[di].DiskNo
  shl   al,4
  or    al,0A0h
  out   dx,al

  inc   dx             {1x7}
  mov   al,098h        {or E5}
  out   dx,al

  mov   cx,0F000h
@1:
  in    al,dx
  test  al,80h
  jz    @2
  loop  @1
@2:
  sub   dx,6            {1x1}
  in    al,dx
  test  al,4
  jnz   @NotSupported

  inc   dx              {1x2}
  in    al,dx
  xor   ah,ah
  cmp   al,00h
  je    @Exit
  cmp   al,80h
  je    @Exit
  cmp   al,0FFh
  je    @Exit

@NotSupported:
  mov   ax,-1

@Exit:
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetBufferSize : Word;
{Buffer size in KB}
begin
  GetBufferSize := IDEInfo.BufSize shr 1;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function   TIDEDrive.InSector(var Data): Boolean;
var
  Start : LongInt;
  i     : Word;
  D     : Array [0..255] of Word absolute Data;
begin
  InSector := False;

  Start := BIOSTimer;
  While Port[BasePort+7] and (hdcBSY or hdcDRQ) <> hdcDRQ do
    if BIOSTimer-Start > IODelay Then Exit;

  for i := 0 to 255 do D[i] := PortW[BasePort];

  InSector := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.OutSector(var Data): Boolean;
var
  Start: LongInt;
  i     : Word;
  D     : Array [0..255] of Word absolute Data;
begin
  OutSector := False;

  If (Port[BasePort+7] and hdcERR) <> 0 Then Exit;

  Start := BIOSTimer;
  While (Port[BasePort+7] and hdcBSY) <> 0 do
    if BIOSTimer-Start > IODelay Then Exit;

  for i := 0 to 255 do PortW[BasePort] := D[i];

  If (Port[BasePort+7] and hdcERR) <> 0 Then Exit;

  OutSector := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.ReadInternalConfiguration(var Data): Boolean;
var
  Start: LongInt;
begin
  ReadInternalConfiguration := False;

  Start := BIOSTimer;
  while Port[BasePort+7] and hdcBSY <> 0 do
    if BIOSTimer-Start > IODelay then Exit;

  {Port[$3F6] := nIEN;}
  Start := BIOSTimer;
  while Port[BasePort+7] and hdcDRDY = 0 do
    if BIOSTimer-Start > IODelay then Exit;

  Port[BasePort+2] := $01;     {Read configuration subcode}
  Port[BasePort+3] := $FF;     {Access password}
  Port[BasePort+4] := $FF;
  Port[BasePort+5] := $3F;
  Port[BasePort+6] := UnitNo;
  Port[BasePort+7] := $F0;     {Command code}

  ReadInternalConfiguration := InSector(Sector(Data))
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.SetInternalConfiguration(var Data; Save : Boolean): Boolean;
var
  Start: LongInt;
begin
  SetInternalConfiguration := False;

  Start := BIOSTimer;
  while Port[BasePort+7] and hdcBSY <> 0 do
    if BIOSTimer-Start > IODelay then Exit;

  {Port[$3F6] := nIEN;}
  Start := BIOSTimer;
  while Port[BasePort+7] and hdcDRDY = 0 do
    if BIOSTimer-Start > IODelay then Exit;

  {Set/Save configuration subcode. Set = FEh, Set & save to disk = FFh}
  If Save
    Then Port[BasePort+2] := $FF
    Else Port[BasePort+2] := $FE;

  Port[BasePort+3] := $FF;     {Access password}
  Port[BasePort+4] := $FF;
  Port[BasePort+5] := $3F;
  Port[BasePort+6] := UnitNo;
  Port[BasePort+7] := $F0;     {Command code}

  SetInternalConfiguration := OutSector(Data)
end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
END.