{$X+,G+,D-,L-,S-,R-}
unit AppWin;

interface

uses Drivers, Objects, Validate, Views, Menus, App, TextView, Dialogs,
     Controls, MyMsgBox, Drive, Tests, IDE, Service, XMS, ASPI, Help,
     GrowView, Defect;

const

  {InfoWindow's palette}
  CInfoWinPalette = #8#9#10#11#12#13#14#15+#8#9#10#13+#32#30#26#31;

  {constants for TStringBuf}
  MaxLinesCount   = 200;
  MaxLineLength   = 100;

  cmSetConfig  = 1000;
  cmSaveConfig = 1001;

  cmSaveList   = 1100;

type

  PMyStatusLine = ^TMyStatusLine;
  TMyStatusLine = Object(TStatusLine)
    procedure Draw; virtual;
  end;

  PStringBuf = ^TStringBuf;
  TStringBuf = Array [1..MaxLinesCount] of String[MaxLineLength];

  PColorText = ^TColorText;
  TColorText = Object(TScroller)
    LinesCount  : Integer;
    StrBuf      : TStringBuf;
    Color       : Integer;
    FirstLine   : Integer;

    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);

    function    GetPalette: PPalette; virtual;
    procedure   CalcBounds(var Bounds: TRect; D: TPoint); virtual;
    procedure   Draw; virtual;

    procedure   FillBuf(S : String; var Buf : TDrawBuffer);
    procedure   WriteLineAt(LineNumber : Integer; S: String); virtual;
    procedure   WriteLine(S: String); virtual;
    procedure   LogWriteLineAt(LineNumber : Integer; S: String; var  LogFile : Text);
    procedure   LogWriteLine(S: String; var LogFile : Text); virtual;

    function    ReadPureLine(LineNumber : Integer) : String; virtual;
  end;

  PInfoWindow = ^TInfoWindow;
  TInfoWindow = Object(TWindow)
    Drive       : PTestDrive;
    ScreenText  : PColorText;
    Becnhmarked : Boolean;

    constructor Init(Drv : PTestDrive);
    destructor  Done; virtual;

    procedure   Draw; virtual;

    function    GetLinesCount : Integer;
    procedure   WriteLineAt(LineNumber : Integer; S: String); virtual;
    procedure   WriteLine(S: String); virtual;
    procedure   LogWriteLineAt(LineNumber : Integer; S: String; var LogFile : Text);
    procedure   LogWriteLine(S: String; var LogFile : Text);

    procedure   SaveResults(var F: Text); virtual;
  end;

  PSaveDialog = ^TSaveDialog;
  TSaveDialog = Object(TDialog)
    constructor Init;
  end;

  TDrivesCollection = Object(TCollection)
    constructor Init;
    function    GetDriveNumber(I : Integer) : String; virtual;
    function    GetDriveType(I : Integer) : String; virtual;
    function    GetDriveModel(I : Integer) : String; virtual;
  end;

  PSelectDriveDialog = ^TSelectDriveDialog;
  TSelectDriveDialog = Object(TDialog)
    Drives      : TDrivesCollection;
    constructor Init;
  end;

  PATAPICollection = ^TATAPICollection;
  TATAPICollection = Object(TCollection)
    constructor Init;
    procedure   FreeItem(Item: Pointer); virtual;
  end;

  PListDialog = ^TListDialog;
  TListDialog = Object(TDialog)
    constructor Init(ATitle, AHeader : String);
  end;

  PDefectListDialog = ^TDefectListDialog;
  TDefectListDialog = Object(TDialog)
    DL : PDefectList;
    constructor Init(L : PDefectList);
    procedure   HandleEvent(var Event: TEvent); virtual;
  end;

  PConfigDialog = ^TConfigDialog;
  TConfigDialog = Object(TDialog)
    constructor Init;
  end;

  PManualSelectDialog = ^TManualSelectDialog;
  TManualSelectDialog = Object(TDialog)
    constructor Init;
  end;

  PEnableDisableDialog = ^TEnableDisableDialog;
  TEnableDisableDialog = Object(TDialog)
    constructor Init(ATitle : String);
  end;

  PAboutDialog = ^TAboutDialog;
  TAboutDialog = Object(TDialog)
    constructor Init;
    procedure   Draw; virtual;
  end;

  PSysinfoDialog = ^TSysinfoDialog;
  TSysinfoDialog = Object(TDialog)
    constructor Init;
  end;

  PMediaVerifyDialog = ^TMediaVerifyDialog;
  TMediaVerifyDialog = Object(TDialog)
    constructor Init(LastCyl: Longint);
  end;

  PFormatDialog = ^TFormatDialog;
  TFormatDialog = Object(TDialog)
    constructor Init(LastCyl: Longint);
  end;

  PProgressDialog = ^TProgressDialog;
  TProgressDialog = Object(TDialog)
    CurrentText : PStaticText;
    TotalText   : PStaticText;
    constructor Init(var GV1, GV2 : PGrowView; ATitle : String);
    destructor  Done; virtual;
    procedure   SetCurrentText(AText : String);
    procedure   SetTotalText(AText : String);
  end;

  PQuantumConfigDialog = ^TQuantumConfigDialog;
  TQuantumConfigDialog = Object(TDialog)
    constructor Init;
    procedure   HandleEvent(var Event: TEvent); virtual;
  end;

