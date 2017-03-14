{$M 16384, $20000, $20000}
{$X+,G+,D-,L-,S-,R-}
unit Tests;

interface

uses Objects, Crt,  XMS, Service, Timer, Drive, GrowView;

type

  PSpeedRec = ^TSpeedRec;
  TSpeedRec = Record
    ReadSpeed  : Word;
    WriteSpeed : Word;
  end;

  PTestDrive = ^TTestDrive;
  TTestDrive = Object(TDrive)
    TestBuffer : Pointer;
    XMSStream  : PXMSStream;
    GV         : PGrowView;

    EffectiveBufferSize : Word;
    RPM : Word;

    AverageSeekTime,
    MaxSeekTime,
    TrackToTrackSeekTime,
    AverageAccessTime     : Real;

    AverageReadSpeed,
    AverageWriteSpeed,

    MinReadSpeed,
    MinWriteSpeed,

    MaxReadSpeed,
    MaxWriteSpeed,

    MaxCacheSpeed,
    RandomReadSpeed,

    BestBlockSize,

    SpeedIndex,
    FATWeightedIndex,
    HPFS386WeightedIndex   : LongInt;

    constructor Init(DrvNum : Integer);
    destructor  Done; virtual;

    function    GetEffectiveBufferSize : Word; virtual;
    function    GetRPM_Write : Word; virtual;
    function    GetRPM(Method : Byte) : Word; virtual;

    function    GetAverageSeekTime : Real; virtual;
    function    GetMaxSeekTime : Real; virtual;
    function    GetTrackToTrackSeekTime : Real; virtual;
    function    GetAverageAccessTime : Real; virtual;

    function    GetTrackLinearReadSpeed(Track, N: Word; Shuttle : Boolean) : LongInt; virtual;
    function    GetTrackLinearWriteSpeed(Track, N: Word; Shuttle : Boolean) : LongInt; virtual;
    function    GetTrackLinearVerifySpeed(Track, N : Word; Shuttle : Boolean) : LongInt; virtual;
    procedure   GetTrackLinearSpeed(Track, N: Word; var ReadSpeed, WriteSpeed : LongInt;
                                    NeedWrite, ReadShuttle, WriteShuttle : Boolean);

    function    GetAverageLinearReadSpeed(N : Byte; Shuttle : Boolean) : LongInt; virtual;
    procedure   GetAverageLinearSpeed(N : Byte; NeedWrite, ReadShuttle, WriteShuttle : Boolean);

    function    GetMaxCacheSpeed : LongInt; virtual;
    function    GetRandomReadSpeed : Word; virtual;

    function    GetSpeedIndex : Word; virtual;
    function    GetFATWeightedIndex : Word; virtual;
    function    GetHPFS386WeightedIndex : Word; virtual;

    function    GetBufferSize : Word; virtual;

    function    ReadTrack(Track : Word; XMS : PXMSStream) : Boolean;
    function    WriteTrack(Track : Word; XMS : PXMSStream) : Boolean;
    function    CopyTrack(Track : Word; P : PTestDrive) : Boolean;
  end;

procedure WriteResultsTable(var Report : Text; Drv : PTestDrive);

implementation

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TTestDrive.Init(DrvNum : Integer);
begin
  inherited Init(DrvNum);
  If Status <> 0 Then Exit;

  MemAlloc(TestBuffer, 64*1024 div 16); {16 byte paragraphs}
{  GetMem(TestBuffer, 65535);}
  If TestBuffer = Nil Then begin Status := -2; Exit; end;

  New(XMSStream, Init((Heads+2)*Sectors div 2+1, Sectors div 2+1)); {1K blocks}
  If XMSStream^.Status <> 0 Then begin Status := -3; Exit; end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
destructor TTestDrive.Done;
begin
  If TestBuffer <> Nil Then MemFree(TestBuffer); TestBuffer := Nil;
{ If TestBuffer <> Nil Then FreeMem(TestBuffer, 65535);}
  If (XMSStream <> Nil) and (XMSStream^.Handle <> 0) Then XMSStream^.Done;
  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetEffectiveBufferSize : Word;
