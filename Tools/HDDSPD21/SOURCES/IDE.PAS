{$X+,G+,D-,L-,S-,R-}
{*$DEFINE DEBUG}
unit IDE;

interface

uses Service, Drive, Tests, XMS, Timer, Defect, Quantum;

const
   ON  = True;
   OFF = False;

   Enabled  = True;
   Disabled = False;

   mLBA    = 0;
   mCHS    = 1;

   Channel   : Array [0..3] of String[15] = ('Primary','Secondary','Tertiary','Quaternary');
   ChannelN  : Array [0..3] of Word = ($1F0, $170, $1E8, $168);
   Disk      : Array [0..1] of String[15] = ('Master','Slave');
   DriveMode : Array [0..1] of String[6] = ('LBA','CHS');

   hdcDataReg         = 0;
   hdcErrorReg        = 1;
   hdcFeaturesReg     = 1;
   hdcSectorsCountReg = 2;


   BufTypeStr : Array [0..3] of String[51] =
   (
    'Not specified',
    'Single ported single sector buffer',
    'Dual ported multi-sector buffer',
    'Dual ported multi-sector buffer with a read caching'
   );

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

  TSMARTThresholdRec = Record
    AttributeID        : Byte;
    AttributeThreshold : Byte;
    Reserved           : Array [1..10] of Byte;
  end;

  TSMARTThresholds = Record
    Revision       : Word;
    Thresholds     : Array [1..30] of TSMARTThresholdRec;
    Reserved       : Array [1..18] of Byte;
    VendorSpecific : Array [1..131] of Byte;
    CheckSum       : Byte;
  end;

  TSMARTValueRec = Record
    AttributeID       : Byte;
    StatusFlags       : Word;
    AttributeValue    : Byte;
    WorstValue        : Byte;
    Raw               : Array [1..6] of Byte;
    Reserved          : Byte;
  end;

  TSMARTValues = Record
    Revision       : Word;
    Values         : Array [1..30] of TSMARTValueRec;
    Reserved       : Array [1..6] of Byte;
    Capability     : Word;
    Reserved2      : Array [1..16] of Byte;
    VendorSpecific : Array [1..125] of Byte;
    CheckSum       : Byte;
  end;

  PSMARTMonitorRec = ^TSMARTMonitorRec;
  TSMARTMonitorRec = Record
    Model          : Array [1..40] of Char;
    SerialNumber   : Array [1..20] of Char;
    StartDate      : LongInt;
    StartValues    : TSMARTValues;
  end;

  Sector = Array [0..511] of Byte;
  PByte  = ^Byte;

  PIDEDrive = ^TIDEDrive;
  TIDEDrive = Object(TTestDrive)
    BasePort        : Word;
    DiskNo          : Byte;
    UnitNo          : Byte;
    DiskMode        : Word;
    IDEInfo         : TIDEInfo;
    SMARTThresholds : TSMARTThresholds;
    SMARTValues     : TSMARTValues;
    Features        : Word;
    SMARTMonitorRec : TSMARTMonitorRec;

    DefectList      : PDefectList;
    InternalConfiguration : Pointer;

    constructor Init(DrvNum : Integer; Port : Word; Disk : Byte);
    function    GetModel : String; virtual;
    function    GetType : String; virtual;

    function    RecoverTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte; virtual;

    procedure   GetDrivePort; virtual;
    function    GetIDEInfo : Boolean; virtual;
    function    GetMaxPIO : Integer; virtual;
    function    GetMaxDMA : Integer; virtual;
    function    GetMaxUltraDMA : Integer; virtual;
    function    GetMaxModes : String; virtual;
    function    GetStandardCompatibility : String;
    function    GetIDEDefaultSize : LongInt; virtual;
    function    GetIDECurrentSize : LongInt; virtual;

    procedure   DetectFeatures; virtual;
    function    IsLBA : Boolean; virtual;
    function    IsDMA : Boolean; virtual;
    function    IsBlockMode : Boolean; virtual;
    function    IsPowerManagement : Boolean; virtual;
    function    IsSMART : Boolean; virtual;

    function    SetFeatures(Feature, Value: Byte) : Byte; virtual;
    function    SetReadAhead(State : Boolean) : Boolean; virtual;
    function    SetWriteCache(State : Boolean) : Boolean; virtual;
    function    SetRetries(State : Boolean) : Boolean; virtual;
    function    SetECC(State : Boolean) : Boolean; virtual;
    function    SetDefectsReassignment(State : Boolean) : Boolean;
    function    SetTransferMode(Mode : Byte) : Boolean; virtual;
    function    SetMultipleMode(BlockSize : Byte) : Byte; virtual;

    function    GetPowerMode : Integer; virtual;

    function    SetSMART(State : Boolean) : Boolean; virtual;
    function    SetSMARTAutosave(State : Boolean) : Boolean; virtual;
    function    GetSMARTStatus : Integer; virtual;
    function    GetSMARTThresholds : Boolean; virtual;
    function    GetSMARTValues : Boolean; virtual;
    function    GetSMARTInfo : Boolean; virtual;
    function    GetSMARTAttrMeaning(N : Byte) : String; virtual;
    procedure   UpdateSMARTBase; virtual;

    function    GetRPM_Index : Word; virtual;
    function    GetRPM_Read : Word; virtual;
    function    GetRPM(Method : Byte) : Word; virtual;

    function    GetBufferSize : Word; virtual;

    function    InSector(var Data): Boolean; virtual;
    function    OutSector(var Data): Boolean; virtual;
    function    ReadInternalConfiguration(var Data): Boolean; virtual;
    function    SetInternalConfiguration(var Data; Save : Boolean): Boolean;
    function    ReadDefectList : Byte; virtual;
 end;

  TSMARTAttrRec = Record
    ID          : Byte;
    Meaning     : String[25];
  end;