implementation

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                         TDrivesCollection.'s Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TDrivesCollection.Init;
const
  FStr = '%d %4dMb %-20s %-40s';
var
  I, NumDisks : Integer;
  D : Pointer;
  S, DN, DT, DM : String;

  ParamRec : Record
    DN : LongInt;
    DS : LongInt;
    DT : PString;
    DM : PString;
  end;

begin
  inherited Init(8,2);
  NumDisks := GetDrivesNumber;
  for I := 0 to NumDisks-1 do
  begin
    New(PIDEDrive(D), Init(I+$80, 0, 0));
    With PIDEDrive(D)^ do
    begin
      DT := GetType;
      DM := GetModel;
      ParamRec.DN := BIOSDriveNumber-$80;
      ParamRec.DS := GetSize;
      ParamRec.DT := @DT;
      ParamRec.DM := @DM;
      FormatStr(S, FStr, ParamRec)
    end;
    Insert(NewStr(S));
    Dispose(PIDEDrive(D), Done);
  end;
end;

function TDrivesCollection.GetDriveNumber(I : Integer) : String;
begin
  GetDriveNumber := IntToStr(PTestDrive(At(I))^.BIOSDriveNumber);
end;

function TDrivesCollection.GetDriveType(I : Integer) : String;
begin
  GetDriveType := PTestDrive(At(I))^.GetType;
end;

function TDrivesCollection.GetDriveModel(I : Integer) : String;
begin
  GetDriveModel := PTestDrive(At(I))^.GetModel;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                         TATAPICollection.'s Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TATAPICollection.Init;
const
  FStr = '%-10s %-7s %-12s %-28s %-8s';
var
  I, J  : Byte;
  S, P, U, D, M, F : String;

  FormatRec : Record
    Port,
    UnitNo,
    Device,
    Model,
    Firmware : PString;
  end;

  IDEInfo : TIDEInfo;

begin
  inherited Init(4,1);
  for i := 0 to 3 do
    for j := 0 to 1 do
    begin

      P := Channel[i]; U := Disk[j];
      D := 'None'; M := ''; F := '';

      If GetIDEorATAPIInfo(ChannelN[i], j, IDEInfo, True)
      Then
        begin
          D := 'ATAPI device'; {SCSI_DevType[Hi(IDEInfo.Config)] - Hi(IDEInfo.Config) = 5}
          M := Trim(IDEInfo.Model);
          F := IDEInfo.Revision;
        end
      Else If GetIDEorATAPIInfo(ChannelN[i], j, IDEInfo, False) Then
             begin
               D := 'Hard disk';
               M := Trim(IDEInfo.Model);
               F := IDEInfo.Revision;
             end;

      FormatRec.Port := @P;
      FormatRec.UnitNo := @U;
      FormatRec.Device := @D;
      FormatRec.Model := @M;
      FormatRec.Firmware := @F;

      FormatStr(S, FStr, FormatRec);
      Insert(NewStr(S));
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TATAPICollection.FreeItem(Item: Pointer);
begin
  If Item <> Nil then DisposeStr(Item);
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                            TMyStatusLine's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TMyStatusLine.Draw;
begin
  inherited Draw;
  WriteStr(52,0,'³ Memory: '+IntToStr((MemAvail div 1024)+(GetFreeMemSize div 64))+'Kb, XMS: '+
                    RealToStr(XMSGetFree div 1024)+'Mb',1);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                           TSelectDriveDialog's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TSelectDriveDialog.Init;