var
   T1, T2, KS1, KS2  : LongInt;
   B, I, K, OldK : Word;
   MaxTransfer : LongInt;
Begin
   EffectiveBufferSize := 0;
   T2 := MaxLongInt Div 10;
   KS2 := 1; MaxTransfer := 0; K := 0; OldK := 0;
   SkipTest := False;
   Repeat
      If SkipTest Then Break;

      T1 := T2;
      KS1 := KS2;
      If KS1 > MaxTransfer Then MaxTransfer := KS1;
      Inc(EffectiveBufferSize);

      B := EffectiveBufferSize*2;
      If B > 255 Then B := 255;

      VerifySectors(0,0,1,B);
      T2 := 0;
      For I := 1 To 5 Do
      begin
         StartTimer;
         VerifySectors(0,0,1,B);
         T2 := T2+ReadTimer;
      end;
      KS2 := (5*LongInt(EffectiveBufferSize)*119318) div T2;
      If (KS2/KS1 < 0.3) and (EffectiveBufferSize-OldK > 8) Then
      begin
        K := EffectiveBufferSize-1;
        OldK := K;
      end;
   Until B >= 255;

   EffectiveBufferSize := K;
   If EffectiveBufferSize >= 127 Then EffectiveBufferSize := 0;
   GetEffectiveBufferSize := EffectiveBufferSize;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetRPM_Write : Word;
var
  i    : Word;
  TimerTicks, Time : LongInt;
begin
  GetRPM_Write := 0;
  SkipTest := False;
  ReadSectors(Tracks, 0, 1, 1, TestBuffer);
  for i := 1 to 1024 do
  begin
    If SkipTest Then Break;
    WriteSectors(Tracks, 0, 1, 1, TestBuffer);
  end;

  TimerTicks := 0; Time := 0;
  for i := 1 to 100 do
  begin
    If SkipTest Then Break;
    StartTimer;
    WriteSectors(Tracks, 0, 1, 1, TestBuffer);
    Inc(TimerTicks,ReadTimer);
  end;
  Time := TimerTicks div 1193;
  If Time = 0 Then Exit;
  RPM := 60*1000*100 div Time;
  GetRPM_Write := RPM;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetRPM(Method : Byte) : Word;
begin
  GetRPM := GetRPM_Write;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Testing linear read speed in Kb on specified track}
function TTestDrive.GetTrackLinearReadSpeed(Track, N: Word; Shuttle : Boolean) : LongInt;
var
  i, j : Byte;
  Size, TimerTicks, Time, ReadSpeed : LongInt;
begin
  SkipTest := False;
  GetTrackLinearReadSpeed := 0;
  ReadSpeed := 0;
  If TestBuffer = Nil Then Exit;

  Time := 0; Size := 0;
  for i := 1 to N do
  begin
    If SkipTest Then Break;
    If I > 1 Then SeekToTrack(Track);
    If Shuttle and (Track > 0) Then ReadSectors(Track-1, Heads-1, 1, Sectors, TestBuffer);
    TimerTicks := 0;
    for J := 0 to Heads-1 do              {Testing Linear Read Speed}
    begin
      StartTimer;
      ReadSectors(Track, J, 1, Sectors, TestBuffer);
      Inc(TimerTicks, ReadTimer);
      Inc(Size, Sectors*512);
    end;
    If Shuttle and (Track < Tracks-1) Then ReadSectors(Track+1, 0, 1, Sectors, TestBuffer);

    Inc(Time, TimerTicks div 1193);
  end;
  If Time = 0 Then Exit;
  ReadSpeed := Size div Time;
  GetTrackLinearReadSpeed := ReadSpeed;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Testing destructive linear write speed in Kb on specified track}
function TTestDrive.GetTrackLinearWriteSpeed(Track, N : Word; Shuttle : Boolean) : LongInt;
var
  i, j : Byte;
  Size, TimerTicks, Time, WriteSpeed : LongInt;
