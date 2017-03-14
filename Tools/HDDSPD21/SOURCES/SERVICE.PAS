{$X+,G+,D-,L-,S-,R-,V-}
unit Service;

interface

uses Dos, OS, CpuType;

type

  TConfigData = Record
    Benchmarks : Word;
    Global     : Word;
    RPMMethod  : Word;
  end;

const

  BinVer  = $0200;
  Version = {$I version.inc};

  CheckBox : Array [Boolean] of Char = (' ','�');

  keyF2  = 316;

  {Benchmarks}
  optBufferSize      = $0001;
  optRPM             = $0002;
  optAvgSeek         = $0004;
  optMaxSeek         = $0008;
  optTTTSeek         = $0010;
  optAvgAccess       = $0020;
  optTrackSpeed      = $0040;
  optAvgLinSpeed     = $0080;
  optCacheSpeed      = $0100;
  optRandomReadSpeed = $0200;

  {Global}
  optEnableWrite       = $0001;
  optNotAskWrite       = $0002;
  optDetailedGraph     = $0004;
  optKeepTracksLog     = $0008;
  optSMARTPrediction   = $0010;
  optLoadFont          = $0020;
  optNotCheckMultitask = $1000;

  ConfigData : TConfigData = (Benchmarks:510; Global: 56; RPMMethod:$0000);

var
  BIOSTimer      : LongInt absolute $40:$6c;

  CancelTests,
  SkipTest       : Boolean;

  OldInt9h       : Pointer;

function  UpCaseStr(S: String): String;
function  IntToStr(I: LongInt): String;
function  RealToStr(R: Real): String;
function  ByteToHexStr(B: Byte):String;
function  WordToHexStr(W: Word):String;
function  LongWordToHexStr(L: LongInt):String;
Function  ByteToBinStr(Number: Byte): String;
function  Trim(S: String): String;
function  Separator(Title: String) : String;
function  MultiTaskPresent : Boolean;
function  GetKey: Word;
function  HighestBit(B: Byte) : Byte;
procedure StartUp;
procedure ShutDown(ExitCode : Byte);
procedure MemAlloc(var P : Pointer; Size : Word);
procedure MemFree(P : Pointer);
function  GetFreeMemSize : Word;
procedure SetBlinking(Switch: Byte);
function  Min(a,b : LongInt) : LongInt;
function  Max(a,b : LongInt) : LongInt;
function  ValToStr(L : LongInt; N : Byte) : String;
function  GetCurrentPackedDateTime : LongInt;
function  GetYearAndMonthStr(PackedTime : LongInt) : String;
function  GetDateStr(PackedTime : LongInt) : String;
function  GetTimeStr(PackedTime : LongInt) : String;
function  GetDateTimeStr(PackedTime : LongInt) : String;
function  CurrentTimeStr : String;
function  CurrentDateStr : String;
function  GetCPU : String;
function  GetOSName : String;
function  GetBIOSString(Seg, Ofs: Word): String;
function  CalcCheckSum(var Buf; Size : Word) : Byte;
function  MonthBetween(PT1, PT2 : LongInt) : Real;
function  AddMonth(PT : LongInt; M : Real) : LongInt;
function  GetTimeSec : LongInt;
function  TimeSecToStr(T : LongInt) : String;
function  GetTime100 : LongInt;
function  Time100ToStr(T : LongInt) : String;
function  AlignLeft(S : String; Len : Byte) : String;

implementation

{����������������������������������������������������������������������}
procedure MemAlloc(var P : Pointer; Size : Word); assembler;
asm
    push   es
    push   di
    les    di,P
    mov    word ptr es:[di+2],0
    mov    word ptr es:[di],0
    mov    ah,48h
    mov    bx,Size
    int    21h
    jc     @1
    les    di,P
    mov    es:[di+2],ax
    mov    word ptr es:[di],0
  @1:
    pop    di
    pop    es
end;

{����������������������������������������������������������������������}
procedure MemFree(P : Pointer); assembler;
asm
  push  es
  push  di
  les   di,P
  mov   ah,49h
  int   21h
  pop   di
  pop   es
end;

{����������������������������������������������������������������������}
function GetFreeMemSize : Word; assembler;
asm
  mov    ah,48h
  mov    bx,0FFFFh
  int    21h
  mov    ax,bx
end;

{����������������������������������������������������������������������}
function UpCaseStr(S: String): String;
var
  i,j : Byte;
  S1 : String;
begin
  for i := 1 to Length(S) do S1[i] := UpCase(S[i]);
  S1[0] := S[0];
  UpCaseStr := S1;