const
  DrivesListHeader = '# Size   Port/Unit            Model';
var
  R, Bounds : TRect;
  B         : PButton;
  S         : PScrollBar;
  ListBox   : PListBox;
begin
  Bounds.Assign(0,0,74,12);
  inherited Init(Bounds,'Select drive');
  Options := Options or ofCentered;
  HelpCtx := hcDiskSelectList;

  Bounds.Assign(3,9,15,11);
  New(B, Init(Bounds, '~S~elect', cmOk, bfDefault));
  Insert(B);

  Bounds.Assign(58,9,70,11);
  New(B, Init(Bounds, '~C~ancel', cmCancel, bfNormal));
  Insert(B);

  Bounds.Assign(70,3,71,8);
  S := New(PScrollBar, Init(Bounds));
  Insert(S);

  Bounds.Assign(3,3,70,8);
  ListBox := New(PListBox, Init(Bounds, 1, S));
  Insert(ListBox);

  Bounds.Assign(3,2,71,3);
  Insert(New(PLabel, Init(Bounds, DrivesListHeader, ListBox)));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                           TListDialog's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TListDialog.Init(ATitle, AHeader : String);
var
  R, Bounds : TRect;
  B         : PButton;
  S         : PScrollBar;
  ListBox   : PListBox;
begin
  Bounds.Assign(0,0,78,15);
  inherited Init(Bounds,ATitle);
  Options := Options or ofCentered;

  Bounds.Assign(32,12,44,14);
  New(B, Init(Bounds, '~O~k', cmOk, bfDefault));
  Insert(B);

  Bounds.Assign(74,3,75,11);
  S := New(PScrollBar, Init(Bounds));
  Insert(S);

  Bounds.Assign(3,3,74,11);
  ListBox := New(PListBox, Init(Bounds, 1, S));
  Insert(ListBox);

  Bounds.Assign(3,2,74,3);
  Insert(New(PLabel, Init(Bounds, AHeader, ListBox)));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                          TDefectListDialog's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TDefectListDialog.Init(L : PDefectList);
const
  DefectListTitle  = 'Defect list';
  DefectListHeader = '   #   Cylinder Head Sector';
var
  R, Bounds : TRect;
  B         : PButton;
  S         : PScrollBar;
  ListBox   : PListBox;
  Str       : String;
begin
  Bounds.Assign(0,0,78,17);
  inherited Init(Bounds, DefectListTitle);
  Options := Options or ofCentered;
  DL := L;

  Bounds.Assign(20,14,32,16);
  New(B, Init(Bounds, '~O~k', cmOk, bfDefault));
  Insert(B);

  Bounds.Assign(46,14,58,16);
  Insert(New(PButton, Init(Bounds, '~S~ave', cmSaveList, bfNormal)));

  Bounds.Assign(74,5,75,13);
  S := New(PScrollBar, Init(Bounds));
  Insert(S);

  Bounds.Assign(3,5,74,13);
  ListBox := New(PListBox, Init(Bounds, 1, S));
  Insert(ListBox);

  Bounds.Assign(3,4,74,5);
  Insert(New(PLabel, Init(Bounds, DefectListHeader, ListBox)));

  Bounds.Assign(3,2,74,3);
  With L^ do
    Str :=  'Used ~'+ IntToStr(DefectsCount) +
            '~ of ~'+ IntToStr(MaxDefectsCount)+
            '~ possible defect entries (~'+ IntToStr(DefectsCount*100 div MaxDefectsCount)+ '%~)';

  Insert(New(PLabel, Init(Bounds, Str, Nil)))
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDefectListDialog.HandleEvent(var Event: TEvent);
var
  R: TRect;
begin
  if Event.What = evCommand Then
  begin
    case Event.Command of
      cmSaveList:
        begin
          ClearEvent(Event);
          DL^.Save;
          MessageBox(#3'Defect list saved to DEFECTS.LST',Nil,
                     mfInformation+mfOkButton, hcNoContext);
        end;
    end;
  end;
  inherited HandleEvent(Event);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                         TColorText's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TColorText.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
begin
  inherited Init(Bounds, AHScrollBar, AVScrollBar);
  Color := 23;
  LinesCount := 0; FirstLine := 1;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TColorText.FillBuf(S : String; var Buf : TDrawBuffer);