begin
  SkipTest := False;
  WriteSpeed := 0; GetTrackLinearWriteSpeed := 0;
  FillChar(TestBuffer^,SizeOf(TestBuffer^),#0);

  If (TestBuffer = Nil) or (XMSStream = Nil) or (XMSStream^.Status <> 0) Then Exit;

  XMSStream^.Seek(0);
  Size := 0;

  If Shuttle and (Track > 0) Then
  begin
    ReadSectors(Track-1, Heads-1, 1, Sectors, TestBuffer);
    XMSStream^.Write(TestBuffer^, Sectors*512);
    Inc(Size, Sectors*512);
  end;

  for J := 0 to Heads-1 do
  begin
    If SkipTest Then Break;
    ReadSectors(Track, J, 1, Sectors, TestBuffer);
    XMSStream^.Write(TestBuffer^, Sectors*512);
    Inc(Size, Sectors*512);
  end;

  If Shuttle and (Track < Tracks-1) Then
  begin
    ReadSectors(Track+1, 0, 1, Sectors, TestBuffer);
    XMSStream^.Write(TestBuffer^, Sectors*512);
    Inc(Size, Sectors*512);
  end;

  IF XMSStream^.GetSize < Size Then Exit;

  Time := 0; Size := 0;
  for i := 1 to N do
  begin
    XMSStream^.Seek(0);
    If SkipTest Then Break;
    TimerTicks := 0;

    If Shuttle and (Track > 0) Then
    begin
      XMSStream^.Read(TestBuffer^, Sectors*512);
      WriteSectors(Track-1, Heads-1, 1, Sectors, TestBuffer);
    end;

    for J := 0 to Heads-1 do
    begin
      XMSStream^.Read(TestBuffer^, Sectors*512);
      StartTimer;
      WriteSectors(Track, J, 1, Sectors, TestBuffer);
      Inc(TimerTicks,ReadTimer);
      If TimerTicks >= 2000000000 Then
      begin
        Inc(Time, TimerTicks div 1193);
        TimerTicks := TimerTicks - (TimerTicks div 1193);
      end;
      Inc(Size, Sectors*512);
    end;

    If Shuttle and (Track < Tracks-1) Then
    begin
      XMSStream^.Read(TestBuffer^, Sectors*512);
      WriteSectors(Track+1, 0, 1, Sectors, TestBuffer);
    end;

    Inc(Time, TimerTicks div 1193);
  end;

{  Size := N*512*LongInt(Heads)*LongInt(Sectors);}
  If Time = 0 Then Exit;
  WriteSpeed := Size div Time;
  GetTrackLinearWriteSpeed := WriteSpeed;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Testing linear write speed in Kb on specified track}
function TTestDrive.GetTrackLinearVerifySpeed(Track, N: Word; Shuttle : Boolean) : LongInt;
var
  i, j : Byte;
  Size, TimerTicks, Time, VerifySpeed : LongInt;
begin
  SkipTest := False;
  GetTrackLinearVerifySpeed := 0;
  VerifySpeed := 0;
  If TestBuffer = Nil Then Exit;
  TimerTicks := 0; Time := 0;
  for i := 1 to N do
  begin
    If SkipTest Then Break;
    If I > 1 Then SeekToTrack(Track);
    for J := 0 to Heads-1 do
    begin
      StartTimer;
      VerifySectors(Track, J, 1, Sectors);
      Inc(TimerTicks, ReadTimer);
    end;
  end;
  Time := TimerTicks div 1193;
  Size := N*512*LongInt(Heads)*LongInt(Sectors);
  If Time = 0 Then Exit;
  VerifySpeed := Size div Time;
  If Time = 0 Then Exit;
  GetTrackLinearVerifySpeed := VerifySpeed;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{Testing linear read & write speed in Kb on specified track}
procedure TTestDrive.GetTrackLinearSpeed(Track, N: Word; var ReadSpeed, WriteSpeed : LongInt;
                                         NeedWrite, ReadShuttle, WriteShuttle : Boolean);
var
  i, j : Byte;
  Size, TimerTicks, Time : LongInt;