const

   SMARTAttrCount = 14;
   FujitsuSMARTAttr : Array [1..SMARTAttrCount] of TSMARTAttrRec =
   (
    (ID:   1; Meaning: 'Raw Read Error Rate'),
    (ID:   2; Meaning: 'Throughput Performance'),
    (ID:   3; Meaning: 'Spin Up Time'),
    (ID:   4; Meaning: 'Start/Stop Count'),
    (ID:   5; Meaning: 'Reallocated Sector Count'),
    (ID:   7; Meaning: 'Seek Error Rate'),
    (ID:   8; Meaning: 'Seek Time Performance'),
    (ID:   9; Meaning: 'Power On Hours Count'),
    (ID:  10; Meaning: 'Spin Retry Count'),
    (ID:  11; Meaning: 'Recalibration Retries'),
    (ID:  12; Meaning: 'Drive Power Cycle Count'),
    (ID:  13; Meaning: 'Soft Read Error Rate'),
    (ID: 199; Meaning: 'Ultra ATA CRC Error Rate'),
    (ID: 200; Meaning: 'Write Error Rate')
   );

function GetIDEorATAPIInfo(BasePort : Word; DiskNo : Byte; var IDEInfo : TIDEInfo; CheckATAPI : Boolean) : Boolean;

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
{$IFDEF DEBUG}
function GetIDEorATAPIInfo(BasePort : Word; DiskNo : Byte; var IDEInfo : TIDEInfo; CheckATAPI : Boolean) : Boolean;
var
  F         : File;
  InfoArray : Array [0..255] of Word absolute IDEInfo;
  i         : Word;
begin
  Assign(F,'ideinfo.dat'); Reset(F,1);
  BlockRead(F,InfoArray, SizeOf(InfoArray));
  System.Close(F);

  for i := 9 to 19 do InfoArray[I] := Swap(InfoArray[I]);  {Correct Serial}
  for i := 23 to 46 do InfoArray[I] := Swap(InfoArray[I]); {Model & Frirmware}

  GetIDEorATAPIInfo := True;
end;
{$ELSE}
function GetIDEorATAPIInfo(BasePort : Word; DiskNo : Byte; var IDEInfo : TIDEInfo; CheckATAPI : Boolean) : Boolean;
var
  Ticks     : LongInt;
  InfoArray : Array [0..255] of Word absolute IDEInfo;
  i         : Word;
  F         : File;
