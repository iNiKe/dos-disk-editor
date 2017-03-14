{$M 16384,$10000,$10000}
{$X+,G+,S-,R-,V-}
{$D-,L-}

uses Dos, Crt, Objects, Drivers, Service, Timer, Drive, Tests, IDE;

var
  Drv  : TIDEDrive;
  D    : Byte;
  Code : Integer;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WriteStr(S : String);
var
  Len : Byte absolute S;
  i, j, B, OldAttr : Byte;
  S1 : String;
  C : Integer;
begin
  OldAttr := TextAttr;
  i := 0;
  While i < Len do
  begin
    Inc(i);
    j := i; S1[0] := #0;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    System.Write(S1);
    i := j+1; j := i;
    While (S[j] <> '\')and(j <= Len) do Inc(j);
    Move(S[i],S1[1],j-i); S1[0] := Char(j-i);
    i := j;
    If J < Len Then
    begin
      If S1[0] = #0
        Then System.Write('\')
        Else begin
          Val(S1,B,C);
          If C = 0 Then TextAttr := B;
        end;
    end;
  end;
  TextAttr := OldAttr;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WriteLine(S : String);
begin
  WriteStr(S);
  System.WriteLn;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure ShowSMARTInfo;
const
  FStr       : String = '%1s %-25s %-3d  %3d      %3d  %-22s  \7\%4s    %-12s';
  HeaderLine : String = '\14\  Attribute                 ID Threshold Value Indicator  1/Month   T.E.C.';
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
  With Drv do
  begin
    Ok := GetSMARTInfo;
    If not Ok Then
    begin
      WriteLine('\31\ş Get S.M.A.R.T. Info: \28\Failed.');
      Exit;
    end;

    UpdateSMARTBase;
    WriteLine('ş T.E.C. prediction monitoring started at: '+GetDateTimeStr(SMARTMonitorRec.StartDate));

    WriteLine('');
    WriteLine(HeaderLine);
    WriteLine('\14\'+Separator(''));

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

         Indicator := '\12\ş\14\şş\10\şşşşşşş';
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
     WriteLine('\14\'+Separator(''));
     WriteLine('NOTE: "*" means life-critical attribute');
     WriteLine('');
     If TEC
       Then begin
              If CriticalTEC Then WriteLine('\12\! T.E.C. detected with life-critical attribute!')
                             Else WriteLine('\12\! T.E.C. detected with not critical attribute.');
              Sound(500); Delay(500); NoSound;
            end
       Else begin
         WriteLine('ş T.E.C. not detected.');
         If NearestTEC < MaxLongInt Then
         begin
           WriteLine('ş Nearest prognosed T.E.C.: \15\'+GetYearAndMonthStr(NearestTEC)+', '+
                        GetSMARTAttrMeaning(NearestTECAttr)+
                     +' ('+CritStr[(SMARTValues.Values[NearestTECAttr].StatusFlags and 1) <> 0]+'Critical)');
         end;
       end;
  end;
end;

begin
  WriteLn;
  WriteLn('ÄÄÍÍ S.M.A.R.T. Drive Health Monitor v1.0 ÍÍÄÄ');
  WriteLn('(C) 1997, Michael Radchenko (2:5025/25@fidonet)');
  WriteLn;
  If ParamCount = 0
    Then D := 0
    Else begin
      Val(ParamStr(1), D, Code);
      If Code <> 0 Then
      begin
        WriteLn('Error in commmand line.');
        WriteLn('Usage: SMARTMON <Drive_Number>');
        Halt(1);
      end;
    end;

  Drv.Init($80+D, 0, 0);
  If Drv.Status <> 0 Then
  begin
    WriteLine('\12\! Error: '+Drv.GetErrorMessage(Drv.Status));
    Drv.Done;
    Halt;
  end;
  WriteLine('ş Drive '+IntToStr(D)+': \11\'+Drv.GetModel+
             '         \7\Serial Number: '+Drv.IDEInfo.Serial);
  ShowSMARTInfo;
  Drv.Done;
end.