begin
  ReadSpeed := 0; WriteSpeed := 0;
  If TestBuffer = Nil Then Exit;

  ReadSpeed := GetTrackLinearReadSpeed(Track, N, ReadShuttle);
  If SkipTest Then Exit;
  If NeedWrite Then WriteSpeed := GetTrackLinearWriteSpeed(Track, 1, WriteShuttle);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetAverageSeekTime : Real;
var
  i, j, TimerTicks : LongInt;
begin
  AverageSeekTime := 0; TimerTicks := 0;
  SeekToTrack(Tracks div 2);
  SkipTest := False;
  for I := 1 to 1000 do                     {1000 moves to random track}
  begin
    If SkipTest Then Break;

    StartTimer;
    SeekToTrack(Random(Tracks));
    Inc(TimerTicks, ReadTimer);

    If (i mod 100 = 0) and (GV <> Nil) Then GV^.Update(i div 10);

  end;
  GV^.Update(100);

  AverageSeekTime := TimerTicks/(1193*1000);
  If AverageSeekTime < 3 Then AverageSeekTime := 0;
  GetAverageSeekTime := AverageSeekTime;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetAverageLinearReadSpeed(N : Byte; Shuttle : Boolean) : LongInt;
var
  i, Speed, TrackSpeed : LongInt;
begin
  {Testing average linaear read speed}
  Speed := 0; MinReadSpeed := MaxInt; MaxReadSpeed := 0;
  SkipTest := False;
  for I := 0 to (Tracks div 20)-1 do            {Testing 5% of cylinders}
  begin
    If SkipTest Then Break;
    SeekToTrack(I*20);
    TrackSpeed := GetTrackLinearReadSpeed(I*20, N, Shuttle);
    If TrackSpeed > MaxReadSpeed Then MaxReadSpeed := TrackSpeed;
    If TrackSpeed < MinReadSpeed Then MinReadSpeed := TrackSpeed;
    Speed := Speed+TrackSpeed;
  end;
  If SkipTest Then Speed := 0;
  AverageReadSpeed := Speed div (Tracks div 20);
  GetAverageLinearReadSpeed := AverageReadSpeed;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TTestDrive.GetAverageLinearSpeed(N : Byte; NeedWrite, ReadShuttle, WriteShuttle : Boolean);
var
  i, RSpeed, WSpeed, RS, WS : LongInt;
begin
  If GV <> Nil Then GV^.Update(0);
  MinReadSpeed := MaxLongInt; MaxReadSpeed := 0;
  MinWriteSpeed := MaxLongInt; MaxWriteSpeed := 0;
  AverageReadSpeed := 0; AverageWriteSpeed := 0;
  {Testing average linaear read speed}
  RSpeed := 0; WSpeed := 0;
  SkipTest := False;
  for I := 0 to (Tracks div 20)-1 do            {Testing 5% of cylinders}
  begin
    If SkipTest Then Break;
    SeekToTrack(I*20);
    GetTrackLinearSpeed(I*20, N, RS, WS, NeedWrite, ReadShuttle, WriteShuttle);
    If RS > MaxReadSpeed Then MaxReadSpeed := RS;
    If RS < MinReadSpeed Then MinReadSpeed := RS;
    If NeedWrite Then
    begin
      If WS > MaxWriteSpeed Then MaxWriteSpeed := WS;
      If WS < MinWriteSpeed Then MinWriteSpeed := WS;
    end;
    RSpeed := RSpeed + RS; WSpeed := WSpeed + WS;
    IF GV <> Nil Then GV^.Update(Round(i/(Tracks div 20)*100));
  end;
  If GV <> Nil Then GV^.Update(100);
  If SkipTest Then Exit;
  AverageReadSpeed := RSpeed div (Tracks div 20);
  AverageWriteSpeed := WSpeed div (Tracks div 20);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetMaxCacheSpeed : LongInt;
var
  i, j, Time, Size, TimerTicks, CacheSpeed : LongInt;