var
  Len   : Byte absolute S;
  i, j,
  B,
  OldColor : Byte;
  S1    : String;
  C     : Integer;
  XPos  : Byte;
begin
  MoveChar(Buf, ' ', Color, Size.X);       { fill buffer with spaces }
  XPos := 0;
  OldColor := Color;
  i := 0;
  While i < Len do
  begin
    Inc(i);
    j := i; S1[0] := #0;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    MoveStr(Buf[XPos], S1, Color);
    Inc(XPos, j-i);
    i := j+1; j := i;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    i := j;
    If J < Len Then
    begin
      If S1[0] = #0
        Then begin MoveStr(Buf[XPos], '\', Color); Inc(XPos); end
        Else begin
          Val(S1, B, C);
          If C = 0 Then Color := B;
        end;
    end;
  end;
  Color := OldColor;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TColorText.Draw;
var
  StartLine,
  Value,
  I            : Integer;
  Buf          : TDrawBuffer;

begin
  Value := VScrollBar^.Value;
  StartLine := Max(1, Value-Size.Y+1);
  FirstLine := StartLine;

  for i := 0 to Size.Y-1 do
  begin
    FillBuf(StrBuf[FirstLine+i], Buf);
    WriteBuf(0, i, Size.X, 1, Buf);
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TColorText.WriteLineAt(LineNumber : Integer; S: String);
var
  i, Value, StartLine : Integer;
  Buf                 : TDrawBuffer;
begin
  If LineNumber = -1 Then LineNumber := LinesCount;
  StrBuf[LineNumber] := S;
  If LineNumber > LinesCount Then
  begin
    for i := LinesCount+1 to LineNumber-1 do StrBuf[i] := '';
    LinesCount := LineNumber;
  end;
  VScrollBar^.SetParams(LineNumber, 1, LinesCount, Size.Y, 1);
  Draw;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TColorText.WriteLine(S: String);
var
  i : Integer;
begin
  If LinesCount >= MaxLinesCount Then
  begin
    for i := 2 to MaxLinesCount do StrBuf[i-1] := StrBuf[i];
    StrBuf[MaxLinesCount] := S;
    Draw;
    Exit;
  end;
  Inc(LinesCount);
  WriteLineAt(LinesCount, S);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TColorText.LogWriteLineAt(LineNumber : Integer; S: String; var  LogFile : Text);
begin
  WriteLineAt(LineNumber, S);
  If LineNumber = -1 Then LineNumber := LinesCount;
  {$I-}
  System.WriteLn(LogFile, ReadPureLine(LineNumber));
  {$I+}
  If IOResult <> 0 Then;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TColorText.LogWriteLine(S: String; var  LogFile : Text);
begin
  WriteLine(S);
  {$I-}
  System.WriteLn(LogFile, ReadPureLine(LinesCount));
  {$I+}
  If IOResult <> 0 Then;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TColorText.GetPalette: PPalette;
const
  P: String[Length(CInfoWinPalette)] = CInfoWinPalette;
begin
  GetPalette := @P;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TColorText.CalcBounds(var Bounds: TRect; D: TPoint);
begin
  Size.X := Size.X+D.X;
  Size.Y := Size.Y+D.Y;
  inherited CalcBounds(Bounds, D);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function   TColorText.ReadPureLine(LineNumber : Integer) : String;
var
  S, S1 : String;
  Len  : Byte absolute S;
  i, j : Byte;
begin
  S := StrBuf[LineNumber]; S1 := '';
  i := 0;
  While i < Len do
  begin
    Inc(i);
    j := i;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    S1 := S1+Copy(S, i, j-i);
    i := j+1; j := i;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    If (J < Len) and (j = i) Then S1 := S1+'\';
    i := j;
  end;
  ReadPureLine := S1;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                         TInfoWindow's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TInfoWindow.Init(Drv : PTestDrive);
var
  Bounds : TRect;
  ScrollBar : PScrollBar;
begin
  If ScreenMode and smFont8x8 = 0
  Then begin Size.X := 80; Size.Y := 23; end
  Else begin Size.X := 80; Size.Y := 49;; end;
  GetExtent(Bounds);

  inherited Init(Bounds, 'Hard Disk '+IntToStr(Drv^.BiosDriveNumber-$80), wnNoNumber);
  Flags := Flags and (not wfZoom) and (not wfGrow) and (not wfMove);
  ScrollBar := StandardScrollBar(sbVertical or sbHandleKeyboard);
  ScrollBar^.Options := ScrollBar^.Options or ofPostProcess;
  Insert(ScrollBar);
  Drive := Drv; Becnhmarked := False;

  Inc(Bounds.A.X,2); Inc(Bounds.A.Y); Dec(Bounds.B.X); Dec(Bounds.B.Y);
  New(ScreenText, Init(Bounds, Nil, ScrollBar));
  Insert(ScreenText);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
destructor  TInfoWindow.Done;
begin
  inherited Done;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.Draw;
begin
  inherited Draw;
  ScreenText^.Draw;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function   TInfoWindow.GetLinesCount : Integer;
begin
  GetLinesCount := ScreenText^.LinesCount;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.WriteLineAt(LineNumber : Integer; S: String);
begin
  ScreenText^.WriteLineAt(LineNumber, S);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.WriteLine(S: String);
begin
  ScreenText^.WriteLine(S);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.LogWriteLineAt(LineNumber : Integer; S: String; var LogFile : Text);
begin
  ScreenText^.LogWriteLineAt(LineNumber, S, LogFile);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.LogWriteLine(S: String; var LogFile : Text);
begin
  ScreenText^.LogWriteLine(S, LogFile);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TInfoWindow.SaveResults(var F: Text);
var
  I : Integer;
  S : String;

  function IsAMI : Boolean;
  var
    P : ^String;
    i : Word;
    S : String;
  begin
    P := Ptr($F000,$e000);
    S[0] := #255;
    Move(P^,S[1], 255);
    IsAMI := Pos('American Megatrends', S) <> 0;
  end;

begin
  System.WriteLn(F, Separator('Test background information'));
  System.WriteLn(F,'ş Running under: '+GetOSName);
  System.WriteLn(F,'ş CPU: '+GetCPU);
  If IsAMI
  Then S := '(C) American Megatrends Inc.'
  Else S := GetBIOSString($F000,$E060);
  System.WriteLn(F,'ş BIOS: '+S);
  If Pos('Award', S) <> 0 Then
  begin
    System.WriteLn(F,'   Version : '+GetBIOSString($F000,$E0C0));
    System.WriteLn(F,'   ID      : '+GetBIOSString($F000,$EC70));
  end;
  System.WriteLn(F);
  System.WriteLn(F, Separator('HddSpeed v'+Version+' Results'));
  for I := 1 to ScreenText^.LinesCount do
    System.WriteLn(F, ScreenText^.ReadPureLine(I));
  If Becnhmarked Then WriteResultsTable(F, Drive);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TSaveDialog.Init;
var
  Bounds : TRect;
  I      : PInputLine;
  B      : PButton;
begin
  Bounds.Assign(0,0,40,9);
  inherited Init(Bounds, 'Save report to file');
  Options := Options or ofCentered;
  HelpCtx := hcFileSave;

  Bounds.Assign(3,4,30,5);
  Insert(New(PCheckBoxes, Init(Bounds,
    NewSItem('~A~ppend if file exists' , nil))));

  Bounds.Assign(3,6,15,8);
  Insert(New(PButton, Init(Bounds, '~O~k', cmOk, bfDefault)));

  Bounds.Assign(24,6,36,8);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

  Bounds.Assign(3,2,35,3);
  New(I, Init(Bounds, 60));
  Insert(I);

  Bounds.A.X := Bounds.B.X;
  Bounds.B.X := Bounds.A.X+3;
  Insert(New(PHistory, Init(Bounds, I, 0)));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TConfigDialog.Init;
var
  Bounds : TRect;
  C, C1  : PCheckBoxes;
  R      : PRadioButtons;
begin
  Bounds.Assign(0,0,75,19);
  inherited Init(Bounds, 'Configuration');
  Options := Options or ofCentered;
  HelpCtx := hcConfig;

  Bounds.Assign(7,16,19,18);
  Insert(New(PButton, Init(Bounds, '~O~k', cmOk, bfDefault)));

  Bounds.Assign(54,16,66,18);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

  Bounds.Assign(2,2,70,7);
  New(C1, Init(Bounds,
    NewSItem('~E~ffective Buffer Size',
    NewSItem('R~o~tation Speed',
    NewSItem('Average ~S~eek Time',
    NewSItem('~M~ax Seek Time',
    NewSItem('~T~rack-to-track Seek Time',
    NewSItem('~A~verage Access Time',
    NewSItem('~L~inear Speed At 0 & Last Tracks',
    NewSItem('A~v~erage Linear Speed',
    NewSItem('Max. ~C~ache Read Speed',
    NewSItem('~R~andom Read Speed',
    nil))))))))))));
  Insert(C1);
  Bounds.Assign(3,1,68,2);
  Insert(New(PLabel, Init(Bounds,'Run tests',C1)));

  Bounds.Assign(2,9,43,15);
  New(C, Init(Bounds,
    NewSItem('Enable non-destructive ~w~rite tests',
    NewSItem('Do~n~''t ask on write tests',
    NewSItem('~D~etailed read/write graphs',
    NewSItem('Save tracks speed lo~g~ in graphs',
    NewSItem('Enable T~.~E.C. prediction',
    NewSItem('Gra~p~hic frames & controls',
    nil))))))));
  Insert(C);
  Bounds.Assign(3,8,30,9);
  Insert(New(PLabel, Init(Bounds,'Global options',C)));

  Bounds.Assign(45,9,73,13);
  New(R, Init(Bounds,
    NewSItem('Autodetect ~b~est method',
    NewSItem('~I~ndex',
    NewSItem('Loo~k~-ahead off & read',
    NewSItem('Cache over~f~low & write',
    nil))))));
  Insert(R);
  Bounds.Assign(45,8,73,9);
  Insert(New(PLabel, Init(Bounds,'RPM testing method',R)));

  C1^.Select;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TManualSelectDialog.Init;
var
  Bounds : TRect;
  I      : PInputLine;
  R      : PRadioButtons;
begin
  Bounds.Assign(0,0,37,14);
  inherited Init(Bounds, 'Specify drive & port');
  Options := Options or ofCentered;
  HelpCtx := hcDiskSelectManual;

  Bounds.Assign(16,2,21,3);
  New(I, Init(Bounds, 5));
  Insert(I);
  Bounds.Assign(2,2,15,3);
  Insert(New(PLabel, Init(Bounds, '~D~isk number:', I)));

  Bounds.Assign(3,5,33,10);
  New(R, Init(Bounds,
    NewSItem('~N~on-ide drive',
    NewSItem('~P~rimary/Master',
    NewSItem('P~r~imary/Slave',
    NewSItem('~S~econdary/Master',
    NewSItem('S~e~condary/Slave',
    nil)))))));
  Insert(R);
  Bounds.Assign(2,4,30,5);
  Insert(New(PLabel, Init(Bounds, 'Port:', R)));

  Bounds.Assign(3,11,15,13);
  Insert(New(PButton, Init(Bounds, '~O~k', cmOk, bfDefault)));

  Bounds.Assign(20,11,32,13);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

  I^.Select;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TEnableDisableDialog.Init(ATitle : String);
var
  Bounds : TRect;
begin
  Bounds.Assign(0,0,50,5);
  inherited Init(Bounds, ATitle);
  Options := Options or ofCentered;

  Bounds.Assign(3,2,15,4);
  Insert(New(PButton, Init(Bounds, '~E~nable', cmYes, bfDefault)));

  Bounds.Assign(18,2,31,4);
  Insert(New(PButton, Init(Bounds, '~D~isable', cmNo, bfNormal)));

  Bounds.Assign(34,2,46,4);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TAboutDialog.Init;
const
   AboutText : Array [1..4] of String[40] =
   (
    'HddSpeed v'+Version,
    '(C) 1996-99 Michael Radchenko',
    'FIDO: 2:5025/25',
    'e-mail: mike@vsi.vrn.ru'
   );
var
  Bounds : TRect;
  B      : PButton;
  T      : PStaticText;
  i      : Byte;
begin
  Bounds.Assign(0,0,40,12);
  inherited Init(Bounds, 'About');
  HelpCtx := hcMainIndex;
  Options := Options or ofCentered;

  for i := 1 to 4 do
  begin
    Bounds.Assign(0,i+1,Length(AboutText[i]),i+2);
    New(T, Init(Bounds, AboutText[i]));
    T^.Options := T^.Options or ofCenterX;
    Insert(T);
  end;

  Bounds.Assign(0,9,10,11);
  New(B, Init(Bounds, '~O~k', cmOk, bfDefault));
  B^.Options := B^.Options or ofCenterX;
  Insert(B);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TAboutDialog.Draw;
var
  Buf : TDrawBuffer;
begin
  inherited Draw;
  MoveStr(Buf,#223#223#223#223#223#223,31);
  WriteBuf(4,7,6,1,Buf);
  MoveStr(Buf,#223#223#223#223#223#223,116);
  WriteBuf(4,8,6,1,Buf);


  MoveStr(Buf,'Made In',123);
  WriteBuf(29,7,7,1,Buf);
  MoveStr(Buf,'Russia',123);
  WriteBuf(30,8,6,1,Buf);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TSysInfoDialog.Init;
var
  Bounds : TRect;
  B      : PButton;
  T      : PStaticText;
  i      : Byte;
begin
  Bounds.Assign(0,0,40,11);
  inherited Init(Bounds, 'System Information');
  HelpCtx := hcMainIndex;
  Options := Options or ofCentered;

  Bounds.Assign(0,8,10,10);
  New(B, Init(Bounds, '~O~k', cmOk, bfDefault));
  B^.Options := B^.Options or ofCenterX;
  Insert(B);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TMediaVerifyDialog.Init(LastCyl: Longint);
var
  Bounds : TRect;
  B      : PButton;
  P      : PInputLine;
begin
  Bounds.Assign(0,0,48,11);
  inherited Init(Bounds, 'Perform media test');
  Options := Options or ofCentered;
  HelpCtx := hcFileSave;

  Bounds.Assign(3,2,45,4);
  Insert(New(PCheckBoxes, Init(Bounds,
    NewSItem('Try to ~r~epair/relocate found defects' ,
    NewSItem('Save media test l~o~g' ,
    nil)))));

  Bounds.Assign(17,5,23,6);
  P := New(PInputLine, Init(Bounds, 4));
  P^.SetValidator(New(PRangeValidator, Init(0, LastCyl)));
  Insert(P);
  Bounds.Assign(3,5,16,6);
  Insert(New(PLabel, Init(Bounds, '~F~irst track:', P)));

  Bounds.Assign(17,6,23,7);
  P := New(PInputLine, Init(Bounds, 4));
  P^.SetValidator(New(PRangeValidator, Init(0, LastCyl)));
  Insert(P);
  Bounds.Assign(3,6,16,7);
  Insert(New(PLabel, Init(Bounds, '~L~ast  track:', P)));

  Bounds.Assign(40,5,45,6);
  P := New(PInputLine, Init(Bounds, 4));
  P^.SetValidator(New(PRangeValidator, Init(0, 10000)));
  Insert(P);
  Bounds.Assign(26,5,39,6);
  Insert(New(PLabel, Init(Bounds, '~T~ests count:', P)));

  Bounds.Assign(32,8,44,10);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

  Bounds.Assign(4,8,15,10);
  Insert(New(PButton, Init(Bounds, '~S~tart', cmOk, bfDefault)));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TFormatDialog.Init(LastCyl: Longint);
var
  Bounds : TRect;
  B      : PButton;
  P      : PInputLine;
begin
  Bounds.Assign(0,0,48,10);
  inherited Init(Bounds, 'Perform media format');
  Options := Options or ofCentered;
  HelpCtx := hcFileSave;

  Bounds.Assign(3,2,45,3);
  Insert(New(PCheckBoxes, Init(Bounds,
    NewSItem('~U~nassign remapped sectors' ,
    nil))));

  Bounds.Assign(17,4,23,5);
  P := New(PInputLine, Init(Bounds, 4));
  P^.SetValidator(New(PRangeValidator, Init(0, LastCyl)));
  Insert(P);
  Bounds.Assign(3,4,16,5);
  Insert(New(PLabel, Init(Bounds, '~F~irst track:', P)));

  Bounds.Assign(17,5,23,6);
  P := New(PInputLine, Init(Bounds, 4));
  P^.SetValidator(New(PRangeValidator, Init(0, LastCyl)));
  Insert(P);
  Bounds.Assign(3,5,16,6);
  Insert(New(PLabel, Init(Bounds, '~L~ast  track:', P)));

  Bounds.Assign(32,7,44,9);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfNormal)));

  Bounds.Assign(4,7,15,9);
  Insert(New(PButton, Init(Bounds, '~S~tart', cmOk, bfDefault)));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TProgressDialog.Init(var GV1, GV2 : PGrowView; ATitle : String);