end;

{����������������������������������������������������������������������}
function IntToStr(I: LongInt): String;
var S : String[11];
begin
  Str(i, S);
  IntToStr := S;
end;

{����������������������������������������������������������������������}
function RealToStr(R: Real): String;
var S : String[11];
begin
  Str(R:3:1,S);
  RealToStr := S;
end;

{����������������������������������������������������������������������}
function ByteToHexStr(B: Byte):String;
const HexChars: Array [0..$F] of Char = '0123456789ABCDEF';
{ �८�ࠧ�� ���� � ��⭠������� ��ப� }
begin
  ByteToHexStr := HexChars[B shr 4 ] + HexChars[B and $F];
end;

{����������������������������������������������������������������������}
function WordToHexStr(W: Word):String;
const HexChars: Array [0..$F] of Char = '0123456789ABCDEF';
{ �८�ࠧ�� ᫮�� � ��⭠������� ��ப� }
begin
  WordToHexStr := HexChars[Hi(W) shr 4]+HexChars[Hi(W) and $F]
                 +HexChars[Lo(W) shr 4]+HexChars[Lo(W) and $F];
end;

{����������������������������������������������������������������������}
function LongWordToHexStr(L: LongInt):String;
var
  W : Array [0..1] of Word absolute L;
begin
  LongWordToHexStr := WordToHexStr(W[0])+WordToHexStr(W[1]);
end;

{����������������������������������������������������������������������}
Function ByteToBinStr(Number: Byte): String;
Var
  Temp1: Byte;
  Temp2: Byte;
  i: Word;
  TempStr: String[8];

Begin
  Temp1 := 0;
  Temp2 := $80;
  For i := 1 to 8 Do
    Begin
    If (Number and Temp2) <> 0 Then
      TempStr[i] := '1'
    Else
      TempStr[i] := '0';
    Temp2 := Temp2 shr 1;
    End;
  TempStr[0] := #8;
  ByteToBinStr := TempStr;
End;

{����������������������������������������������������������������������}
function Trim(S: String): String;
var
  i,j : Byte;
begin
  i := 1;
  While (S[i] = ' ')and(i < Length(S)) do Inc(i);
  j := Length(S);
  While (S[j] = ' ')and(j > 1) do Dec(j);
  Trim := Copy(S,i,j-i+1);
end;

{����������������������������������������������������������������������}
function Separator(Title: String) : String;
var
  S, S1 : String[76];
begin
  FillChar(S[1],76,196); S[0] := #76;
  S1 := '';
  If Title <> '' Then S1 := '�'+Title+'�';
  Move(S1[1], S[(Length(S)-Length(S1)) div 2], Length(S1));
  Separator := S;
end;

{����������������������������������������������������������������������}
function MultiTaskPresent : Boolean; assembler;
asm
  mov ax,$1687;int $2f;
  or ax,ax;jz @1
  mov ax,$1600;int $2f;
  cmp al,1;je @1
  mov ax,$160A;int $2f;
  or ax,ax;jz @1
  mov ax,$4680;int $2f;
  or ax,ax;jz @1
  mov al,0
  jmp @2
@1:                     {multitask}
  mov al,1
@2:
end;

{����������������������������������������������������������������������}
procedure Int9h; interrupt; assembler;
asm
  in al,$60
  cmp al,1              {ESC}
  jnz @1
  mov SkipTest,1
  mov CancelTests,1
  jmp @Exit
@1:
  cmp al,39h            {Space}
  jnz @2
  mov SkipTest,1
@2:
  cmp al,1Ch            {Enter}
  jnz @Exit
  mov SkipTest,1
@Exit:
  pushf
  call OldInt9h
end;

{����������������������������������������������������������������������}
procedure SetBlinking(Switch: Byte); assembler;
asm
   mov  ax,1003h
   mov  bl,Switch
   int  10h
end;

{����������������������������������������������������������������������}
function GetKey: Word;
var
  R: Registers;
begin
  R.AX := $0000;
  Intr($16,R);
  If R.AL <> 0 Then GetKey := R.AL
               Else GetKey := R.AH + 256;
end;

{����������������������������������������������������������������������}
function HighestBit(B: Byte) : Byte;
var
  i, HBit : Byte;
begin
  HBit := 0;
  for i := 7 downto 0 do
    If ((B shr i) and 1 <> 0) and (i > HBit) Then HBit := i;
  HighestBit := HBit;
end;

{����������������������������������������������������������������������}
function Max(a,b : LongInt) : LongInt;
begin
  If a > b Then Max := a
           Else Max := b;
end;