begin
  If GV <> Nil Then GV^.Update(0);
  {Testing cache tranfer speed}
  MaxCacheSpeed := 0; BestBlockSize := 0;
  GetMaxCacheSpeed := 0; If TestBuffer = Nil Then Exit;
  for j := 1 to 32 do    {Read blocks 2k,4k,...,64k}
  begin
    SkipTest := False;
    for i := 0 to 4 do ReadSectors(0,0,1,j*4, TestBuffer); {Fill disk buffer}
    TimerTicks := 0;
    for i := 0 to 127 do
    begin
      If SkipTest Then Break;
      StartTimer;
      ReadSectors(0,0,1,j*4, TestBuffer);
      Inc(TimerTicks,ReadTimer);
    end;
    Time := TimerTicks div 1193;
    Size := 512*128*LongInt(j*4);
    If Time = 0 Then Exit;
    CacheSpeed := Size div Time;
    If (Status = 0) and (CacheSpeed >= MaxCacheSpeed) Then
    begin
      MaxCacheSpeed := CacheSpeed; {Determine Max Cache Read Speed }
      BestBlockSize := j*2;        {Best result block size in KBytes}
    end;
    If GV <> Nil Then GV^.Update(Round(j/32*100));
    If SkipTest Then Break;
  end;
  If (AverageReadSpeed <> 0) and (MaxCacheSpeed < AverageReadSpeed) Then MaxCacheSpeed := 0;
  GetMaxCacheSpeed := MaxCacheSpeed;
  If GV <> Nil Then GV^.Update(100);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetMaxSeekTime : Real;
var
  i, j, TimerTicks : LongInt;
begin
  {Testing maximal seek}
  MaxSeekTime := 0; TimerTicks := 0;
  SkipTest := False;
  If GV <> Nil Then GV^.Update(0);
  for I := 1 to 300 do      {Full Stroke: seek 0 <-> MaxTrack}
  begin
    If SkipTest Then Break;

    StartTimer;
    SeekToTrack(Tracks-1);
    SeekToTrack(0);
    Inc(TimerTicks, ReadTimer);

    If (i mod 30 = 0) and (GV <> Nil) Then GV^.Update(i div 3);
  end;
  If GV <> Nil Then GV^.Update(100);
  MaxSeekTime := TimerTicks/(1193*600);
  If MaxSeekTime < 3 Then MaxSeekTime := 0;
  GetMaxSeekTime := MaxSeekTime;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetAverageAccessTime : Real;
var
  i, j, TimerTicks : LongInt;
begin
  {Testing true average access}
  If GV <> Nil Then GV^.Update(0);
  AverageAccessTime := 0; TimerTicks := 0;
  GetAverageAccessTime := 0;
  If TestBuffer = Nil Then Exit;
  SkipTest := False;
  SeekToTrack(Tracks div 2);
  SkipTest := False;
  for I := 1 to 1000 do        {Access to Random Sector 1000 times}
  begin
    If SkipTest Then Break;
    StartTimer;
    ReadSectors(Random(Tracks), Random(Heads), Random(Sectors)+1, 1, TestBuffer);
    Inc(TimerTicks,ReadTimer);
    If (i mod 100 = 0) and (GV <> Nil) Then GV^.Update(i div 10);
  end;
  If GV <> Nil Then GV^.Update(100);
  AverageAccessTime := TimerTicks/(1193*1000);
  If AverageAccessTime < 3 Then AverageAccessTime := 0;
  GetAverageAccessTime := AverageAccessTime;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetRandomReadSpeed : Word;
var
  i, j, TimerTicks, Size, Time : LongInt;
begin
  If GV <> Nil Then GV^.Update(0);
  GetRandomReadSpeed := 0;
  RandomReadSpeed := 0; TimerTicks := 0; Size := 0;
  If TestBuffer = Nil Then Exit;
  SkipTest := False;
  SeekToTrack(Tracks div 2);
  SkipTest := False;
  for I := 1 to 1500 do
  begin
    If SkipTest Then Break;
    j := Random(128)+1; Inc(Size, j);
    StartTimer;
    ReadSectors(Random(Tracks),Random(Heads),Random(Sectors)+1, j, TestBuffer);
    Inc(TimerTicks, ReadTimer);
    If (i mod 150 = 0) and (GV <> Nil) Then GV^.Update(i div 15);
  end;
  Time := TimerTicks div 1193;
  Size := Size*512;
  RandomReadSpeed := Size div Time;
  If RandomReadSpeed < 3 Then RandomReadSpeed := 0;
  GetRandomReadSpeed := RandomReadSpeed;
  If GV <> Nil Then GV^.Update(100);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetTrackToTrackSeekTime : Real;
var
  i, j, TimerTicks : LongInt;
begin
  If GV <> Nil Then GV^.Update(0);
  {Testing Track-To-Track Seek}
  TrackToTrackSeekTime := 0; TimerTicks := 0;
  SkipTest := False;
  SeekToTrack(0);
  for I := 0 to Tracks-1 do   {Sequental Tracks Seek}
  begin
    If SkipTest Then Break;

    StartTimer;
    SeekToTrack(I);
    Inc(TimerTicks,ReadTimer);
    If (i mod (Tracks div 10) = 0) and (GV <> Nil) Then GV^.Update(Round(i/Tracks*100));
  end;
  TrackToTrackSeekTime := TimerTicks/(1193*LongInt(Tracks-1));
  If TrackToTrackSeekTime < 1 Then TrackToTrackSeekTime := 0;
  GetTrackToTrackSeekTime := TrackToTrackSeekTime;
  If GV <> Nil Then GV^.Update(100);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetSpeedIndex : Word;
begin
  If (AverageReadSpeed <> 0) and (AverageAccessTime <> 0)
    Then SpeedIndex := Round(AverageReadSpeed/AverageAccessTime)
    Else SpeedIndex := 0;
  GetSpeedIndex := SpeedIndex;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetFATWeightedIndex : Word;
begin
  If (AverageReadSpeed <> 0) and (AverageWriteSpeed <> 0) and (AverageAccessTime <> 0)
    Then FATWeightedIndex := Round(0.65*(0.6*AverageReadSpeed+0.4*AverageWriteSpeed)/(0.35*AverageAccessTime*10))
    Else FATWeightedIndex := 0;
  GetFATWeightedIndex := FATWeightedIndex;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function    TTestDrive.GetHPFS386WeightedIndex : Word;
begin
  If (AverageReadSpeed <> 0) and (AverageWriteSpeed <> 0) and (AverageAccessTime <> 0)
    Then HPFS386WeightedIndex := Round(0.40*(0.85*AverageReadSpeed+0.15*AverageWriteSpeed)/(0.60*AverageAccessTime*10))
    Else HPFS386WeightedIndex := 0;
  GetHPFS386WeightedIndex := HPFS386WeightedIndex;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.GetBufferSize : Word;
{Buffer size in KB}
begin
  GetBufferSize := 0;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.ReadTrack(Track : Word; XMS : PXMSStream) : Boolean;
var
  i, j : Byte;
  Size : LongInt;