begin
  GetIDEorATAPIInfo := False;
  FillChar(InfoArray, SizeOf(InfoArray), 0);

  {Port[$3F6] := 2;}                     {Disable interrupt in control reg.}
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);

  Ticks := BIOSTimer;
  While (Port[BasePort+7] and $80 <> 0)and(BIOSTimer - Ticks <= 3) do ;
  If Port[BasePort+7] and $80 <> 0 Then Exit;

  Port[BasePort+6] := $A0 + (DiskNo SHL 4);
  If CheckATAPI Then Port[BasePort+7] := $A1  {ATAPI inqury command}
                Else Port[BasePort+7] := $EC; {Identify drive command}

  Ticks := BIOSTimer;
  While(Port[BasePort+7] <> $58) and (BIOSTimer - Ticks <= 3) do ;
  If Port[BasePort+7] <> $58 Then Exit;

  For I := 0 to 255 do InfoArray[I] := PortW[BasePort];

  {$IFDEF DEBUG2}
  Assign(F,'ideinfo.dat'); Rewrite(F,1);
  BlockWrite(F,InfoArray, SizeOf(InfoArray));
  System.Close(F);
  {$ENDIF}

  for i := 9 to 19 do InfoArray[I] := Swap(InfoArray[I]);  {Correct Serial}
  for i := 23 to 46 do InfoArray[I] := Swap(InfoArray[I]); {Model & Frirmware}
  GetIDEorATAPIInfo := True;
end;
{$ENDIF}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TIDEDrive.Init(DrvNum : Integer; Port : Word; Disk : Byte);
begin
  inherited Init(DrvNum);
  If (Status <> 0) and (Status <> -3) Then Exit;
  BasePort := Port; DiskNo := Disk;
  If Port = 0 Then GetDrivePort;
  UnitNo := $A0 + (DiskNo SHL 4);
  GetIDEInfo;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TIDEDrive.GetDrivePort;
var
  NumDisks : Integer;
  I, B     : Byte;
  Where    : Word;
  Drv      : Byte;
begin
  Drv := BIOSDriveNumber;
  NumDisks := GetDrivesNumber;
  for I := 0 to NumDisks-1 do
  begin
    BIOSDriveNumber := I+$80;
    ReadSectors(0,0,1,1,TestBuffer);
  end;

  BasePort := 0; DiskNo := 0;
  BIOSDriveNumber := Drv;
  ReadSectors(0,0,1,10, TestBuffer);

  {Primary/Master}
  Port[$1f6] := $A0;
  B := Port[$1f7];
  If (B and 64 <> 0)and(B and 128 = 0) Then
  begin
    Where := PortW[$1f3];
    If Where in [9..10] Then
    begin
      BasePort := $1F0; DiskNo := 0;
      DiskMode := Word(Where = 10);           {0 - LBA, 1 - CHS aka Normal}
      Exit;
    end;
  end;

  {Primary/Slave}
  Port[$1f6] := $B0;
  B := Port[$1f7];
  If (B and 64 <> 0)and(B and 128 = 0) Then
  begin
    Where := PortW[$1f3];
    If Where in [9..10] Then
    begin
      BasePort := $1F0; DiskNo := 1;
      DiskMode := Word(Where = 10);           {0 - LBA, 1 - CHS aka Normal}
      Exit;
    end;
  end;

  {Secondary/Master}
  Port[$176] := $A0;
  B := Port[$177];
  If (B and 64 <> 0)and(B and 128 = 0) Then
  begin
    Where := PortW[$173];
    If Where in [9..10] Then
    begin
      BasePort := $170; DiskNo := 0;
      DiskMode := Word(Where = 10);           {0 - LBA, 1 - CHS aka Normal}
      Exit;
    end;
  end;

  {Secondary/Slave}
  Port[$176] := $B0;
  B := Port[$177];
  If (B and 64 <> 0)and(B and 128 = 0) Then
  begin
    Where := PortW[$173];
    If Where in [9..10] Then
    begin
      BasePort := $170; DiskNo := 1;
      DiskMode := Word(Where = 10);           {0 - LBA, 1 - CHS aka Normal}
      Exit;
    end;
  end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  TIDEDrive.RecoverTrack(Track : Word; Head : Byte; var TrackMap : TTrackMap) : Byte;
begin
  SetDefectsReassignment(Enabled);
  RecoverTrack := inherited RecoverTrack(Track, Head, TrackMap);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetIDEInfo : Boolean;
begin
  GetIDEInfo := GetIDEorATAPIInfo(BasePort, DiskNo, IDEInfo, False);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetMaxPIO : Integer;
var PIO : Byte;
begin
  PIO := HighestBit(Hi(IDEInfo.PIO))+1;
  If (IDEInfo.ExtValid and 2) <> 0 Then
    PIO := HighestBit(Lo(IDEInfo.AdvancedPIO))+3;
  GetMaxPIO := PIO;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetMaxDMA : Integer;