{����������������������������������������������������������������������}
function Min(a,b : LongInt) : LongInt;
begin
  If a < b Then Min := a
           Else Min := b;
end;
{����������������������������������������������������������������������}
function ValToStr(L : LongInt; N : Byte) : String;
var
  S1, S2 : String;
  i : Byte;
begin
  Str(L,S1);
  S2 := '';
  IF Length(S1) < N Then for i := 1 to N-Length(S1) do S2 := S2 + '0';
  ValToStr := S2+S1;
end;

{����������������������������������������������������������������������}
function GetCurrentPackedDateTime : LongInt;
var
  DT              : DateTime;
  DayOfWeek       : Word;
  Sec100          : Word;
  L               : LongInt;
begin
  GetDate(DT.Year, DT.Month, DT.Day, DayOfWeek);
  GetTime(DT.Hour, DT.Min, DT.Sec, Sec100);
  PackTime(DT, L);
  GetCurrentPackedDateTime := L;
end;

{����������������������������������������������������������������������}
function GetYearAndMonthStr(PackedTime : LongInt) : String;
const
  MonthName : Array [1..12] of String[3] = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
var
  DT : DateTime;
begin
  UnPackTime(PackedTime, DT);
  With DT do
    GetYearAndMonthStr := MonthName[Month{ mod 12}]+'-'+ValToStr(Year,4);
end;

{����������������������������������������������������������������������}
function GetDateStr(PackedTime : LongInt) : String;
var
  DT : DateTime;
begin
  UnPackTime(PackedTime, DT);
  With DT do
    GetDateStr := ValToStr(Day,2)+'-'+ValToStr(Month,2)+'-'+ValToStr(Year mod 100,2)
end;

{����������������������������������������������������������������������}
function GetTimeStr(PackedTime : LongInt) : String;
var
  DT : DateTime;
begin
  UnPackTime(PackedTime, DT);
  With DT do
    GetTimeStr := ValToStr(Hour,2)+':'+ValToStr(Min,2)+':'+ValToStr(Sec,2);
end;

{����������������������������������������������������������������������}
function GetDateTimeStr(PackedTime : LongInt) : String;
begin
  GetDateTimeStr := GetDateStr(PackedTime)+', '+GetTimeStr(PackedTime)
end;

{����������������������������������������������������������������������}
function CurrentTimeStr : String;
var
{$IFDEF OS2}
  Hour, Min, Sec, Sec100: LongInt;
{$ELSE}
  Hour, Min, Sec, Sec100: Word;
{$ENDIF}
  HourStr, MinStr, SecStr : String[2];
begin
  GetTime(Hour, Min, Sec, Sec100);
  HourStr := ValToStr(Hour,2);
  MinStr := ValToStr(Min,2);
  SecStr := ValToStr(Sec,2);
  CurrentTimeStr := HourStr+':'+MinStr+':'+SecStr;
end;

{����������������������������������������������������������������������}
function CurrentDateStr : String;
var
  Year, Month, Day, DayOfWeek : Word;
begin
  GetDate(Year, Month, Day, DayOfWeek);
  CurrentDateStr := ValToStr(Day,2)+'-'+ValToStr(Month,2)+'-'+ValToStr(Year mod 100,2);
end;


{����������������������������������������������������������������������}
procedure StartUp;
begin
  GetIntVec($9,OldInt9h); SetIntVec($9,Addr(Int9h));
end;

{����������������������������������������������������������������������}
procedure ShutDown(ExitCode : Byte);
begin
  SetIntVec($9,OldInt9h);
end;

{����������������������������������������������������������������������}
function GetOSName : String;
const
  OSName : Array [0..4] of String[15] =
           ('MS DOS', 'Windows', 'OS/2', 'DESQview', 'TopView');
var
  S : String;
begin
 InitMulti;
 S := OSName[Task.OS]+' ver. ';
 If Task.OS = 0 Then S := S+IntToStr(lo(DosVersion))+ '.'+IntToStr(hi(DosVersion))
                Else S := S+IntToStr(hi(Task.Version))+ '.'+IntToStr(lo(Task.Version));
 GetOSName := S;
end;

{����������������������������������������������������������������������}
function GetCPU : String;
begin
  GetCPU := cpu_Type+' at '+IntToStr(cpu_Speed)+'MHz';
end;

{����������������������������������������������������������������������}
function GetBIOSString(Seg, Ofs: Word): String;
var
  P : ^String;
  i : Byte;
  S : String;
