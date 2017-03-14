{$M 16384, $20000, $20000}
{$X+,G+,S-,R-,V-}
{*$D-,L-}

uses Crt, Dos, Drivers, Memory, Objects, Views, Menus, App, HelpFile,
     Controls, MyMsgBox, Service, XMS, Drive, Tests, IDE, ASPI,
     VGA, Graphics, AppWin, Help, Font, G_Mouse, GrowView, Quantum;

const

  cmSave          = 101;

  cmSelect        = 111;
  cmManualSelect  = 112;
  cmBench         = 121;
  cmReadGraph     = 131;
  cmWriteGraph    = 132;
  cmVerifyGraph   = 133;
  cmCacheGraph    = 134;
  cmCtrlTest      = 141;
  cmSeekTest      = 142;
  cmMediaVerify   = 143;
  cmMediaFormat   = 144;

  cmSetReadAhead  = 211;
  cmSetWriteCache = 212;
  cmSetRetries    = 213;
  cmSetECC        = 214;
  cmSetDefect     = 215;

  cmShowSMARTInfo = 221;
  cmShowAdvSMART  = 222;
  cmSetSMART      = 223;
  cmSetAutosave   = 224;
  cmSaveSMARTDump = 225;

  cmATAPIList     = 230;
  cmSCSIList      = 240;
  cmDefectList    = 241;
  cmInternalCfg   = 242;
  cmSysinfo       = 250;

  cmConfiguration = 301;

  cmAbout         = 401;
  cmContextHelp   = 402;
  cmNotDone       = 1000;

  cmOptionsVideo  = 1502;

type

  PDriveTestApp = ^TDriveTestApp;
  TDriveTestApp = Object(TApplication)
    InfoWindow  : PInfoWindow;

    DrivesList : TDrivesCollection;
    Drive      : PTestDrive;

    TestWriteSpeed : Boolean;

    constructor Init;
    destructor  Done; virtual;

    procedure   Idle; virtual;
    procedure   GetEvent(var Event: TEvent); virtual;

    procedure   HandleEvent(var Event: TEvent); virtual;
    procedure   InitMenuBar; virtual;
    procedure   InitStatusLine; virtual;
    function    GetPalette: PPalette; virtual;
    procedure   SetScreenMode(Mode: Word); virtual;

    procedure   DoAboutBox;
    procedure   Sysinfo;

    procedure   ShowDriveInfo;
    procedure   SaveResults;

    function    SelectDrive : Boolean;
    function    ManualSelectDrive : Boolean;

    procedure   Benchmarks;

    procedure   ControllerTest;
    procedure   SeekTest;
    procedure   MediaVerify;
    procedure   MediaFormat;

    procedure   ShowSMARTInfo;
    procedure   ShowAdvancedSMARTInfo;
    procedure   SaveSMARTDump;

    procedure   SetDriveFeature(Command : Word);
    procedure   ShowList(Command : Word);
    procedure   ShowDefectList;
    procedure   QuantumConfiguration;

    procedure   Configuration;
  end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
                           TDriveTestApp's Methods
 ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TDriveTestApp.Init;
var
  Sel : Byte;
  F   : File;