var
  DMA : Byte;
begin
  GetMaxDMA := -1;
  If (IDEInfo.Capabil and $0100) = 0 Then Exit;
  DMA := HighestBit(Hi(IDEInfo.DMA));
  If (IDEInfo.ExtValid and 2) <> 0 Then
    DMA := HighestBit(Lo(IDEInfo.MultiDMA));
  GetMaxDMA := DMA;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetMaxUltraDMA : Integer;
var
  UDMA : Integer;
begin
  UDMA := -1;
  If (IDEInfo.ExtValid and 4) <> 0 Then
    UDMA := HighestBit(Lo(IDEInfo.UltraDMA));
  GetMaxUltraDMA := UDMA;

{$IFDEF ALTUDMA}
  GetMaxUltraDMA := ' - Not Supported';
  If SetTransferMode($FF) Then Exit;
  If SetTransferMode(UltraDMA2)
    Then GetMaxUltraDMA := '2'
    Else  If SetTransferMode(UltraDMA1)
            Then GetMaxUltraDMA := '1'
            Else If SetTransferMode(UltraDMA0) Then GetMaxUltraDMA := '0';
{$ENDIF}
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetMaxModes : String;
var
  S : String[80];
  DMA, UDMA : Integer;
begin
  S := 'PIO'+IntToStr(GetMaxPIO);
  DMA := GetMaxDMA;
  If DMA >= 0 Then S := S+', DMA'+IntToStr(DMA);
  UDMA := GetMaxUltraDMA;
  If UDMA >= 0 Then
   If UDMA <= 2
     Then S := S+', UltraDMA/33 (UDMA'+IntToStr(UDMA)+')'
     Else S := S+', UltraDMA/66 (UDMA'+IntToStr(UDMA)+')';
  GetMaxModes := S;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetStandardCompatibility : String;
var
  Version : Integer;
begin
  Version := -1;
  If (IDEInfo.MajorVer <> 0) and (IDEInfo.MajorVer <> $FFFF) Then
    Version := HighestBit(Lo(IDEInfo.MajorVer));
  Case Version of
    2..3 : GetStandardCompatibility := 'ATA-'+IntToStr(Version);
    4..14 : GetStandardCompatibility := 'ATA/ATAPI-'+IntToStr(Version);
  else
     GetStandardCompatibility := 'Unknown';
  end;
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
  If IDEInfo.Model <> '' Then GetModel := Trim(IDEInfo.Model)
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
   If GetSMARTStatus <> -1 Then Features := Features or feSMART;
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
function TIDEDrive.IsSMART : Boolean;
begin
  IsSMART := (Features and feSMART) <> 0;
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
function    TIDEDrive.SetSMART(State : Boolean) : Boolean;
const
  IODelay = 5;
var
  Timer: LongInt absolute $40:$6C;
  Start: LongInt;
begin
  SetSMART := False;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  Start := Timer;
  while Port[BasePort+7] and $40 = 0 do
    if Timer-Start > IODelay then Exit;

  If State = Enabled
   Then Port[BasePort+1] := $D8
   Else Port[BasePort+1] := $D9;
  Port[BasePort+4] := $4F;
  Port[BasePort+5] := $C2;
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);;
  Port[BasePort+7] := $B0;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  If Port[BasePort+7] and $01 <> 0 Then Exit;
  SetSMART := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.SetSMARTAutosave(State : Boolean) : Boolean;
const
  IODelay = 5;
var
  Timer: LongInt absolute $40:$6C;
  Start: LongInt;
begin
  SetSMARTAutosave := False;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  Start := Timer;
  while Port[BasePort+7] and $40 = 0 do
    if Timer-Start > IODelay then Exit;

  Port[BasePort+1] := $D2;
  If State = Enabled
    Then Port[BasePort+2] := $F1
    Else Port[BasePort+2] := $00;
  Port[BasePort+4] := $4F;
  Port[BasePort+5] := $C2;
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);;
  Port[BasePort+7] := $B0;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  If Port[BasePort+7] and $01 <> 0 Then Exit;
  SetSMARTAutosave := True;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.GetSMARTStatus : Integer;
const
  IODelay = 5;
var
  CL, CH: Byte;
  Timer: LongInt absolute $40:$6C;
  Start: LongInt;