begin
  GetBIOSString := '';
  P := Ptr(Seg,Ofs);
  i := 1;
  While P^[i] >= ' ' do Inc(i);
  S[0] := Char(i-1); Move(P^[1],S[1],i-1);
  GetBIOSString := S;
end;

{����������������������������������������������������������������������}
function CalcCheckSum(var Buf; Size : Word) : Byte;
type
  PByteArray = ^TByteArray;
  TByteArray = Array [1..65520] of Byte;
var
  PA  : PByteArray;
  Sum : Byte;
  i   : LongInt;
begin
   PA := Pointer(Addr(Buf));
   Sum := 0;
   for i := 1 to Size do Sum := Sum+PA^[i];
   CalcCheckSum := -Sum;
end;

{����������������������������������������������������������������������}
function MonthBetween(PT1, PT2 : LongInt) : Real;
var
  D1, D2 : DateTime;
  M1, M2 : Real;
begin
  UnpackTime(PT1, D1); UnpackTime(PT2, D2);
  M1 := D1.Year*12+D1.Month+D1.Day/30;
  M2 := D2.Year*12+D2.Month+D2.Day/30;
  MonthBetween := Abs(M2-M1);
end;

{����������������������������������������������������������������������}
function AddMonth(PT : LongInt; M : Real) : LongInt;
var
  DT      : DateTime;
  Y, D, L : LongInt;
begin
  UnpackTime(PT, DT);
  Y := Trunc(M) div 12;
  M := Trunc(M) mod 12;
  D := Round(Frac(M)*30);
  M := Trunc(M);

  Inc(DT.Day, D);
  If DT.Day > 30 Then
  begin
    Dec(DT.Day, 30);
    Inc(DT.Month);
  end;
  Inc(DT.Month, Trunc(M));
  If DT.Month > 12 Then
  begin
    Dec(DT.Month,12);
    Inc(DT.Year);
  end;
  Inc(DT.Year, Y);
  PackTime(DT, L);
  AddMonth := L;
end;

{����������������������������������������������������������������������}
function  GetTimeSec : LongInt;
{�����頥� ⥪�饥 �६� � 100-� ����� ᥪ㭤}
var
  Hour, Minute, Second, Sec100 : {$IFDEF OS2} LongInt {$ELSE} Word {$ENDIF};
begin
  GetTime(Hour, Minute, Second, Sec100);
  GetTimeSec := Second + Minute*60 + Hour*60*60;
end;

{����������������������������������������������������������������������}
function  TimeSecToStr(T : LongInt) : String;
var
  Hour, Minute, Second : {$IFDEF OS2} LongInt {$ELSE} Word {$ENDIF};

  function LeadingZero(w : Word) : String;
  var
    s : String;
  begin
    Str(w:0,s);
    if Length(s) = 1 then
      s := '0' + s;
    LeadingZero := s;
  end;

begin
  Second := T mod 60;  T := T div 60;
  Minute := T mod 60;  T := T div 60;
  Hour := T;

  TimeSecToStr := LeadingZero(Hour)+':'+ LeadingZero(Minute)+
                  ':'+LeadingZero(Second);
end;


{����������������������������������������������������������������������}
function  GetTime100 : LongInt;
{�����頥� ⥪�饥 �६� � 100-� ����� ᥪ㭤}
var
  Hour, Minute, Second, Sec100 : {$IFDEF OS2} LongInt {$ELSE} Word {$ENDIF};
begin
  GetTime(Hour, Minute, Second, Sec100);
  GetTime100 := Sec100 + Second*100 + Minute*60*100 + Hour*60*60*100;
end;

{����������������������������������������������������������������������}
function  Time100ToStr(T : LongInt) : String;
var
  Hour, Minute, Second, Sec100 : LongInt;

  function LeadingZero(w : LongInt) : String;
  var
    s : String;
  begin
    Str(Abs(w):0, s);
    if Length(s) = 1 then
      s := '0' + s;
    LeadingZero := s;
  end;

begin
  Sec100 := T mod 100; T := T div 100;
  Second := T mod 60;  T := T div 60;
  Minute := T mod 60;  T := T div 60;
  Hour := T;

  Time100ToStr := LeadingZero(Hour)+':'+ LeadingZero(Minute)+
                  ':'+LeadingZero(Second){+'.'+LeadingZero(Sec100)};
end;

function  AlignLeft(S : String; Len : Byte) : String;
var
  S1 : String;
begin
  AlignLeft := S;
  If Length(S) >= Len Then Exit;
  FillChar(S1[1], Len, ' '); S1[0] := Char(Len);
  Move(S[1], S1[1], Length(S));
  AlignLeft := S1;
end;

begin
end.