begin
  StartUp;
  inherited Init;
  HelpCtx := hcMainIndex;
  RegisterHelpFile;
  SetBlinking(1);

  Assign(F, 'hddspeed.ini');
  {$I-}
  Reset(F,1);
  {$I+}
  If IOResult = 0 Then
  begin
    BlockRead(F, ConfigData, SizeOf(ConfigData));
    Close(F);
  end;

  If (ScreenMode and smFont8x8 = 0) and (ConfigData.Global and optLoadFont <> 0)
    Then LoadNewFont;

  If UpCaseStr(ParamStr(1)) = '/M' Then ConfigData.Global := ConfigData.Global or optNotCheckMultitask;

  If MultiTaskPresent and (ConfigData.Global and optNotCheckMultitask = 0) Then
  begin
    MessageBox(#3'This program can''t run in multitask environment.',Nil,mfConfirmation+mfOkButton, hcMsgBoxMultitask);
    Exit;
  end;

  Drive := Nil;
  DrivesList.Init;
  SelectDrive;
  If Drive = Nil Then Exit;
  InfoWindow := New(PInfoWindow , Init(Drive));
  InsertWindow(InfoWindow);
  ShowDriveInfo;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
destructor TDriveTestApp.Done;
begin
  If Drive <> Nil Then
  begin
    Dispose(Drive, Done); Drive := Nil;
  end;
  inherited Done;
{ inherited SetScreenMode(ScreenMode); }
  SetMode(3);
  ShutDown(0);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.Idle;
const
  SCSICommandSet = [cmSave, cmBench, cmReadGraph, cmWriteGraph, cmVerifyGraph, cmCacheGraph,
                    cmCtrlTest, cmSeekTest, cmMediaVerify, cmMediaFormat];
  IDECommandSet =  [cmSetReadAhead, cmSetWriteCache, cmSetRetries, cmSetECC, cmSetDefect,
                    cmShowSMARTInfo, cmSetSMART, cmSetAutosave, cmSaveSMARTDump,
                    cmDefectList ,cmInternalCfg];
  AllCommandSet = SCSICommandSet+IDECommandSet;

var
  KbdState: Byte absolute $40:$17;
begin
  If KbdState and (kbLeftShift+kbRightShift) <> 0
  Then
    begin
      HelpCtx := $F000;
      MenuBar^.WriteStr(71,0,CurrentDateStr,1);
    end
  Else
    begin
       HelpCtx := $0000;
       MenuBar^.WriteStr(71,0,CurrentTimeStr,1);
    end;
  If InfoWindow = Nil
    Then DisableCommands(AllCommandSet)
    Else If TypeOf(Drive^) = TypeOf(TIDEDrive) Then EnableCommands(AllCommandSet)
                                               Else EnableCommands(SCSICommandSet);
  inherited Idle;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.DoAboutBox;
var
  D : PAboutDialog;
begin
  New(D, Init);
  ExecuteDialog(D, Nil);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.Sysinfo;
begin
  ExecuteDialog(New(PSysinfoDialog, Init), Nil);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.SaveResults;
type
  TSaveData = Record
    AppendFile  : Word;
    RptFile     : String[80];
  end;
const
  Data : TSaveData = (AppendFile:0; RptFile:'HddSpeed.rpt');
var
  F : Text;
  D : PSaveDialog;
begin
  If (InfoWindow = Nil) or (Drive = Nil) Then Exit;

  New(D, Init);
  If ExecuteDialog(D, @Data) = cmOk Then
  begin
    {$I-}
    Assign(F, Data.RptFile); Append(F);
    {$I+}
    IF (IOResult <> 0) or (Data.AppendFile and 1 = 0) Then
    begin
      {$I-}
      Rewrite(F);
      {$I+}
      IF IOResult <> 0 Then
      begin
        MessageBox(#3'Error: Can''t open report file', nil, mfInformation or mfOKButton, hcNoContext);
        Exit;
      end;
    end;
    InfoWindow^.SaveResults(F);
    Close(F);
    MessageBox(#3'Report file successfully saved.', nil, mfInformation or mfOKButton, hcNoContext);
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.Configuration;
var
  F : File;
  D : PConfigDialog;
  B : Boolean;
begin
  New(D, Init);
  B := ConfigData.Global and optLoadFont <> 0;
  If ExecuteDialog(D, @ConfigData) = cmOk Then
  begin
    ConfigData.Global := ConfigData.Global and (not optNotCheckMultitask);
    Assign(F, 'hddspeed.ini');
    {$I-}
    Rewrite(F,1);
    {$I+}
    If IOResult = 0 Then
    begin
      BlockWrite(F, ConfigData, SizeOf(ConfigData));
      Close(F);
    end;
    If B <> (ConfigData.Global and optLoadFont <> 0) Then
    begin
      SetScreenMode(ScreenMode);
      Redraw;
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TDriveTestApp.SelectDrive : Boolean;
var
  Data : Record
    List      : PCollection;
    Selection : Word;
  end;
  D   : PSelectDriveDialog;
  Sel : Byte;
begin
  SelectDrive := False;
  If DrivesList.Count = 0 Then
  begin
    MessageBox(#3'No hard drives found. '#13#3'Please, check configuaration!',Nil, mfInformation+mfOkButton, hcNoContext);
    Exit;
  end;

  Data.List := @DrivesList;
  Data.Selection := 0;
  If DrivesList.Count > 0 Then
  begin
     New(D, Init);
     If ExecuteDialog(D, @Data) = cmOk Then
     begin
       SelectDrive := True;
       Sel := Data.Selection+1;
       If Sel <> 0 Then
       begin
         If Drive <> Nil Then Dispose(Drive, Done);
         New(PIDEDrive(Drive), Init($7F+Sel, 0, 0));
         If PIDEDrive(Drive)^.BasePort = 0 Then
         begin
           Dispose(Drive, Done);
           New(PTestDrive(Drive), Init($7F+Sel));
         end;
       end;
     end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TDriveTestApp.ManualSelectDrive : Boolean;
type
  TManualSelectData = Record
    DrvNum    : String[5];
    Selection : Word;
  end;
var
  Data : TManualSelectData;
  D    : PManualSelectDialog;
  Sel  : Byte;
  C    : Integer;
  Port, DiskNo : Word;
begin
  ManualSelectDrive := False;
  If DrivesList.Count = 0 Then
  begin
    MessageBox(#3'No hard drives found. '#13#3'Please, check configuaration!',Nil, mfInformation+mfOkButton, hcNoContext);
    Exit;
  end;

  Data.DrvNum := '0';
  Data.Selection := 1;
  If DrivesList.Count > 0 Then
  begin
     New(D, Init);
     If ExecuteDialog(D, @Data) = cmOk Then
     begin
       ManualSelectDrive := True;
       Val(Data.DrvNum, Sel, C);
       If C = 0 Then
       begin
         Case Data.Selection of
           0 : begin Port := 0; DiskNo := 0; end;
           1 : begin Port := $1F0; DiskNo := 0; end;
           2 : begin Port := $1F0; DiskNo := 1; end;
           3 : begin Port := $170; DiskNo := 0; end;
           4 : begin Port := $170; DiskNo := 1; end;
         end;
         If Drive <> Nil Then begin Dispose(Drive, Done); Drive := Nil; end;

         If Port <> 0 Then
         begin
           New(PIDEDrive(Drive), Init($80+Sel, Port, DiskNo));
           If (Drive^.Status >= -2) and (Drive^.Status < 0) and (PIDEDrive(Drive)^.BasePort = 0) Then
           begin
             Dispose(Drive, Done); Drive := Nil;
             New(PTestDrive(Drive), Init($80+Sel));
           end;
         end
         Else New(PTestDrive(Drive), Init($80+Sel));

         If (Drive <> Nil) and (Drive^.Status >= -2) and (Drive^.Status < 0) Then
         begin
           MessageBox(#3'Specified drive not exist', nil, mfError or mfOKButton, hcNoContext);
           If Drive <> Nil Then begin Dispose(Drive, Done); Drive := Nil; end;
           ManualSelectDrive := False;
         end;
       end;
     end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.ControllerTest;
var
  Err : Boolean;
begin
  MenuBar^.Draw;
  If Drive <> Nil Then With InfoWindow^ do
  begin
    Err := False;
    WriteLine('\31\ş Reset controller: \154\Wait...');
    Drive^.ResetController;
    If Drive^.Status = 0 Then WriteLineAt(-1, '\31\ş Reset controller: \26\Ok.')
                         Else WriteLineAt(-1, '\31\ş Reset controller: \26\Failed - '+Drive^.GetErrorMessage(Drive^.Status));
    Err := Err or (Drive^.Status <> 0);

    WriteLine('\31\ş Controller diagnostic: \154\Wait...');
    Drive^.ControllerDiagnostic;
    If Drive^.Status = 0 Then WriteLineAt(-1, '\31\ş Controller diagnostic: \26\Ok.')
                         Else WriteLineAt(-1, '\31\ş Controller diagnostic: \26\Failed - '
                                            +Drive^.GetErrorMessage(Drive^.Status));
    Err := Err or (Drive^.Status <> 0);

    WriteLine('\31\ş Recalibrate drive: \154\Wait...');
    Drive^.RecalibrateDrive;
    If Drive^.Status = 0 Then WriteLineAt(-1, '\31\ş Recalibrate drive: \26\Ok.')
                         Else WriteLineAt(-1, '\31\ş Recalibrate drive: \26\Failed - '+Drive^.GetErrorMessage(Drive^.Status));
    Err := Err or (Drive^.Status <> 0);
    WriteLine('');

    If Err Then  MessageBox(#3'Controller & drive tests failed. ', nil, mfError or mfOKButton, hcNoContext)
           Else  MessageBox(#3'Controller & drive tests passed. ', nil, mfInformation or mfOKButton, hcNoContext);
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.ShowSMARTInfo;
const
  FStr       : String = '\31\%1s %-25s %-3d  %3d      %3d  %-22s  \31\%4s    %-8s';
  HeaderLine : String = '\30\  Attribute                 ID Threshold Value Indicator  1/Month   T.E.C.';
  OkStr : Array [Boolean] of String[12] = ('\28\Mismatch','\26\Ok');
  CritChar : Array [Boolean] of Char = (' ','*');
  CritStr  : Array [Boolean] of String[4] = ('Not ','');
  OneMonth = 2097152;

var
  Ok, TEC, CriticalTEC : Boolean;
  Sum : Byte;
  i, j, L  : Word;
  FRec : Record
    Crit : PString;
    Attr : PString;
    ID,
    Thresh,
    Val  : LongInt;
    Ind  : PString;
    Chg  : PString;
    TEC  : PString;
  end;
  Attribute, Critical, Indicator, ChangeStr, TecDateStr, S : String;
  TotalChange : Integer;
  ChangeSpeed : Real;
  ElapsedTime : Real;
  TECDate,
  NearestTEC  : LongInt;
  NearestTECAttr : Byte;
  LI : LongInt;

begin
  MenuBar^.Draw;
  With InfoWindow^ do
  begin
    If (Drive <> Nil) and (TypeOf(Drive^) = TypeOf(TIDEDrive)) Then
    With PIDEDrive(Drive)^ do
    begin
      Ok := GetSMARTInfo;
      If not Ok Then
      begin
        WriteLine('\31\ş Get S.M.A.R.T. Info: \28\Failed.');
        Exit;
      end;
      WriteLine('ş Thresholds structure revision: \26\'+IntToStr(SMARTThresholds.Revision));
      WriteLine('ş Values structure revision: \26\'+IntToStr(SMARTValues.Revision));
      Sum := CalcCheckSum(SMARTThresholds,511);
      WriteLine('ş Thresholds checksum: '+OkStr[SMARTThresholds.CheckSum=Sum]+
                 '\23\ (Reported='+ByteToHexStr(SMARTThresholds.CheckSum)+'h, Calculated='+ByteToHexStr(Sum)+'h)');
      Sum := CalcCheckSum(SMARTValues,511);
      WriteLine('ş Values checksum: '+OkStr[SMARTValues.CheckSum=Sum]+
                 '\23\ (Reported='+ByteToHexStr(SMARTValues.CheckSum)+'h, Calculated='+ByteToHexStr(Sum)+'h)');
      WriteLine('ş Capability:');
      WriteLine('   [\31\'+CheckBox[SMARTValues.Capability and 1 <> 0]+'\23\] Pre-power mode attributes autosave');
      WriteLine('   [\31\'+CheckBox[SMARTValues.Capability and 2 <> 0]+'\23\] Attributes autosave after event');

      If ConfigData.Global and optSMARTPrediction <> 0 Then
      begin
        UpdateSMARTBase;
        WriteLine('ş T.E.C. prediction monitoring started at: '+GetDateTimeStr(SMARTMonitorRec.StartDate));
      end;

      WriteLine('');
      WriteLine(HeaderLine);
      WriteLine('\30\'+Separator(''));

      TEC := False; CriticalTEC := False; NearestTEC := MaxLongInt; NearestTECAttr := 0;
      for i := 1 to 30 do
       If SMARTThresholds.Thresholds[i].AttributeID <> 0 Then
       begin
         FRec.ID := SMARTThresholds.Thresholds[i].AttributeID;
         FRec.Thresh := SMARTThresholds.Thresholds[i].AttributeThreshold;

         j := 0;
         Repeat
           Inc(j);
         Until (SMARTvalues.Values[j].AttributeID = FRec.ID) or (j = 30);

         If SMARTThresholds.Thresholds[i].AttributeID = SMARTvalues.Values[j].AttributeID Then
         begin
           Critical := CritChar[(SMARTValues.Values[j].StatusFlags and 1) <> 0];
           FRec.Crit := @Critical;

           Attribute := GetSMARTAttrMeaning(i);
           FRec.Attr := @Attribute;
           FRec.Val := SMARTValues.Values[j].AttributeValue;

           IF FRec.Val < FRec.Thresh Then
           begin
             TEC := True;
             If (SMARTValues.Values[j].StatusFlags and 1) <> 0 Then CriticalTEC := True;
           end;

           Indicator := '\28\ş\30\şş\26\şşşşşşş';
           L := 0; j := 1;
           for j := 1 to Length(Indicator) do
           begin
             If (Indicator[j] = 'ş') Then
             begin
               Inc(L);
               If (L > Round(FRec.Val/(Max(100,FRec.Val) div 10))) Then Indicator[j] := ' ';
             end;
           end;

           FRec.Ind := @Indicator;
           FRec.Chg := @ChangeStr;
           FRec.TEC := @TECDateStr;

           TECDate := MaxLongInt; ChangeSpeed := 0;
           TotalChange := SMARTMonitorRec.StartValues.Values[i].AttributeValue-FRec.Val;
           If (ConfigData.Global and optSMARTPrediction <> 0) and (TotalChange > 0) Then
           begin
             ElapsedTime := MonthBetween(SMARTMonitorRec.StartDate, GetCurrentPackedDateTime);
             If ElapsedTime <> 0 Then
             begin
               ChangeSpeed := TotalChange/ElapsedTime;
               If ChangeSpeed <> 0 Then
               begin
                 TECDate := AddMonth(GetCurrentPackedDateTime, (Frec.Val-FRec.Thresh)/ChangeSpeed);
                 If TECDate < NearestTEC Then
                 begin
                   NearestTEC := TECDate;
                   NearestTECAttr := i;
                 end;
               end;
             end;
           end;
           ChangeStr := RealToStr(ChangeSpeed);
           If FRec.Val < FRec.Thresh
             Then TECDateStr := '  Yes'
             Else
              If TECDate < MaxLongInt Then TECDateStr := GetYearAndMonthStr(TECDate)
                                      Else TECDateStr := 'Unknown';

             FormatStr(S, FStr, FRec);
             WriteLine(S);
           end;
         end;
       WriteLine('\30\'+Separator(''));
       WriteLine('NOTE: "*" means life-critical attribute');
       WriteLine('');
       If TEC
         Then If CriticalTEC Then WriteLine('\156\! T.E.C. detected with life-critical attribute!')
                             Else WriteLine('\28\! T.E.C. detected with not critical attribute.')
         Else begin
           WriteLine('\31\ş T.E.C. not detected.');
           If NearestTEC < MaxLongInt Then
           begin
             WriteLine('ş Nearest prognosed T.E.C.: '+GetYearAndMonthStr(NearestTEC)+', '+GetSMARTAttrMeaning(NearestTECAttr)+
                       +' ('+CritStr[(SMARTValues.Values[NearestTECAttr].StatusFlags and 1) <> 0]+'Critical)');
           end;
         end;
       WriteLine('');
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.ShowAdvancedSMARTInfo;
const
  FStr       : String = '\31\%1s %-25s %-3d  %3d      %3d   %3d  %12sh %s';
  HeaderLine : String = '\30\  Attribute                 ID Threshold Value Worst Raw            Type';
  OkStr : Array [Boolean] of String[12] = ('\28\Mismatch','\26\Ok');
  CritChar : Array [Boolean] of Char = (' ','*');
  CritStr  : Array [Boolean] of String[4] = ('Not ','');
  OneMonth = 2097152;

var
  Ok, TEC, CriticalTEC : Boolean;
  Sum : Byte;
  i, j, k, L  : Word;
  FRec : Record
    Crit   : PString;
    Attr   : PString;
    ID,
    Thresh,
    Val    : LongInt;
    Worst  : LongInt;
    Raw    : PString;
    Rel    : PString;
  end;
  Attribute, Critical, Raw, Related, S : String;

begin
  MenuBar^.Draw;
  With InfoWindow^ do
  begin
    If (Drive <> Nil) and (TypeOf(Drive^) = TypeOf(TIDEDrive)) Then
    With PIDEDrive(Drive)^ do
    begin
      Ok := GetSMARTInfo;
      If not Ok Then
      begin
        WriteLine('\31\ş Get S.M.A.R.T. Info: \28\Failed.');
        Exit;
      end;
      WriteLine('ş Thresholds structure revision: \26\'+IntToStr(SMARTThresholds.Revision));
      WriteLine('ş Values structure revision: \26\'+IntToStr(SMARTValues.Revision));
      Sum := CalcCheckSum(SMARTThresholds,511);
      WriteLine('ş Thresholds checksum: '+OkStr[SMARTThresholds.CheckSum=Sum]+
                 '\23\ (Reported='+ByteToHexStr(SMARTThresholds.CheckSum)+'h, Calculated='+ByteToHexStr(Sum)+'h)');
      Sum := CalcCheckSum(SMARTValues,511);
      WriteLine('ş Values checksum: '+OkStr[SMARTValues.CheckSum=Sum]+
                 '\23\ (Reported='+ByteToHexStr(SMARTValues.CheckSum)+'h, Calculated='+ByteToHexStr(Sum)+'h)');
      WriteLine('ş Capability:');
      WriteLine('   [\31\'+CheckBox[SMARTValues.Capability and 1 <> 0]+'\23\] Pre-power mode attributes autosave');
      WriteLine('   [\31\'+CheckBox[SMARTValues.Capability and 2 <> 0]+'\23\] Attributes autosave after event');

      If ConfigData.Global and optSMARTPrediction <> 0 Then
      begin
        UpdateSMARTBase;
        WriteLine('ş T.E.C. prediction monitoring started at: '+GetDateTimeStr(SMARTMonitorRec.StartDate));
      end;

      WriteLine('');
      WriteLine(HeaderLine);
      WriteLine('\30\'+Separator(''));

      TEC := False; CriticalTEC := False;
      for i := 1 to 30 do
       If SMARTThresholds.Thresholds[i].AttributeID <> 0 Then
       begin
         FRec.ID := SMARTThresholds.Thresholds[i].AttributeID;
         FRec.Thresh := SMARTThresholds.Thresholds[i].AttributeThreshold;

         j := 0;
         Repeat
           Inc(j);
         Until (SMARTvalues.Values[j].AttributeID = FRec.ID) or (j = 30);

         If SMARTThresholds.Thresholds[i].AttributeID = SMARTvalues.Values[j].AttributeID Then
         begin
           Critical := CritChar[(SMARTValues.Values[j].StatusFlags and sfCritical) <> 0];
           FRec.Crit := @Critical;

           Attribute := GetSMARTAttrMeaning(i);
           FRec.Attr := @Attribute;
           FRec.Val := SMARTValues.Values[j].AttributeValue;

           FRec.Worst := SMARTValues.Values[i].WorstValue;
           Raw := '';
           for k := 1 to 6 do
             Raw := ByteToHexStr(SMARTValues.Values[i].Raw[k])+Raw;
           FRec.Raw := @Raw;
           Related := '';
           With SMARTValues.Values[i] do
           begin
             If StatusFlags and sfPerformance <> 0 Then Related := Related+' PR';
             If StatusFlags and sfErrorRate <> 0 Then Related := Related+' ER';
             If StatusFlags and sfEventCount <> 0 Then Related := Related+' EC';
             If StatusFlags and sfSelfPreserve <> 0 Then Related := Related+' SP';
           end;
           FRec.Rel := @Related;

           FormatStr(S, FStr, FRec);
           WriteLine(S);
         end;
       end;
       WriteLine('\30\'+Separator(''));
       WriteLine('NOTE: "*" means life-critical attribute');
       WriteLine('Attribute types:');
       WriteLine('      PR - Performance-related         ER - Error rate');
       WriteLine('      EC - Events count                SP - Self-preserve');
       WriteLine('');
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.SaveSMARTDump;
var
  F : File;
begin
  If (Drive <> Nil) and (TypeOf(Drive^) = TypeOf(TIDEDrive)) Then
  With PIDEDrive(Drive)^ do
  begin
    If not GetSMARTInfo Then
    begin
      MessageBox(#3'Getting S.M.A.R.T. attributes failed. ', nil, mfError or mfOKButton, hcNoContext);
      Exit;
    end;

    Assign(F,'thresh.dat'); Rewrite(F,1);
    BlockWrite(F,SMARTThresholds, SizeOf(SMARTThresholds));
    System.Close(F);
    Assign(F,'values.dat'); Rewrite(F,1);
    BlockWrite(F,SMARTValues, SizeOf(SMARTValues));
    System.Close(F);

    MessageBox(#3'S.M.A.R.T. attributes successfully saved to file.', nil, mfInformation or mfOKButton, hcNoContext);
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.SeekTest;
var
  Err : Boolean;
  S   : String;
  I   : Word;
  D   : PProgressDialog;
  GV2 : PGrowView;
begin
  MenuBar^.Draw;
  If Drive <> Nil Then With InfoWindow^ do
  begin
    Err := False;

    New(D, Init(Drive^.GV, GV2, 'Seek tests'));
    Desktop^.Insert(D);

    GV2^.Update(0);
    D^.SetCurrentText('Sequental seek test');
    WriteLine('\31\ş Sequental seek test: \154\Wait...');
    Drive^.ResetStatus;
    SkipTest := False;
    I := 0;
    Drive^.GV^.Update(0);
    Repeat
      Drive^.SeekToTrack(I);
      Inc(I);
      Drive^.GV^.Update(Round(i/Drive^.Tracks*50));
    Until (I = Drive^.Tracks-1) or SkipTest or (Drive^.LastError <> 0);
    Draw;
    Repeat
      Dec(I);
      Drive^.SeekToTrack(I);
      Drive^.GV^.Update(Round((Drive^.Tracks*2-i)/Drive^.Tracks*50));
    Until (I = 0) or SkipTest or (Drive^.LastError <> 0);
    Drive^.GV^.Update(100);
    If SkipTest
      Then S := 'Aborted'
      Else If Drive^.Status = 0 Then S := 'Ok.'
                                Else S := 'Failed - '+Drive^.GetErrorMessage(Drive^.LastError);
    WriteLineAt(-1, '\31\ş Sequental seek test: \26\'+S);
    Err := Err or (Drive^.LastError <> 0);
    Draw;

    GV2^.Update(33);
    Drive^.GV^.Update(0);
    D^.SetCurrentText('Funnel seek test');
    WriteLine('\31\ş Funnel seek test: \154\Wait...');
    Drive^.ResetStatus;
    SkipTest := False;
    I := 0;
    Repeat
      Drive^.SeekToTrack(I);
      Drive^.SeekToTrack(Drive^.Tracks-1-I);
      Inc(I);
      Drive^.GV^.Update(Round(i/Drive^.Tracks*100));
    Until (I = Drive^.Tracks-1) or SkipTest or (Drive^.LastError <> 0);
    If SkipTest
      Then S := 'Aborted'
      Else If Drive^.Status = 0 Then S := 'Ok.'
                                Else S := 'Failed - '+Drive^.GetErrorMessage(Drive^.LastError);
    WriteLineAt(-1, '\31\ş Funnel seek test: \26\'+S);
    Err := Err or (Drive^.LastError <> 0);
    Drive^.GV^.Update(100);
    Draw;

    GV2^.Update(66);
    Drive^.GV^.Update(0);
    D^.SetCurrentText('Random seek test');
    WriteLine('\31\ş Random seek test: \154\Wait...');
    Drive^.ResetStatus;
    SkipTest := False;
    I := 0;
    Repeat
      Drive^.SeekToTrack(Random(Drive^.Tracks));
      Inc(I);
      If i mod 100 = 0 Then Drive^.GV^.Update(Round(i/10));
    Until (I = 1000) or SkipTest or (Drive^.LastError <> 0);
    If SkipTest
      Then S := 'Aborted'
      Else If Drive^.Status = 0 Then S := 'Ok.'
                                Else S := 'Failed - '+Drive^.GetErrorMessage(Drive^.LastError);
    WriteLineAt(-1, '\31\ş Random seek test: \26\'+S);
    Err := Err or (Drive^.LastError <> 0);
    GV2^.Update(100);
    Drive^.GV^.Update(100);
    Draw;

    WriteLine('');
    Dispose(D, Done);
    While KeyPressed do ReadKey;
    If Err Then  MessageBox(#3'Seek tests failed. ', nil, mfError or mfOKButton, hcNoContext)
           Else  MessageBox(#3'Seek tests passed. ', nil, mfInformation or mfOKButton, hcNoContext);
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.MediaVerify;
type
  TSaveData = Record
    TestOptions : Word;
    FirstCyl    : String[4];
    LastCyl     : String[4];
    Count       : String[4];
  end;

const
  optRepair  = $01;
  optSaveLog = $02;

  Data : TSaveData = (TestOptions: optSaveLog; FirstCyl: ''; LastCyl: ''; Count: '');

  HeaderLine : String = '\30\ Cyl/Head/Sec Error code                                       Status';
  FStrOk     : String = '\23\ %04d/%03d/%02d  %02xh - %-42s \26\%-20s';
  FStrBad    : String = '\31\ %04d/%03d/%02d  %02xh - %-42s \28\%-20s';
  RecStatus  : Array [-2..1] of String[20] =
  ('\154\Analysing...', '\154\Recovering...', 'Not Recovered', 'Recovered');
var
  I, J, K, St,
  ErrorsCount,
  RecoveredCount    : LongInt;
  RecoveryStatus    : Integer;
  D                 : PProgressDialog;
  GV2               : PGrowView;
  F                 : Text;
  StartTime         : LongInt;
  ElapsedTime       : LongInt;
  FirstTime         : Boolean;
  TrackMapBefore,
  TrackMapAfter     : TTrackMap;
  FirstCyl          : Word;
  LastCyl           : Word;
  Code              : Integer;
  TestsCount        : Integer;
  CurrentPercents   : Real;
  TotalPercents     : Real;
  Pass              : Integer;

  function  GetErrorInfo(Track : Word; Head, Sector : Byte; ErrorCode, RecoveryCode : Integer) : String;
  var
    FRec : Record
      C, H, S : LongInt;
      Err     : LongInt;
      ErrMess : PString;
      RecMess : PString;
    end;
    Str, ErrorMessage, RecoveryMessage : String[100];
  begin
    ErrorMessage := Drive^.GetErrorMessage(ErrorCode);
    RecoveryMessage := RecStatus[RecoveryCode];
    With FRec do begin
     C := Track; H := Head; S := Sector;
     Err := ErrorCode; ErrMess := @ErrorMessage;
     RecMess := @RecoveryMessage;
    end;
    If RecoveryCode <> 1 Then FormatStr(Str, FStrBad, FRec)
                         Else FormatStr(Str, FStrOk, FRec);
    GetErrorInfo := Str;
  end;

begin
  MenuBar^.Draw;
  If Drive <> Nil Then With InfoWindow^ do
  begin
    Data.FirstCyl := IntToStr(0);
    Data.LastCyl := IntToStr(Drive^.Tracks-1);
    Data.Count := IntToStr(1);

    If ExecuteDialog(New(PMediaVerifyDialog, Init(Drive^.Tracks-1)), @Data) = cmOk Then
    begin

      If Data.TestOptions and optSaveLog <> 0 Then
      begin
        Assign(F, 'surface.log'); Rewrite(F);
      end;

      Val(Data.FirstCyl, FirstCyl, Code);
      If not FirstCyl in [0..Drive^.Tracks-1] Then FirstCyl := 0;
      Val(Data.LastCyl, LastCyl, Code);
      If not LastCyl in [FirstCyl..Drive^.Tracks-1] Then LastCyl := Drive^.Tracks-1;
      Val(Data.Count, TestsCount, Code);

      New(D, Init(Drive^.GV, GV2, 'Media test'));
      Desktop^.Insert(D);
      D^.SetCurrentText('Verifycation');
      WriteLine('\31\ş Media verify test in progress...');

      Drive^.ResetStatus;
      SkipTest := False;
      StartTime := GetTime100;
      for Pass := 1 to TestsCount do
        With Drive^ do
        begin
          If SkipTest Then Break;
          ResetStatus;
          SkipTest := False; FirstTime := True;
          I := FirstCyl; ErrorsCount := 0; RecoveredCount := 0;
          Repeat
            D^.SetCurrentText('Verifying: Track '+IntToStr(i));

            for J := 0 to Heads-1 do
            begin
              If SkipTest Then Break;
              VerifySectors(I, J, 1, Drive^.Sectors);

              If Status <> 0 Then
              begin
                St := Status;
                If FirstTime Then
                begin
                  FirstTime := False;
                  LogWriteLineAt(-1, '\30\'+Separator(''), F);
                  LogWriteLine(HeaderLine, F);
                  LogWriteLine('\30\'+Separator(''), F);
                end;

                D^.SetCurrentText('Analysing bad track');
                WriteLine(GetErrorInfo(I, J, 0, St, -2));
                If DetailedVerifyTrack(I, J, TrackMapBefore) <> 0 Then
                begin
                  TrackMapAfter := TrackMapBefore;

                  If Data.TestOptions and optRepair <> 0 Then
                  begin
                    D^.SetCurrentText('Recovering bad track');
                    WriteLineAt(-1, GetErrorInfo(I, J, 0, St, -1));
                    RecoverTrack(I, J, TrackMapAfter);
                    DetailedVerifyTrack(I, J, TrackMapAfter);
                  end;

                  Dec(ScreenText^.LinesCount);

                  for k := 1 to Sectors do
                  begin
                    If (TrackMapBefore[k].Flag <> 0) or (TrackMapAfter[k].Flag <> 0) Then
                    begin
                      Inc(ErrorsCount);
                      If TrackMapAfter[k].Flag <> 0
                        Then LogWriteLine(GetErrorInfo(I, J, k, TrackMapBefore[k].Flag, 0), F)
                        Else begin
                                LogWriteLine(GetErrorInfo(I, J, k, TrackMapBefore[k].Flag, 1), F);
                                Inc(RecoveredCount);
                             end;
                    end;
                  end;
                end;
              end;

              ResetStatus;
            end;
            Inc(I);
            CurrentPercents := (i-FirstCyl+1)/(LastCyl-FirstCyl+1);
            TotalPercents := (Pass-1+CurrentPercents)/TestsCount;
            Drive^.GV^.Update(Round(100*CurrentPercents));
            GV2^.Update(Round(100*TotalPercents));
            ElapsedTime := GetTime100-StartTime;
            D^.SetTotalText('Time left: '+Time100ToStr(Round((1/TotalPercents-1)*ElapsedTime)));
          Until (I > LastCyl) or SkipTest;
        end;

      Dispose(D, Done);
      If ErrorsCount > 0 Then
      begin
        LogWriteLine('\30\'+Separator(''), F);
        LogWriteLine('\31\ Bad sectors: \27\'+IntToStr(ErrorsCount)+'\23\ ('+IntToStr(ErrorsCount div 2)+'Kb), '+
                  '\31\Recovered: \27\'+IntToStr(RecoveredCount)+'\23\ ('+IntToStr(RecoveredCount div 2)+'Kb, '
                  +IntToStr(Round(100*RecoveredCount/ErrorsCount))+'%)', F);
      end
      Else LogWriteLine('\31\ş Media verify test finished. No errors found.', F);
      WriteLine('');

      If Data.TestOptions and optSaveLog <> 0 Then
      begin
        {$I-}
        System.Close(F);
        {$I+}
        IF IOResult <> 0 Then;
      end;

      Draw;
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.MediaFormat;
type
  TSaveData = Record
    TestOptions : Word;
    FirstCyl    : String[4];
    LastCyl     : String[4];
  end;

const
  optUnassign  = $01;

  Data : TSaveData = (TestOptions: 0; FirstCyl: ''; LastCyl: '');

var
  I, J, K, St,
  ErrorsCount,
  RecoveredCount    : LongInt;
  RecoveryStatus    : Integer;
  D                 : PProgressDialog;
  GV2               : PGrowView;
  F                 : Text;
  StartTime         : LongInt;
  ElapsedTime       : LongInt;
  FirstTime         : Boolean;
  TrackMap          : TTrackMap;
  FirstCyl          : Word;
  LastCyl           : Word;
  Code              : Integer;
  CurrentPercents   : Real;

begin
  MenuBar^.Draw;
  If Drive <> Nil Then With InfoWindow^ do
  begin
    Data.FirstCyl := IntToStr(0);
    Data.LastCyl := IntToStr(Drive^.Tracks-1);

    If ExecuteDialog(New(PFormatDialog, Init(Drive^.Tracks-1)), @Data) = cmOk Then
    begin

      Val(Data.FirstCyl, FirstCyl, Code);
      If not FirstCyl in [0..Drive^.Tracks-1] Then FirstCyl := 0;
      Val(Data.LastCyl, LastCyl, Code);
      If not LastCyl in [FirstCyl..Drive^.Tracks-1] Then LastCyl := Drive^.Tracks-1;

      New(D, Init(Drive^.GV, GV2, 'Media format'));
      Desktop^.Insert(D);
      D^.SetCurrentText('Formatting');

      With Drive^ do
      begin
        ResetStatus;
        SkipTest := False; FirstTime := True;
        I := FirstCyl; ErrorsCount := 0; RecoveredCount := 0;
        StartTime := GetTime100;
        Repeat
          D^.SetCurrentText('Formatting: Track '+IntToStr(i));

          for J := 0 to Heads-1 do
          begin

            If SkipTest Then Break;

            for k := 1 to Sectors do
              With TrackMap[k] do
              begin
                No   := k;
                If (Data.TestOptions and optUnassign) <> 0
                  Then Flag := $20
                  Else Flag := 0;
              end;

            FormatTrack(I, J, @TrackMap);
            ResetStatus;
          end;
          Inc(I);

          CurrentPercents := (i-FirstCyl+1)/(LastCyl-FirstCyl+1);
          Drive^.GV^.Update(Round(100*CurrentPercents));
          GV2^.Update(Round(100*CurrentPercents));
          ElapsedTime := GetTime100-StartTime;
          D^.SetTotalText('Time left: '+Time100ToStr(Round((1/CurrentPercents-1)*ElapsedTime)));
        Until (I > LastCyl) or SkipTest;
      end;

      Dispose(D, Done);

      Draw;
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TDriveTestApp.ShowDriveInfo;
const
  SMARTStatus : Array [-1..1] of String[45] =
  ('', '(Status: \26\Ok\23\)','(Status: \28\Threshold exceeded!\23\)');
var
  I : Integer;
  S : String;
begin
  MenuBar^.Draw;
  If Drive <> Nil Then With InfoWindow^ do
  begin
    WriteLine('ş Hard Disk '+IntToStr(Drive^.BIOSDriveNumber-$80)+': \30\'+Drive^.GetType);
    If TypeOf(Drive^) <> TypeOf(TIDEDrive) Then
      With PTestDrive(Drive)^ do
      begin
        WriteLine('ş Size:');
        WriteLine('   '+#4+' BIOS: \27\'+IntToStr(Drive^.GetSize)+' MBytes');

        WriteLine('ş Geometry:');
        WriteLine('   '+#4+' BIOS: \31\'+IntToStr(Tracks)+' \23\Cylinders, \31\'+IntToStr(Heads)+' \23\Heads, \31\'+
                       +IntToStr(Sectors)+' \23\Sectors ');

        If ConfigData.Benchmarks and optRPM <> 0 Then
        begin
           WriteLine('ş Disk Rotation Speed: \154\Testing...');
           RPM := Drive^.GetRPM(0);
           If SkipTest
             Then WriteLineAt(-1, 'ş Disk Rotation Speed: \26\Not Tested')
             Else If (RPM > 3000) and (RPM < 10000)
                    Then WriteLineAt(-1, 'ş Disk Rotation Speed: \26\'+IntToStr(Round(RPM/100))+'00 RPM')
                    Else WriteLineAt(-1, 'ş Disk Rotation Speed: \26\Not Determined');
        end;
      end
    Else
      With PIDEDrive(Drive)^ do
      begin
        WriteLine('ş Model: \27\'+GetModel+
                  '\23\      Compatibility: \27\'+GetStandardCompatibility);
        WriteLine('ş Serial Number: '+IDEInfo.Serial+' Firmware Revision: '+IDEInfo.Revision);
        WriteLine('ş Size:');
        WriteLine('   '+#4+' BIOS: \27\'+IntToStr(GetSize)+' MBytes');
        WriteLine('   '+#4+' IDE Default: \27\'+IntToStr(GetIDEDefaultSize)+' MBytes');

        If ((IDEInfo.ExtValid and 2) <> 0)and(IDEInfo.Cyls <> IDEInfo.CurrCyls) Then
          WriteLine('   '+#4+' IDE Current: \27\'+IntToStr(GetIDECurrentSize)+' MBytes');

        WriteLine('ş Geometry:');
        WriteLine('   '+#4+' BIOS: \31\'+IntToStr(Tracks)+' \23\Cylinders, \31\'+IntToStr(Heads)+' \23\Heads, \31\'+
                        IntToStr(Sectors)+' \23\Sectors, '+
                      'Using \26\'+DriveMode[DiskMode]+' translation');
        WriteLine('   '+#4+' IDE Default: \31\'+IntToStr(IDEInfo.Cyls)+' \23\Cylinders, \31\'+
                        IntToStr(IDEInfo.Heads)+' \23\Heads, \31\'+
                        IntToStr(IDEInfo.SPT)+' \23\Sectors');

        If ((IDEInfo.ExtValid and 2) <> 0) and (IDEInfo.Cyls <> IDEInfo.CurrCyls) Then
          WriteLine('   '+#4+' IDE Current: \31\'+IntToStr(IDEInfo.CurrCyls)+' \23\Cylinders, \31\'+
                          IntToStr(IDEInfo.CurrHeads)+' \23\Heads, \31\'+
                          IntToStr(IDEInfo.CurrSect)+' \23\Sectors');

        WriteLine('ş Supported Features:');
        DetectFeatures;
        WriteLine('   [\31\'+CheckBox[IsDMA]+'\23\] DMA Transfer');
        WriteLine('   [\31\'+CheckBox[IsLBA]+'\23\] LBA');

        S := '   [\31\'+CheckBox[IsBlockMode]+'\23\] Block Mode';
        If IsBlockMode
          Then S := S+' (Max='+IntToStr(IDEInfo.Features and $00FF)+',Current='+IntToStr(IDEInfo.BlockMode and $00FF)+')';
        WriteLine(S);
        WriteLine('   [\31\'+CheckBox[IsPowerManagement]+'\23\] Power Management');

        S := '   [\31\'+CheckBox[IsSMART]+'\23\] S.M.A.R.T.';
        If IsSMART Then S := S+' '+SMARTStatus[GetSMARTStatus];
        WriteLine(S);

        WriteLine('   [\31\'+CheckBox[IDEInfo.CommandSupp and $0400 <> 0]+'\23\] Host Protected Area ');

        WriteLine('ş Maximal Supported Modes: \27\'+GetMaxModes);

        If IDEInfo.BufSize <> 0 Then
        begin
          WriteLine('ş Buffer: Type '+IntToStr(IDEInfo.BufType)+' ('+BufTypeStr[IDEInfo.BufType]+')');
          WriteLine('   '+#4+' IDE Size: \27\'+IntToStr(IDEInfo.BufSize shr 1)+' Kb');
        end;

        If ConfigData.Benchmarks and optBufferSize <> 0 Then
        begin
          If IDEInfo.BufSize = 0 Then WriteLine('ş Buffer:');
          CancelTests := False;
          WriteLine('   '+#4+' Effective Size: \154\Testing...');
          Drive^.GetEffectiveBufferSize;
          If SkipTest
            Then WriteLineAt(-1, '   '+#4+' Effective Size: \26\Not Tested')
            Else If EffectiveBufferSize >= IDEInfo.BufSize shr 2
                   Then WriteLineAt(-1, '   '+#4+' Effective Size: \26\'+IntToStr(EffectiveBufferSize)+' Kb')
                   Else WriteLineAt(-1, '   '+#4+' Effective Size: \26\Not Determined');
        end;

        If ConfigData.Benchmarks and optRPM <> 0 Then
        begin
          WriteLine('ş Disk Rotation Speed: \154\Testing...');
          RPM := Drive^.GetRPM(ConfigData.RPMMethod);
          If SkipTest
            Then WriteLineAt(-1, 'ş Disk Rotation Speed: \26\Not Tested')
            Else If (RPM > 3000) and (RPM < 10000)
                   Then WriteLineAt(-1, 'ş Disk Rotation Speed: \26\'+IntToStr(Round(RPM/100))+'00 RPM')
                   Else WriteLineAt(-1, 'ş Disk Rotation Speed: \26\Not Determined');
          end;
      end;

      WriteLine('');
  end;
  While KeyPressed do ReadKey;
  If MessageBox(#3'Run speed benchmarks for this drive?',Nil,mfConfirmation+mfYesButton+mfNoButton, hcNoContext) = cmYes
    Then Benchmarks;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.Benchmarks;
const
   TestStr : Array [1..10] of String[50] =
   (
    'ş Average Seek Time: %s',
    'ş Maximal Seek Time: %s',
    'ş Track-To-Track Seek Time: %s',
    '\31\ş Average Access Time: %s',
    'ş Linear Speed At Track %4d:   %-20s   %-20s',
    '\31\ş Average Linear Speed:         %-20s   %-20s',
    'ş Min. Linear Speed:            %-20s   %-20s',
    'ş Max. Linear Speed:            %-20s   %-20s',
    'ş Max. Cache Read Speed: %s',
    'ş Random Read Speed: %s'
   );
   msgTesting   : String[20] = '\154\Testing...';
   msgNotTested : String[20] = '\026\Not Tested';
   msgNotDetermined : String[20] = '\026\Not Determined';
var
  RSpeed, WSpeed, RSpeed0, WSpeed0, RSpeedLast, WSpeedLast : LongInt;
  FormatRec : Record
                PS  : PString;
                PS2 : PString;
              end;
  TrkFormatRec : Record
                   Track : LongInt;
                   RS, WS : PString;
                 end;
  S, S1, S2 : String;
  D         : PProgressDialog;
  GV2       : PGrowView;

  function GetFormattedString(FStr, Msg1, Msg2 : String) : String;
  begin
    FormatRec.PS := @Msg1;
    FormatRec.PS2 := @Msg2;
    FormatStr(S, FStr, FormatRec);
    GetFormattedString := S;
  end;

  function GetTrkFormattedString(FStr : String; Track : LongInt; Msg1, Msg2 : String) : String;
  begin
    TrkFormatRec.Track := track;
    TrkFormatRec.RS := @Msg1;
    TrkFormatRec.WS := @Msg2;
    FormatStr(S, FStr, TrkFormatRec);
    GetTrkFormattedString := S;
  end;

begin
   MenuBar^.Draw;
  If (Drive <> Nil) and (InfoWindow <> Nil) Then
    With InfoWindow^ do
    begin
      CancelTests := False;
      Becnhmarked := True;

      If (TypeOf(Drive^) = TypeOf(TIDEDrive)) and
         (PIDEDrive(Drive)^.GetIDEDefaultSize-PIDEDrive(Drive)^.GetSize > 20)
      Then begin
        WriteLine('          \28\ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
        WriteLine('          \28\º Warning! The following tests results are not correct.º');
        WriteLine('          \28\º       You must test this drive in mode with          º');
        WriteLine('          \28\º              BIOS access to all tracks.              º');
        WriteLine('          \28\ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼');
        WriteLine('');
      end;

      New(D, Init(Drive^.GV, GV2, 'Benchmarks'));
      Desktop^.Insert(D);

      If ConfigData.Benchmarks and optAvgSeek <> 0 Then
      begin
        {Average Seek}
        D^.SetCurrentText('Average seek test');
        WriteLine(GetFormattedString(TestStr[1], msgTesting, ''));
        Drive^.GetAverageSeekTime;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[1], msgNotTested, ''))
          Else If Drive^.AverageSeekTime > 1
                 Then WriteLineAt(-1, GetFormattedString(TestStr[1], '\26\'+RealToStr(Drive^.AverageSeekTime)+' ms', ''))
                 Else WriteLineAt(-1, GetFormattedString(TestStr[1], msgNotDetermined, ''));



        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If ConfigData.Benchmarks and optMaxSeek <> 0 Then
      begin
        {Max Seek}
        GV2^.Update(12);
        D^.SetCurrentText('Max. seek test');
        WriteLine(GetFormattedString(TestStr[2], msgTesting, ''));
        Drive^.GetMaxSeekTime;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[2], msgNotTested, ''))
          Else If Drive^.MaxSeekTime > 1
                 Then WriteLineAt(-1, GetFormattedString(TestStr[2], '\26\'+RealToStr(Drive^.MaxSeekTime)+' ms', ''))
                 Else WriteLineAt(-1, GetFormattedString(TestStr[1], msgNotDetermined, ''));
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If ConfigData.Benchmarks and optTTTSeek <> 0 Then
      begin
        GV2^.Update(25);
        D^.SetCurrentText('Track-to-track seek test');
        {Track-To-Track Seek}
        WriteLine(GetFormattedString(TestStr[3], msgTesting, ''));
        Drive^.GetTrackToTrackSeekTime;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[3], msgNotTested, ''))
          Else If Drive^.TrackToTrackSeekTime > 1
                 Then WriteLineAt(-1, GetFormattedString(TestStr[3], '\26\'+RealToStr(Drive^.TrackToTrackSeekTime)+' ms', ''))
                 Else WriteLineAt(-1, GetFormattedString(TestStr[3], msgNotDetermined, ''));
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If ConfigData.Benchmarks and optAvgAccess <> 0 Then
      begin
        GV2^.Update(37);
        D^.SetCurrentText('Average Access Test');
        {Average Access}
        WriteLine(GetFormattedString(TestStr[4], msgTesting, ''));
        Drive^.GetAverageAccessTime;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[4], msgNotTested, ''))
          Else If Drive^.AverageAccessTime > 1
                 Then WriteLineAt(-1, GetFormattedString(TestStr[4], '\26\'+RealToStr(Drive^.AverageAccessTime)+' ms', ''))
                 Else WriteLineAt(-1, GetFormattedString(TestStr[4], msgNotDetermined, ''));
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If (ConfigData.Benchmarks and (optTrackSpeed+optAvgLinSpeed) <> 0) Then
      begin
        Draw;
        While KeyPressed do ReadKey;

        TestWriteSpeed := (ConfigData.Global and optEnableWrite <> 0);
        If TestWriteSpeed and (Drive^.XMSStream^.Status <> 0) Then
        begin
          MessageBox(#3'Not enough XMS memory to perform write speed tests.'#13+
                      ' Only read speed will be tested.',Nil,mfError+mfOkButton, hcNoContext);
          TestWriteSpeed := False;
        end;
        If TestWriteSpeed and (ConfigData.Global and optNotAskWrite = 0) Then
        begin
          If MessageBox(#3'Would you like SKIP non-destructive write speed tests?',
                         Nil,mfConfirmation+mfYesButton+mfNoButton, hcNoContext) <> cmNo Then
          TestWriteSpeed := False;
        end;
      end;

      If ConfigData.Benchmarks and (optTrackSpeed+optAvgLinSpeed) <> 0 Then
      begin
         WriteLine('');
         WriteLine('                              \30\Read \23\(MBytes/sec.) \30\Write \23\(MBytes/sec.)');
      end;

      MenuBar^.Draw;
      If ConfigData.Benchmarks and optTrackSpeed <> 0 Then
      begin
        Drive^.GV^.Update(0);
        GV2^.Update(50);
        D^.SetCurrentText('First Track Speed Test');
        {Linear read at track 1}
        RSpeed0 := 0; WSpeed0 := 0;
        WriteLine(GetTrkFormattedString(TestStr[5], 1, msgTesting, ''));
        Drive^.GetTrackLinearSpeed(1, 4, RSpeed0, WSpeed0, TestWriteSpeed, True, True);
        If SkipTest
          Then WriteLineAt(-1, GetTrkFormattedString(TestStr[5], 1, msgNotTested, msgNotTested))
          Else begin
                 If RSpeed0 = 0 Then S1 := msgNotDetermined
                                Else S1 := '\26\'+RealToStr(RSpeed0/1024);
                 If WSpeed0 = 0 Then If TestWriteSpeed
                                      Then S2 := msgNotDetermined
                                      Else S2 := msgNotTested
                                Else S2 := '\26\'+RealToStr(WSpeed0/1024);
                 WriteLineAt(-1, GetTrkFormattedString(TestStr[5], 1, S1, S2))
               end;
        Drive^.GV^.Update(100);
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If ConfigData.Benchmarks and optTrackSpeed <> 0 Then
      begin
        Drive^.GV^.Update(0);
        GV2^.Update(62);
        D^.SetCurrentText('Last Track Speed Test');
        {Linear read at last track}
        RSpeedLast := 0; WSpeedLast := 0;
        WriteLine(GetTrkFormattedString(TestStr[5], Drive^.Tracks-2, msgTesting, ''));
        Drive^.GetTrackLinearSpeed(Drive^.Tracks-2, 4, RSpeedLast, WSpeedLast, TestWriteSpeed, True, True);
        If SkipTest
          Then WriteLineAt(-1, GetTrkFormattedString(TestStr[5], Drive^.Tracks-2, msgNotTested, msgNotTested))
          Else begin
                 If RSpeedLast = 0 Then S1 := msgNotDetermined
                                   Else S1 := '\26\'+RealToStr(RSpeedLast/1024);
                 If WSpeedLast = 0 Then If TestWriteSpeed
                                      Then S2 := msgNotDetermined
                                      Else S2 := msgNotTested
                                   Else S2 := '\26\'+RealToStr(WSpeedLast/1024);
                 WriteLineAt(-1, GetTrkFormattedString(TestStr[5], Drive^.Tracks-2, S1, S2))
               end;
        Drive^.GV^.Update(100);
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      If ConfigData.Benchmarks and optAvgLinSpeed <> 0 Then
      begin
        GV2^.Update(75);
        D^.SetCurrentText('Average Linear Speed Test');
        WriteLine('');
        {Average Linear Speed}
        WriteLine(GetFormattedString(TestStr[6], msgTesting, ''));
        Drive^.GetAverageLinearSpeed(1, TestWriteSpeed, True, True);
          If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[6], msgNotTested, msgNotTested))
          Else begin
                 If Drive^.AverageReadSpeed = 0 Then S1 := msgNotDetermined
                                                Else S1 := '\26\'+RealToStr(Drive^.AverageReadSpeed/1024);
                 If Drive^.AverageWriteSpeed = 0 Then If TestWriteSpeed
                                                         Then S2 := msgNotDetermined
                                                         Else S2 := msgNotTested
                                                 Else S2 := '\26\'+RealToStr(Drive^.AverageWriteSpeed/1024);
                 WriteLineAt(-1, GetFormattedString(TestStr[6], S1, S2))
               end;

        If not SkipTest Then
        begin
          If Drive^.MinReadSpeed = MaxLongInt Then S1 := msgNotDetermined
                                              Else S1 := '\26\'+RealToStr(Min(Drive^.MinReadSpeed, RSpeedLast)/1024);
          If Drive^.MinWriteSpeed = MaxLongInt Then If TestWriteSpeed
                                                  Then S2 := msgNotDetermined
                                                  Else S2 := msgNotTested
                                      Else S2 := '\26\'+RealToStr(Min(Drive^.MinWriteSpeed, WSpeedLast)/1024);
          WriteLine(GetFormattedString(TestStr[7], S1, S2));
          If Drive^.MaxReadSpeed = 0 Then S1 := msgNotDetermined
                                     Else S1 := '\26\'+RealToStr(Max(Drive^.MaxReadSpeed, RSpeed0)/1024);
          If Drive^.MaxWriteSpeed = 0 Then If TestWriteSpeed
                                             Then S2 := msgNotDetermined
                                             Else S2 := msgNotTested
                                      Else S2 := '\26\'+RealToStr(Max(Drive^.MaxWriteSpeed, WSpeed0)/1024);
          WriteLine(GetFormattedString(TestStr[8], S1, S2));
        end;

        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      {Max. Cache Speed}
      If ConfigData.Benchmarks and optCacheSpeed <> 0 Then
      begin
        GV2^.Update(87);
        D^.SetCurrentText('Max. Cache Read Speed Test');
        WriteLine('');
        WriteLine(GetFormattedString(TestStr[9], msgTesting, ''));
        Drive^.GetMaxCacheSpeed;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[9], msgNotTested, ''))
          Else If Drive^.MaxCacheSpeed > Drive^.AverageReadSpeed
                 Then WriteLineAt(-1, GetFormattedString(TestStr[9], '\26\'+RealToStr(Drive^.MaxCacheSpeed/1024)+
                      ' MBytes/sec. \31\(', '')+IntToStr(Drive^.BestBlockSize)+'K block)')
                 Else WriteLineAt(-1, GetFormattedString(TestStr[9], msgNotDetermined, ''));
        If CancelTests Then begin Draw; Dispose(D, Done); Exit; end;
      end;

      {Random Read Speed}
      If ConfigData.Benchmarks and optRandomReadSpeed <> 0 Then
      begin
        GV2^.Update(100);
        D^.SetCurrentText('Random Read Speed Test');
        WriteLine(GetFormattedString(TestStr[10], msgTesting, ''));
        Drive^.GetRandomReadSpeed;
        If SkipTest
          Then WriteLineAt(-1, GetFormattedString(TestStr[10], msgNotTested, ''))
          Else WriteLineAt(-1, GetFormattedString(TestStr[10], '\26\'+RealToStr(Drive^.RandomReadSpeed/1024)+
                               ' MBytes/sec.',''));
        If CancelTests Then begin Draw; Exit; end;
        WriteLine('');
      end;

      Drive^.GetSpeedIndex;
      If Drive^.SpeedIndex > 0 Then WriteLine('\31\ş Disk Speed Index: \26\'+IntToStr(Drive^.SpeedIndex));
      WriteLine('');
      Drive^.GetFATWeightedIndex; Drive^.GetHPFS386WeightedIndex;
      If Drive^.FATWeightedIndex > 0 Then
      begin
        WriteLine('                         FAT    HPFS386');
        WriteLine('ş Weighted Speed Index:   '+IntToStr(Drive^.FATWeightedIndex)+'        '+
                  IntToStr(Drive^.HPFS386WeightedIndex));
        WriteLine('');
      end;
      Draw;
      Dispose(D, Done);
    end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.SetDriveFeature(Command : Word);
var
  DialogTitle : String;
  Result      : Word;
  Ok          : Boolean;
begin
  If (Drive = Nil) or (TypeOf(Drive^) <> TypeOf(TIDEDrive)) Then Exit;
  With PIDEDrive(Drive)^ do
  begin
      Case Command of
        cmSetReadAhead  : DialogTitle := 'Read look-ahead';
        cmSetWriteCache : DialogTitle := 'Write cache';
        cmSetRetries    : DialogTitle := 'Retries';
        cmSetECC        : DialogTitle := 'ECC';
        cmSetDefect     : DialogTitle := 'Defects Auto Reassignment';
        cmSetSMART      : DialogTitle := 'S.M.A.R.T.';
        cmSetAutosave   : DialogTitle := 'Attributes Autosave';
      end;
    Result := ExecuteDialog(New(PEnableDisableDialog, Init(DialogTitle)), Nil);
    If Result <> cmCancel Then
    begin
      Case Command of
        cmSetReadAhead  : Ok := SetReadAhead(Result = cmYes);
        cmSetWriteCache : Ok := SetWriteCache(Result = cmYes);
        cmSetRetries    : Ok := SetRetries(Result = cmYes);
        cmSetECC        : Ok := SetECC(Result = cmYes);
        cmSetDefect     : Ok := SetDefectsReassignment(Result = cmYes);
        cmSetSMART      : Ok := SetSMART(Result = cmYes);
        cmSetAutosave   : Ok := SetSMARTAutosave(Result = cmYes);
      end;
      If Ok Then MessageBox(#3+DialogTitle+' successfully switched.',Nil,mfInformation+mfOkButton, hcNoContext)
            Else MessageBox(#3+DialogTitle+' switching failed.',Nil,mfError+mfOkButton, hcNoContext);
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.ShowList(Command : Word);
const
  ATAPIListTitle  = 'EIDE/ATAPI devices list';
  ATAPIListHeader = 'Port       Unit    Device       Model                        Revision';

  SCSIListTitle  = 'SCSI devices list';
  SCSIListHeader = 'Host/Target/LUN   Device';
var
  Data : Record
    List      : PCollection;
    Selection : Word;
  end;
  L   : PCollection;
  D   : PListDialog;
  Sel : Byte;
begin
  MenuBar^.WriteStr(71,0,' Wait... ',128);
  Case Command of
    cmATAPIList  : L := New(PATAPICollection, Init);
    cmSCSIList   : L := New(PSCSICollection, Init);
  end;
  MenuBar^.WriteStr(71,0,'          ',1);

  Data.List := L;
  Data.Selection := 0;

  Case Command of
    cmATAPIList : New(D, Init(ATAPIListTitle, ATAPIListHeader));
    cmSCSIList  : begin
                    If not ASPI_Ok Then
                    begin
                      MessageBox(#3'Can''t initialize ASPI manager.'#13+
                                   'Getting SCSI devices list failed.',Nil,mfError+mfOkButton, hcNoContext);
                      Dispose(L, Done);
                      Exit;
                    end;
                    New(D, Init(SCSIListTitle, SCSIListHeader));
                  end;
  end;
  ExecuteDialog(D, @Data);
  Dispose(L, Done);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.ShowDefectList;
var
  Data : Record
    List      : PCollection;
    Selection : Word;
  end;
  Sel : Byte;
begin
  If (Drive = Nil) or (TypeOf(Drive^) <> TypeOf(TIDEDrive)) Then Exit;
  With PIDEDrive(Drive)^ do
  begin
    If Pos('QUANTUM', GetModel) = 0 Then
       If MessageBox(#3'This feature implemented for Quantum drives only.'#13#3+
                       ' Whould you like to try it anyway?',
                       Nil,mfConfirmation+mfYesButton+mfNoButton, hcNoContext) <> cmYes Then Exit;

    If ReadDefectList <> 0 Then
    begin
      MessageBox(#3'Can''t get defect list.'
                   ,Nil,mfError+mfOkButton, hcNoContext);
      Exit;
    end;

    Data.List := DefectList;
    Data.Selection := 0;

    ExecuteDialog(New(PDefectListDialog, Init(DefectList)), @Data);
    Dispose(DefectList, Done); DefectList := Nil;
 end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.QuantumConfiguration;
var
  Data : Record
    DriveParams   : Word;
    DiskCache     : Word;
    ErrorRecovery : Word;
  end;
  Cfg : TQuantumConfiguration;
  Result : Word;
begin
  If (Drive = Nil) or (TypeOf(Drive^) <> TypeOf(TIDEDrive)) Then Exit;
  With PIDEDrive(Drive)^ do
  begin
    If Pos('QUANTUM', GetModel) = 0 Then
       If MessageBox(#3'This feature implemented for Quantum drives only.'#13#3+
                       ' Whould you like to try it anyway?',
                       Nil,mfConfirmation+mfYesButton+mfNoButton, hcNoContext) <> cmYes Then Exit;

    If not ReadInternalConfiguration(Cfg) Then
    begin
      MessageBox(#3'Can''t read internal configuration.'
                   ,Nil,mfError+mfOkButton, hcNoContext);
      Exit;
    end;
    Data.DriveParams := Cfg.DriveParams shr 1;
    Data.DiskCache := Cfg.DiskCache;
    Data.ErrorRecovery := ((Cfg.ErrorRecovery and $C0) shr 3) or ((Cfg.ErrorRecovery and $18) shr 2)
                          or (Cfg.ErrorRecovery and $01);

    Result := ExecuteDialog(New(PQuantumConfigDialog, Init), @Data);
    If Result <> cmCancel Then
    begin
      Cfg.DriveParams := Data.DriveParams shl 1;
      Cfg.DiskCache := Data.DiskCache;
      Cfg.ErrorRecovery := ((Data.ErrorRecovery and $18) shl 3) or ((Data.ErrorRecovery and $06) shl 2)
                            or (Data.ErrorRecovery and $01);

      If SetInternalConfiguration(Cfg, Result = cmSaveConfig)
        Then MessageBox(#3'Set or save internal configuration succesfull.'
                   ,Nil, mfInformation+mfOkButton, hcNoContext)
        Else MessageBox(#3'Can''t set or save internal configuration.'
                   ,Nil,mfError+mfOkButton, hcNoContext);
    end;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', hcFile, NewMenu(
      NewItem('~S~elect drive from list', 'F3', kbF3, cmSelect, hcDiskSelectList,
      NewItem('~M~anually set drive/port', 'Shift-F3', kbShiftF3, cmManualSelect, hcDiskSelectManual,
      NewLine(
      NewItem('Save ~r~eport as...', 'F2', kbF2, cmSave, hcFileSave,
      NewLine(
      NewItem('~D~os shell', '', kbNoKey, cmDosShell, hcFileDosShell,
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcFileExit,
    nil)))))))),
    NewSubMenu('~P~erformance', hcDisk, NewMenu(
      NewItem('~B~ecnhmarks', 'F4', kbF4, cmBench, hcBenchmarks,
      NewSubMenu('~G~raphs', hcGraphs, NewMenu(
        NewItem('Linear ~r~ead speed', 'F7', kbF7, cmReadGraph, hcGraphsRead,
        NewItem('Linear ~w~rite speed', 'F8', kbF8, cmWriteGraph, hcGraphsWrite,
        NewItem('Linear ~v~erify speed', 'Shift-F7', kbShiftF7, cmVerifyGraph, hcGraphsVerify,
        NewItem('~C~ache read speed', 'F9', kbF9, cmCacheGraph, hcGraphsCache,
      nil))))),
    nil))),
    NewSubMenu('~D~iagnostic', hcNoContext, NewMenu(
      NewItem('~C~ontroller & drive test', 'Alt-C', kbAltC, cmCtrlTest, hcNoContext,
      NewItem('~S~eek tests', 'Alt-S', kbAltS, cmSeekTest, hcNoContext,
      NewItem('~M~edia verify/repair', 'Alt-M', kbAltM, cmMediaVerify, hcNoContext,
      NewLine(
      NewSubMenu('S~.~M.A.R.T.', hcNoContext, NewMenu(
        NewItem('Show S.M.A.R.~T~. info', 'Alt-T', kbAltT, cmShowSMARTInfo, hcNoContext,
        NewItem('Ad~v~anced S.M.A.R.T. info', 'Alt-V', kbAltV, cmShowAdvSMART, hcNoContext,
        NewLine(
        NewItem('~C~hange S.M.A.R.T status...', '', kbNoKey, cmSetSMART, hcNoContext,
        NewItem('Change attributes ~a~utosave...', '', kbNoKey, cmSetAutosave, hcNoContext,
        NewLine(
        NewItem('Save attributes ~d~ump', '', kbNoKey, cmSaveSMARTDump, hcNoContext,
      nil)))))))),
      NewSubMenu('~A~dvanced', hcNoContext, NewMenu(
        NewItem('~V~iew defect list', '', kbNoKey, cmDefectList, hcNoContext,
        NewItem('~I~nternal drive configuration', '', kbNoKey, cmInternalCfg, hcNoContext,
      nil))),
    nil))))))),
    NewSubMenu('~U~tilities', hcNoContext, NewMenu(
      NewSubMenu('IDE drive ~f~eatures', hcNoContext, NewMenu(
        NewItem('~R~ead look-ahead...', '', kbNoKey, cmSetReadAhead, hcNoContext,
        NewItem('~W~rite cache...', '', kbNoKey, cmSetWriteCache, hcNoContext,
        NewItem('R~e~tries...', '', kbNoKey, cmSetRetries, hcNoContext,
        NewItem('E~C~C...', '', kbNoKey, cmSetECC, hcNoContext,
        NewItem('~D~efects auto reassignment...', '', kbNoKey, cmSetDefect, hcNoContext,
      nil)))))),
      NewLine(
      NewItem('~E~IDE/ATAPI devices list', '', kbNoKey, cmATAPIList, hcNoContext,
      NewItem('~S~CSI devices list', '', kbNoKey, cmSCSIList, hcNoContext,
      NewItem('Media ~f~ormat', '', kbNoKey, cmMediaFormat, hcNoContext,
      {
      NewItem('System ~i~nformation', '', kbNoKey, cmSysinfo, hcNoContext,
      }
    nil)))))),
    NewSubMenu('~O~ptions', hcNoContext, NewMenu(
      NewItem('~C~onfiguration..', 'Alt-F10', kbAltF10, cmConfiguration, hcConfig,
      NewLine(
      NewItem('25/50 ~l~ines', 'Shift-F10', kbShiftF10, cmOptionsVideo, hcNoContext,
      nil)))),
    NewSubMenu('~H~elp', hcNoContext, NewMenu(
      NewItem('~A~bout...', 'Ctrl-F1', kbCtrlF1, cmAbout, hcNoContext,
      nil)),
    nil)))))))));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(PMyStatusLine(StatusLine), Init(R,
    NewStatusDef(0, $EFFF,
      NewStatusKey('~F1~ Help', kbF1, cmHelp,
      NewStatusKey('~F2~ Save', kbF2, cmSave,
      NewStatusKey('~F3~ Select disk', kbF3, cmSelect,
      NewStatusKey('~F4~ Benchmarks', kbF4, cmBench,
      StdStatusKeys(nil))))),
    {When Shift pressed}
    NewStatusDef($F000, $FF00,
      NewStatusKey('~Shift+F3~ Select drive/port', kbShiftF3, cmManualSelect,
      NewStatusKey('~Shift+F10~ 25/50 lines', kbShiftF10, cmOptionsVideo,
      StdStatusKeys(nil))),
   nil))));
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TDriveTestApp.GetPalette: PPalette;
const
  CNewColor = CAppColor + CHelpColor;
  CNewBlackWhite = CAppBlackWhite + CHelpBlackWhite;
  CNewMonochrome = CAppMonochrome + CHelpMonochrome;
  P: array[apColor..apMonochrome] of string[Length(CNewColor)] =
    (CNewColor, CNewBlackWhite, CNewMonochrome);
begin
  GetPalette := @P[AppPalette];
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure   TDriveTestApp.SetScreenMode(Mode: Word);
begin
  inherited SetScreenMode(Mode);
  If (ScreenMode and smFont8x8 = 0) and (ConfigData.Global and optLoadFont <> 0)
    Then begin
           LoadNewFont;
           InitGMouse(False);
         end;

  If InfoWindow = Nil Then Exit;
  With InfoWindow^.ScreenText^ do VScrollBar^.SetRange(1, LinesCount);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.GetEvent(var Event: TEvent);
var
  W: PWindow;
  HFile: PHelpFile;
  HelpStrm: PDosStream;
  R : TRect;
const
  HelpInUse: Boolean = False;

  function CalcHelpName: PathStr;
  var
    EXEName: PathStr;
    Dir: DirStr;
    Name: NameStr;
    Ext: ExtStr;
  begin
    If Lo(DosVersion) >= 3
      Then EXEName := ParamStr(0)
      Else EXEName := FSearch('HDDSPEED.EXE', GetEnv('PATH'));
    FSplit(EXEName, Dir, Name, Ext);
    If Dir[Length(Dir)] = '\' Then Dec(Dir[0]);
    CalcHelpName := FSearch('HDDSPEED.HLP', Dir);
  end;

begin
  inherited GetEvent(Event);
  case Event.What of
    evCommand:
      if (Event.Command = cmHelp) and not HelpInUse then
      begin
        HelpInUse := True;
        HelpStrm := New(PDosStream, Init(CalcHelpName, stOpenRead));
        HFile := New(PHelpFile, Init(HelpStrm));
        if HelpStrm^.Status <> stOk then
        begin
          MessageBox(#3'Could not open help file.', nil, mfError + mfOkButton, hcNoContext);
          Dispose(HFile, Done);
        end
        else
        begin
          W := New(PHelpWindow,Init(HFile, GetHelpCtx));
          GetExtent(R); R.Grow(-3,-3);
          W^.ChangeBounds(R);
          if ValidView(W) <> nil then
          begin
            ExecView(W);
            Dispose(W, Done);
          end;
          ClearEvent(Event);
        end;
        HelpInUse := False;
      end;
    evMouseDown:
      if Event.Buttons <> 1 then Event.What := evNothing;
  end;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure TDriveTestApp.HandleEvent(var Event: TEvent);
var
  R: TRect;
begin
  if Event.What = evCommand Then
  begin
    case Event.Command of
      cmQuit:
        begin
          If MessageBox(#3'Do you wish to quit HddSpeed?',Nil,mfConfirmation+mfYesButton+mfNoButton, hcMsgBoxExit) <> cmYes
            Then ClearEvent(Event);
        end;
      cmAbout:
        begin
          DoAboutBox;
          ClearEvent(Event);
        end;
      cmClose:
        begin
          InfoWindow := Nil;
          If Drive <> Nil Then
          begin
            Dispose(Drive, Done); Drive := Nil;
          end;
        end;
      cmOptionsVideo:
        begin
          SetScreenMode(ScreenMode xor smFont8x8);
          ClearEvent(Event);
        end;
      cmSave:
        begin
          SaveResults;
          ClearEvent(Event);
        end;
      cmSelect:
        begin
          If SelectDrive and (Drive <> Nil) Then
          begin
            If InfoWindow <> Nil Then Dispose(InfoWindow, Done);
            InfoWindow := New(PInfoWindow , Init(Drive));
            InsertWindow(InfoWindow);
            ShowDriveInfo;
          end;
          ClearEvent(Event);
        end;
      cmManualSelect:
        begin
          If ManualSelectDrive and (Drive <> Nil) Then
          begin
            If InfoWindow <> Nil Then Dispose(InfoWindow, Done);
            InfoWindow := New(PInfoWindow , Init(Drive));
            InsertWindow(InfoWindow);
            ShowDriveInfo;
          end;
          ClearEvent(Event);
        end;
      cmCtrlTest:
        begin
          ControllerTest;
          ClearEvent(Event);
        end;
      cmSeekTest:
        begin
          SeekTest;
          ClearEvent(Event);
        end;
      cmMediaVerify:
        begin
          MediaVerify;
          ClearEvent(Event);
        end;
      cmBench:
        begin
          Benchmarks;
          ClearEvent(Event);
        end;
      cmReadGraph:
        begin
          HideMouse;
          DrawLinearSpeedGraph(Drive, lsRead, False);
          SetScreenMode(ScreenMode);
          Redraw;
          ShowMouse;
          ClearEvent(Event);
        end;
      cmWriteGraph:
        begin
          TestWriteSpeed := (ConfigData.Global and optEnableWrite <> 0);
          If not TestWriteSpeed Then
            MessageBox(#3'Write speed tests disabled in Options->Configuration',Nil,mfInformation+mfOkButton, hcNoContext);
          If TestWriteSpeed and (Drive^.XMSStream^.Status <> 0) Then
          begin
            MessageBox(#3'Not enough XMS memory to perform write speed tests.',Nil,mfError+mfOkButton, hcNoContext);
            TestWriteSpeed := False;
          end;
          If TestWriteSpeed and (ConfigData.Global and optNotAskWrite = 0) Then
          begin
            If MessageBox(#3'Would you like SKIP non-destructive write speed tests?',
                           Nil,mfConfirmation+mfYesButton+mfNoButton, hcNoContext) <> cmNo Then
            TestWriteSpeed := False;
          end;
          If TestWriteSpeed Then
          begin
            HideMouse;
            DrawLinearSpeedGraph(Drive, lsWrite, True);
            SetScreenMode(ScreenMode);
            Redraw;
            ShowMouse;
          end;
          ClearEvent(Event);
        end;
      cmVerifyGraph:
        begin
          HideMouse;
          DrawLinearSpeedGraph(Drive, lsVerify, False);
          SetScreenMode(ScreenMode);
          Redraw;
          ShowMouse;
          ClearEvent(Event);
        end;
      cmCacheGraph:
        begin
          HideMouse;
          DrawCacheGraph(Drive);
          SetScreenMode(ScreenMode);
          Redraw;
          ShowMouse;
          ClearEvent(Event);
        end;
      cmSetReadAhead,
      cmSetWriteCache,
      cmSetRetries,
      cmSetECC,
      cmSetDefect,
      cmSetSMART,
      cmSetAutosave:
        begin
          SetDriveFeature(Event.Command);
          ClearEvent(Event);
        end;
      cmShowSMARTInfo:
        begin
          ShowSMARTInfo;
          ClearEvent(Event);
        end;
      cmShowAdvSMART:
        begin
          ShowAdvancedSMARTInfo;
          ClearEvent(Event);
        end;
      cmSaveSMARTDump:
        begin
          SaveSMARTDump;
          ClearEvent(Event);
        end;
      cmATAPIList,
      cmSCSIList:
        begin
          ShowList(Event.Command);
          ClearEvent(Event);
        end;
      cmMediaFormat:
        begin
          MediaFormat;
          ClearEvent(Event);
        end;
      cmDefectList:
        begin
          ShowDefectList;
          ClearEvent(Event);
        end;
      cmInternalCfg:
        begin
          QuantumConfiguration;
          ClearEvent(Event);
        end;
      cmSysinfo:
        begin
          SysInfo;
          ClearEvent(Event);
        end;
      cmConfiguration:
        begin
          Configuration;
          ClearEvent(Event);
        end;
      cmNotDone:
        begin
          MessageBox(#3'Sorry, this feature is not implemented yet.',Nil,mfConfirmation+mfOkButton, hcNoContext);
          ClearEvent(Event);
        end;
    end;
  end;
  inherited HandleEvent(Event);
end;

var
  DTApp: TDriveTestApp;

begin
  DTApp.Init;
  If MultiTaskPresent and (ConfigData.Global and optNotCheckMultitask = 0) Then
  begin
    DTApp.Done;
    Halt(1);
  end;
  DTApp.Run;
  DTApp.Done;
end.