begin
  GetSMARTStatus := -1;
  If Not SetSMART(Enabled) Then Exit;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  Start := Timer;
  while Port[BasePort+7] and $40 = 0 do
    if Timer-Start > IODelay then Exit;

  Port[BasePort+1] := $DA;
  Port[BasePort+4] := $4F;
  Port[BasePort+5] := $C2;
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);;
  Port[BasePort+7] := $B0;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  If Port[BasePort+7] and $01 <> 0 Then Exit;

  CL := Port[BasePort+4];
  CH := Port[BasePort+5];

  If (CL = $4F) and (CH = $C2)
   Then GetSMARTStatus := 0
   Else If (CL = $F4) and (CH = $2C) Then GetSMARTStatus := 1;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
{$IFDEF DEBUG}
function    TIDEDrive.GetSMARTThresholds : Boolean;
var
  F : File;
begin
  Assign(F,'thresh.dat'); Reset(F,1);
  BlockRead(F,SMARTThresholds, SizeOf(SMARTThresholds));
  System.Close(F);
  GetSMARTThresholds := True;
end;
{$ELSE}
function    TIDEDrive.GetSMARTThresholds : Boolean;
const
  IODelay = 5;
var
  Timer: LongInt absolute $40:$6C;
  Start, I : LongInt;
  SMARTArray : Array [0..255] of Word absolute SMARTThresholds;
begin
  GetSMARTThresholds := False;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  Start := Timer;
  while Port[BasePort+7] and $40 = 0 do
    if Timer-Start > IODelay then Exit;

  Port[BasePort+1] := $D1;
  Port[BasePort+4] := $4F;
  Port[BasePort+5] := $C2;
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);;
  Port[BasePort+7] := $B0;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  If Port[BasePort+7] and $01 <> 0 Then Exit;

  for I := 0 to 255 do SMARTArray[I] := PortW[BasePort];

  GetSMARTThresholds := True;
end;
{$ENDIF}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
{$IFDEF DEBUG}
function    TIDEDrive.GetSMARTValues : Boolean;
var
  F : File;
begin
  Assign(F,'values.dat'); Reset(F,1);
  BlockRead(F,SMARTValues, SizeOf(SMARTValues));
  System.Close(F);
  GetSMARTValues := True;
end;
{$ELSE}
function    TIDEDrive.GetSMARTValues : Boolean;
const
  IODelay = 5;
var
  Timer: LongInt absolute $40:$6C;
  Start, I : LongInt;
  SMARTArray : Array [0..255] of Word absolute SMARTValues;
begin
  GetSMARTvalues := False;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  Start := Timer;
  while Port[BasePort+7] and $40 = 0 do
    if Timer-Start > IODelay then Exit;

  Port[BasePort+1] := $D0;
  Port[BasePort+4] := $4F;
  Port[BasePort+5] := $C2;
  Port[BasePort+6] := $A0 + (DiskNo SHL 4);;
  Port[BasePort+7] := $B0;

  Start := Timer;
  while Port[BasePort+7] and $80 <> 0 do
    if Timer-Start > IODelay then Exit;

  If Port[BasePort+7] and $01 <> 0 Then Exit;

  for I := 0 to 255 do SMARTArray[I] := PortW[BasePort];

  GetSMARTValues := True;
end;
{$ENDIF}

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.GetSMARTInfo : Boolean;
begin
  SetSMART(Enabled);
  GetSMARTInfo := GetSMARTThresholds and GetSMARTValues;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function    TIDEDrive.GetSMARTAttrMeaning(N : Byte) : String;
var
  i, ID : Byte;
begin
  ID := SMARTThresholds.Thresholds[N].AttributeID;
  GetSMARTAttrMeaning := 'Attribute '+IntToStr(ID);
  for i := 1 to SMARTAttrCount do
   If FujitsuSMARTAttr[i].ID = ID Then GetSMARTAttrMeaning := FujitsuSMARTAttr[i].Meaning
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TIDEDrive.UpdateSMARTBase;
var
  P, FoundPos     : LongInt;
  Found           : Boolean;
  F               : File;
  NumRead         : Word;