begin
  ReadTrack := False;
  SkipTest := False;
  FillChar(TestBuffer^,SizeOf(TestBuffer^),#0);

  If (TestBuffer = Nil) or (XMS = Nil) or (XMS^.Status <> 0) Then Exit;

  XMS^.Seek(0);
  Size := 0;

  for J := 0 to Heads-1 do
  begin
    If SkipTest Then Break;
    ReadSectors(Track, J, 1, Sectors, TestBuffer);
    XMS^.Write(TestBuffer^, Sectors*512);
    Inc(Size, Sectors*512);
  end;

  IF XMS^.GetSize < Size Then Exit;

  ReadTrack := True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.WriteTrack(Track : Word; XMS : PXMSStream) : Boolean;
var
  i, j : Byte;
  Size : LongInt;
begin
  WriteTrack := False;
  SkipTest := False;

  Size := 0;
  XMS^.Seek(0);

  for J := 0 to Heads-1 do
  begin
    XMS^.Read(TestBuffer^, Sectors*512);
    WriteSectors(Track, J, 1, Sectors, TestBuffer);
    Inc(Size, Sectors*512);
  end;

  WriteTrack := True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TTestDrive.CopyTrack(Track : Word; P : PTestDrive) : Boolean;
begin
  CopyTrack := False;
  If not ReadTrack(Track, XMSStream) Then Exit;
  If not P^.WriteTrack(Track, XMSStream) Then Exit;
  CopyTrack := True;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WriteResultsTable(var Report : Text; Drv : PTestDrive);
const
  OrigTable : Array [1..9] of String[80] =
  (
   'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄ¿',
   '³Vendor/Model       ³Total³Average³Maximal³Average³TTT³Average³  Max.  ³ IDX ³',
   '³                   ³Size,³ Seek  ³ Seek  ³Access ³   ³Linear ³ Cache  ³     ³',
   '³                   ³Cache³ Time  ³ Time  ³ Time  ³   ³ Speed ³  Read  ³     ³',
   '³                   ³Size ³  ms.  ³  ms.  ³  ms.  ³ms.³MB/sec.³ MB/sec.³     ³',
   'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄ´',
   '³                   ³ N/A ³  N/A  ³  N/A  ³  N/A  ³N/A³  N/A  ³  N/A   ³ N/A ³',
   '³                   ³     ³       ³       ³       ³   ³       ³        ³     ³',
   'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÙ'
  );

var
  Table : Array [1..9] of String[80];

  procedure InsertStr(InsLine, InsPos, StrWidth : Byte; S : String; AlignRight : Boolean);
  var
    P : Byte;
    S1, S2 : String;
  begin
    FillChar(Table[InsLine][InsPos],StrWidth, Byte(' '));
    While S[Length(S)] = ' ' do Dec(Byte(S[0]));
    S1 := Copy(S,1,StrWidth); S2 := Copy(S,StrWidth+1,Length(S));
    If AlignRight Then P := InsPos+StrWidth-Length(S1)
                  Else P := InsPos;
    Move(S1[1],Table[InsLine][P],Length(S1));
    If S2 <> '' Then
    begin
      If AlignRight Then P := InsPos+StrWidth-Length(S2)
                    Else P := InsPos;
      Move(S2[1],Table[InsLine+1][P],Length(S2));
    end;
  end;

var
  i : Byte;
  Size : Word;
begin
  With Drv^ do
  begin
    System.WriteLn(Report);
    System.WriteLn(Report,Separator('Tests Summary Table'));
    System.WriteLn(Report);

    for i := 1 to 9 do Table[i] := OrigTable[i];

    InsertStr(7,2,19,GetModel,False);

    Size := GetSize;
    If Size >= 1024 Then InsertStr(7,22,5,RealToStr(Size/1024)+'GB',False)
                    Else InsertStr(7,22,5,IntToStr(Size)+'MB',False);

    Size := GetBufferSize;
    If Size > 0 Then InsertStr(8,22,5,IntToStr(Size)+'KB',False);

    If AverageSeekTime <> 0 Then InsertStr(7,29,4,RealToStr(AverageSeekTime),True);
    If MaxSeekTime <> 0 Then InsertStr(7,37,4,RealToStr(MaxSeekTime),True);
    If AverageAccessTime <> 0 Then InsertStr(7,45,4,RealToStr(AverageAccessTime),True);
    If TrackToTrackSeekTime <> 0 Then InsertStr(7,52,3,RealToStr(TrackToTrackSeekTime),True);
    If AverageReadSpeed <> 0 Then InsertStr(7,56,6,'R='+RealToStr(AverageReadSpeed/1024),True);
    If AverageWriteSpeed <> 0 Then InsertStr(8,56,6,'W='+RealToStr(AverageWriteSpeed/1024),True);
    If MaxCacheSpeed <> 0 Then InsertStr(7,66,4,RealToStr(MaxCacheSpeed/1024),True);
    If SpeedIndex <> 0 Then InsertStr(7,73,4,IntToStr(SpeedIndex),True);

    for i := 1 to 9 do
      System.WriteLn(Report,Table[i]);

    System.WriteLn(Report);
  end;
end;

begin
end.