var
  R       : TRect;
  B       : PButton;
  T       : PStaticText;
begin
  R.Assign( 0, 0, 40, 11 );
  inherited Init( R, ATitle );
  Options := Options or ofCentered;

  R.Assign(2,2,38,3);
  New(T, Init(R, '        Current test progress         '));
  Insert(T);
  CurrentText := T;
  R.Assign( 2, 3, 38, 4 );
  GV1 := New( PGrowView, Init( R, 100 ));
  Insert( GV1 );

  R.Assign(2,5,38,6);
  New(T, Init(R, '           Total progress             '));
  Insert(T);
  TotalText := T;
  R.Assign( 2, 6, 38, 7 );
  GV2 := New( PGrowView, Init( R, 100 ));
  Insert( GV2 );

  R.Assign(0,8,12,10);
  New(B, Init(R, '~S~kip', cmCancel, 1));
  B^.Options := B^.Options or ofCenterX;
  Insert(B);

  {Bar1 := @GV1; Bar2 := @GV2;}
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TProgressDialog.SetCurrentText(AText : String);
begin
  CurrentText^.Text^ := #3+AText;
  CurrentText^.Draw;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TProgressDialog.SetTotalText(AText : String);
begin
  TotalText^.Text^ := #3+AText;
  TotalText^.Draw;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