begin
  Found := False;
  {$I-}
  Assign(F,'smart.dat'); Reset(F,1);
  {$I+}
  IF IOResult <> 0
  Then Rewrite(F,1)
  Else begin
    While (not EOF(F)) and (not Found) do
    begin
      P := FilePos(F);
      BlockRead(F, SMARTMonitorRec, SizeOf(SMARTMonitorRec), NumRead);
      If NumRead = SizeOf(SMARTMonitorRec) Then
        With SMARTMonitorRec do
          If (Model = IDEInfo.Model) and (SerialNumber = IDEInfo.Serial) Then
          begin
            Found := True;
            FoundPos := P;
          end;
    end;
  end;

  With SMARTMonitorRec do
  begin
    If not Found Then
    begin
      Move(IDEInfo.Model, Model, SizeOf(Model));
      Move(IDEInfo.Serial, SerialNumber, SizeOf(SerialNumber));
      StartDate := GetCurrentPackedDateTime;
      StartValues := SMARTValues;
      BlockWrite(F, SMARTMonitorRec, SizeOf(SMARTMonitorRec));
    end;

  end;
  Close(F);
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

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetRPM_Index : Word;
var
  OldTimer   : LongInt;
  TimerTicks : LongInt;
  RevCount   : LongInt;
begin
  GetRPM_Index := 0;
  SkipTest := False;
  asm
    les  di,Self
    mov  dx,es:[di].BasePort
    add  dx,6
    mov  al,es:[di].DiskNo
    shl  al,4
    or   al,0A0h
    out  dx,al
    inc  dx
    in   al,dx

    mov  cx,0FFFFh
  @1:
    in   al,dx
    test al,2
    jz   @100
    dec  cx
    jnz  @1
  @100:
  end;

  RevCount := 0;
  TimerTicks := 0;
  OldTimer := BIOSTimer;
  Repeat
    StartTimer;
    asm
      les  di,Self
      mov  dx,es:[di].BasePort
      add  dx,7
      mov  cx,0FFFFh
    @1:
      in   al,dx
      test al,2
      jz   @200
      dec  cx
      jnz  @1
      jmp  @1000

    @200:
      mov  cx,0FFFFh
    @2:
      in   al,dx
      test al,2
      jnz  @300
      dec  cx
      jnz  @2
      jmp  @1000

    @300:
      inc  word ptr [RevCount]
    @1000:
    end;
    Inc(TimerTicks,ReadTimer);
  Until (BIOSTimer-OldTimer >= 91) or SkipTest;
  If TimerTicks = 0 Then Exit;
  RPM := Round(60*(1193180*RevCount/TimerTicks));
  GetRPM_Index := RPM;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetRPM_Read : Word;
var
  i : Word;
  TimerTicks, ReadTime : LongInt;
begin
  GetRPM_Read := 0;
  SkipTest := False;
  TimerTicks := 0; ReadTime := 0;

  ReadSectors(Tracks, 0, 1, 1, TestBuffer);
  for i := 1 to 1024 do
  begin
    If SkipTest Then Break;
    WriteSectors(Tracks, 0, 1, 1, TestBuffer);
  end;

  SeekToTrack(0);
  SetReadAhead(OFF);
  for i := 1 to Sectors do
  begin
    If SkipTest Then Break;
    StartTimer;
    ReadSectors(0, 0, i, 1, TestBuffer);
    Inc(TimerTicks,ReadTimer);
  end;
  ReadTime := TimerTicks div 1193;

  SetReadAhead(ON);
  If ReadTime = 0 Then Exit;
  RPM := 60*1000*63 div ReadTime;
  GetRPM_Read := RPM;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function TIDEDrive.GetRPM(Method : Byte) : Word;
begin
  Case Method of
    1 : GetRPM := GetRPM_Index;
    2 : GetRPM := GetRPM_Read;
    3 : GetRPM := GetRPM_Write;
  Else begin   {Autodetect best method}
         RPM := GetRPM_Index;
         If (RPM < 3000) or (RPM > 10000) Then
         begin
           RPM := GetRPM_Read;
           If (RPM < 3000) or (RPM > 10000) Then
           begin
             RPM := GetRPM_Write;
             If (RPM < 3000) or (RPM > 10000) Then RPM := 0;
           end;
         end;
         GetRPM := RPM;
       end;
  end;
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
function TIDEDrive.ReadDefectList : Byte;
var
  DLMaxSectors,
  I, Cnt, Size : Word;
  P            : PByte;
  Data         : Sector;
  Start        : LongInt;
  DLMaxSize,
  DLSize          : Word;
  Defects         : PRawDefectList;

  {컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
  function GetDLLength: Word;
  var
    Start: LongInt;
  begin
    GetDLLength := 0;

    Start := BIOSTimer;
    while Port[BasePort+7] and hdcBSY <> 0 do
      if BIOSTimer-Start > IODelay then Exit;

    {Port[$3F6] := nIEN;}
    Start := BIOSTimer;
    while Port[BasePort+7] and hdcDRDY = 0 do
      if BIOSTimer-Start > IODelay then Exit;

    Port[BasePort+2] := 0;      {Read defect list subcode}
    Port[BasePort+3] := $FF;    {Access password}
    Port[BasePort+4] := $FF;
    Port[BasePort+5] := $3F;
    Port[BasePort+6] := UnitNo;
    Port[BasePort+7] := $F0;    {Command code}

    Start := BIOSTimer;
    while Port[BasePort+7] and hdcBSY <> 0 do
      if BIOSTimer-Start > IODelay then Exit;

    if Port[BasePort+7] and hdcERR <> 0 then
      Exit;

    GetDLLength := (Port[BasePort+3] shl 8) or Ord(Port[BasePort+2]);
  end;

  {컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
  procedure StartReadDL(DLLength: Word);
  var
    Start: LongInt;
  begin
    Start := BIOSTimer;
    while Port[BasePort+7] and hdcBSY <> 0 do
      if BIOSTimer-Start > IODelay then Exit;

    {Port[$3F6] := nIEN;}
    Start := BIOSTimer;
    while Port[BasePort+7] and hdcDRDY = 0 do
      if BIOSTimer-Start > IODelay then Exit;

    Port[BasePort+2] := Lo(DLLength);
    Port[BasePort+3] := Hi(DLLength);
    Port[BasePort+4] := $FF;
    Port[BasePort+5] := $3F;
    Port[BasePort+6] := UnitNo;
    Port[BasePort+7] := $F0;
  end;

begin
  ReadDefectList := 0;

  DLMaxSectors := GetDLLength;
  if DLMaxSectors = 0 Then
  begin
    ReadDefectList := 1;
    Exit; {  Error('Supported Quantum IDE HDD not found');}
  end;

  StartReadDL(DLMaxSectors);
  If not InSector(Data) Then
  begin
    ReadDefectList := 2;
    Exit; {  Error('Timeout error.'); }
  end;

  Move(Data, DLSize, 2);
  if DLSize <> $1D00 Then
  begin
    ReadDefectList := 3;
    Exit; {  Error('Defect List signature not present'); }
  end;

  DLMaxSize := DLMaxSectors*SizeOf(Sector)-4;

  Move(Data[2], DLSize, 2);
  DLSize := Swap(DLSize);

  if DLSize > DLMaxSize Then
  begin
    ReadDefectList := 4;
    Exit; {  Error('Defective Defect List header'); }
  end;

  GetMem(Defects, DLSize);
  if Defects = Nil Then
  begin
    ReadDefectList := 5;
    Exit; {  Error('Out of memory'); }
  end;

  Size := 0;
  I := 4;
  Cnt := SizeOf(Sector)-4;
  P := PByte(Defects);

  Start := BIOSTimer;
  Repeat
    Inc(Size, Cnt);
    if Size > DLSize then
      Dec(Cnt, DLSize-Size);
    Move(Data[I], P^, Cnt);
    Inc(P, Cnt);

    if Size >= DLSize Then Break;

    If not InSector(Data) Then
    begin
      ReadDefectList := 2;
      Exit; {  Error('Timeout error.'); }
    end;

    I := 0;
    Cnt := SizeOf(Sector);
  Until (Size >= DLSize) or (BIOSTimer-Start > 50);

  If DefectList <> Nil Then
  begin
    Dispose(DefectList, Done);
    DefectList := Nil;
  end;
  New(PQuantumDefectList(DefectList), Init(1000, 100));

  With DefectList^ do
  begin
    DefectsCount := DLSize div SizeOf(TRawDefectEntry);
    MaxDefectsCount := DLMaxSize div SizeOf(TRawDefectEntry);

    for I := 0 to DefectList^.DefectsCount-1 do
      AddDefect(Defects^[I]);
  end;
  FreeMem(Defects, DLSize);

  ResetController;
end;

begin
end.