destructor TProgressDialog.Done;
begin
  inherited Done;
{  Bar1^ := Nil; Bar2^ := Nil;}
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TQuantumConfigDialog.Init;
var
  Bounds : TRect;
  C, C1  : PCheckBoxes;
begin
  Bounds.Assign(0,0,75,15);
  inherited Init(Bounds, 'Internal drive configuration');
  Options := Options or ofCentered;
  HelpCtx := hcConfig;

  Bounds.Assign(3,2,40,4);
  New(C, Init(Bounds,
    NewSItem('Reallocate ~u~ncorrectable errors',
    NewSItem('~W~rite cache enable',
    nil))));
  Insert(C);
  Bounds.Assign(3,1,23,2);
  Insert(New(PLabel, Init(Bounds,'Drive parameters', C1)));

  Bounds.Assign(45,2,68,4);
  New(C1, Init(Bounds,
    NewSItem('~C~ache enable',
    NewSItem('~P~refetch enable',
    nil))));
  Insert(C1);
  Bounds.Assign(45,1,68,2);
  Insert(New(PLabel, Init(Bounds,'Disk cache',C1)));

  Bounds.Assign(3,6,43,11);
  New(C1, Init(Bounds,
    NewSItem('~D~isable correction',
    NewSItem('~E~arly correction enable',
    NewSItem('Read c~o~ntinuous',
    NewSItem('Automatic ~r~ead reallocation',
    NewSItem('~A~utomatic write reallocation',
    nil)))))));
  Insert(C1);
  Bounds.Assign(3,5,30,6);
  Insert(New(PLabel, Init(Bounds,'Error recovery',C)));

  Bounds.Assign(7,12,19,14);
  Insert(New(PButton, Init(Bounds, '~C~ancel', cmCancel, bfDefault)));

  Bounds.Assign(30,12,42,14);
  Insert(New(PButton, Init(Bounds, '~S~et', cmSetConfig, bfNormal)));

  Bounds.Assign(54,12,66,14);
  Insert(New(PButton, Init(Bounds, 'S~a~ve', cmSaveConfig, bfNormal)));

  C^.Select;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TQuantumConfigDialog.HandleEvent(var Event: TEvent);
var
  R: TRect;
begin
  if Event.What = evCommand Then
  begin
    case Event.Command of
      cmSetConfig:
        begin
         ClearEvent(Event);
          If MessageBox(#3'Do you wish to set new internal configuration? '+
                        'It will be used until reset or power off.',Nil,
               mfConfirmation+mfYesButton+mfNoButton, hcMsgBoxExit) = cmYes
            Then begin
                   EndModal(Event.Command);
                 end;
        end;
      cmSaveConfig:
        begin
          ClearEvent(Event);
          If MessageBox(#3'Do you wish to save new internal configuration? '+
                        'It still remain after power off.',Nil,
               mfConfirmation+mfYesButton+mfNoButton, hcMsgBoxExit) = cmYes
            Then begin
                   EndModal(Event.Command);
                 end;
        end;
    end;
  end;
  inherited HandleEvent(Event);
end;

begin
end.
