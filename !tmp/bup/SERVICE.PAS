(****************************************************************************
 *                ����� �᭮���� ��⥬��� �⨫�� v1.00 beta 2             *
 ****************************************************************************
 *                                                                          *
 *                                                         Since: --------- *
 * (c) NiKe'Soft UnLtd.                              Last UpDate: 31/07/Y2k *
 ****************************************************************************)
{$X+,G+,D-,L-,S-,R-,V-}
Unit Service;

  INTERFACE

type
      DateTime = record
               Year,Month,Day,Hour,Min,Sec: Word;
             end;

const On  = True;
      Off = False;
      MonthSt : array[1..12] of string[8] =
      (('������' ),('���ࠫ�'),('����'    ),('��५�' ),('���'   ),('���'   ),
       ('���'   ),('������' ),('�������'),('������'),('�����'),('�������'));
      LeftAlign   = 0;
      RightAlign  = 1;
      CenterAlign = 2;

var  BIOSTimer : LongInt absolute $40:$6c;

function  StrEq(Var a,b; Count : Word) : Boolean;
function  LoCase(s : string)  : string;
function  UpCaseStr(S : String): String;
function  UpCaseCh(ch : char) : char;
function  fStr(l : longint; maxsz : byte; digch, fillch : char; Align : byte): string;
function  StrF(l : longint; d : byte): string;
Function  Min(X,Y : Integer) : Integer;                            {assembler}
function  Max(X,Y : Integer) : Integer;                            {assembler}
function  MultiTaskPresent : Boolean;                              {assembler}
procedure StartTimer;
function  ReadTimer : Word;
function  ReadKey: char;                                           {assembler}
function  keyPressed: boolean;                                     {assembler}
procedure SetCursorSpeed(spd: byte);                               {assembler}
procedure UnpackTime(P: Longint; var T: DateTime);
procedure PackTime(var T: DateTime; var P: Longint);
function  RTrim(s : string) : string;
function  LTrim(s : string) : string;
function  TimeDateStr(td : DateTime) : string;
function  GetTimeSt(tm : longint) : string;
function  LZ(s : string; zn : byte; ch : char): string;
function  Size_Str(sz : real) : string;
function  Size_Str_kb(sz : real) : string;
function Trim(s : string) : string;

  IMPLEMENTATION

{����������������������������������������������������������������������}
{$L PTIM.OBJ}           { Time pack and unpack routines }
procedure UnpackTime(P: Longint; var T: DateTime); external {PTIM};
procedure PackTime(var T: DateTime; var P: Longint); external {PTIM};
{����������������������������������������������������������������������}
function Trim(s : string) : string;
var i : integer;
begin
  while length(s) > 0 do if s[1] in [' '] then delete(s,1,1) else break;
  i := length(s);
  while i > 0 do if not (s[i] in [' ']) then break else dec(i);
  s[0] := chr(i);
  Trim := s;
end;
function TimeDateStr;
var s1,s2:string;
begin
  s1:='';
  with td do
  begin
    if (day<0) or (day>31) then day:=0;
    str(day,s2); if length(s2)=1 then s2:='0'+s2; s1:=s1+s2+'.';
    if (month<0) or (month>12) then month:=0;
    str(month,s2); if length(s2)=1 then s2:='0'+s2; s1:=s1+s2+'.';
    if year>=2100 then year:=0 else
    if year>=2000 then dec(year,2000) else
     if year<1976 then year:=76 else dec(year,1900);
    str(year,s2);
    if length(s2)=1 then s2:='0'+s2;
    s1:=s1+s2+' ';
    if (hour<0) or (hour>99) then hour:=0;
    str(hour,s2); if length(s2)=1 then s2:='0'+s2; s1:=s1+s2+':';
    if (min<0) or (min>59) then min:=0;
    str(min,s2); if length(s2)=1 then s2:='0'+s2; s1:=s1+s2;
  end;
  TimeDateStr:=s1;
end;
{����������������������������������������������������������������������}
function LZ;
begin
  while length(s)<zn do s:=ch+s;
  LZ:=s;
end;
{����������������������������������������������������������������������}
function GetTimeSt;
var s : string;
begin
  s:=lz(strf(tm div (60*60),1),2,'0');
  tm:=tm mod (60*60);
  s:=s+':'+lz(strf(tm div 60,1),2,'0')+':'+lz(strf(tm mod 60,1),2,'0');
  GetTimeSt:=s;
end;
{����������������������������������������������������������������������}
function LTrim;
begin
  while (s>'') and (s[1] in [#0..#32,#255]) do delete(s,1,1);
  LTrim:=s;
end;
{����������������������������������������������������������������������}
function RTrim;
begin
  while (s > '') and (s[length(s)] in [#0..#32,#255]) do dec(byte(s[0]));
  RTrim:=s;
end;
{����������������������������������������������������������������������}
function UpCaseCh;
begin
  if (ch>='a')and(ch<='z') then UpCaseCh:=char(ord(ch)+ord('A')-ord('a')) else
   if (ch>='�')and(ch<='�') then UpCaseCh:=char(ord(ch)+ord('�')-ord('�')) else
    if (ch>='�')and(ch<='�') then UpCaseCh:=char(ord(ch)+ord('�')-ord('�')) else
     if (ch>='�')and(ch<='�') then UpCaseCh:=char(ord(ch)+1)
      else UpCaseCh:=ch;
end;
{����������������������������������������������������������������������}
function UpCaseStr;
var i,j : Byte; S1 : String;
begin
  for i := 1 to Length(S) do S1[i] := UpCaseCh(S[i]);
  S1[0] := S[0];
  UpCaseStr := S1;
end;
{����������������������������������������������������������������������}
function StrEq;
var f : Boolean;
begin
 asm
   push ds
   les  si,a
   lds  di,b
   xor  dx,dx
   mov  cx,Count
  @Loop:
   mov al,es:[si]
   cmp al,ds:[di]
   jnz @Ex
   inc di
   inc si
   loop @Loop
   inc dl
  @Ex:
   pop ds
   mov f,dl
 end;
 StrEq:=f;
end;
{����������������������������������������������������������������������}
function LoCase(s : string) : string;
var i : byte;
begin
  for i:=1 to length(s) do case s[i] of
   'A'..'Z':inc(byte(s[i]),32);
   '�'..'�':inc(byte(s[i]),32);
   '�'..'�':inc(byte(s[i]),80);
  end;
  LoCase:=s;
end;
{����������������������������������������������������������������������}
Function Min(X,Y : Integer) : Integer; Assembler;
Asm
   Mov   Ax,X
   Cmp   Ax,Y
   Jle   @@1
   Mov   Ax,Y
@@1:
End;
{����������������������������������������������������������������������}
Function Max(X,Y : Integer) : Integer; Assembler;
Asm
   Mov   Ax,X
   Cmp   Ax,Y
   Jge   @@1
   Mov   Ax,Y
@@1:
End;
{����������������������������������������������������������������������}
function MultiTaskPresent : Boolean; assembler;
asm
   mov  ax,1687h
   int  2fh
   or   ax,ax
   jz   @1        {multitask}
   mov  ax,1600h
   int  2fh
   cmp  al,1
   je   @1
   mov  ax,160Ah
   int  2fh
   or   ax,ax
   jz   @1
   mov  ax,4680h
   int  2fh
   or   ax,ax
   jz   @1
   mov  al,0
   jmp  @2
@1:
   mov  al,1
@2:
end;
{����������������������������������������������������������������������}
procedure StartTimer; assembler;
asm
   in   al,61h
   and  al,0FCh         {Speaker - off}
   out  61h,al
   mov  al,0B4h         {10110110b - Channel 2, mode 2, both hi&lo bytes}
   out  43h,al         {Out to command register}
   mov  ax,0000h       {Counter value - maximum: FFFFh}
   out  42h,al         {Out lo byte to channel 2}
   mov  al,ah
   out  42h,al         {Out hi byte to channel 2}
   in   al,61h
   or   al,01
   out  61h,al
end;
{����������������������������������������������������������������������}
function ReadTimer : Word; assembler;
{Stop timer and read value}
asm
  in      al,42h
  mov     bl,al
  in      al,42h
  mov     bh,al
  neg     bx
  in      al,61h
  and     al,0FDh
  out     61h,al
  mov     ax,bx
end;
{����������������������������������������������������������������������}
function  readKey: char;assembler;
asm
   mov    ah,07h
   int    21h
end;
{����������������������������������������������������������������������}
function  keyPressed: boolean;assembler;
asm
   mov    ah,0Bh
   int    21h
   and    al,0FEh
end;
{����������������������������������������������������������������������}
procedure SetCursorSpeed(spd: byte); assembler;
asm
   mov  al,0f3h
   out  60h,al
   nop
   nop
   nop
   mov  al,Spd
   out  60h,al
end;
{����������������������������������������������������������������������}
function  StrF(l : longint; d : byte): string;
var s : string;
begin
  str(l:d,s);
  strf:=s;
end;
{����������������������������������������������������������������������}
function  fStr;
var b : byte; s,ts : string;
begin
  str(l,s);
  ts:=''; b:=0;
  while (b<byte(s[0])) do
  begin
    ts:=s[byte(s[0])-b]+ts;
    inc(b);
    if (b<byte(s[0])) then if (b) mod 3 = 0 then ts:=digch+ts;
  end;
  if Align = LeftAlign then b:=0 else b:=1;
  while (byte(ts[0])<maxsz) do
  begin
    if (b=0) then ts:=fillch+ts else ts:=ts+fillch;
    if Align = CenterAlign then b:=1-b;
  end;
  fStr := ts;
end;
{����������������������������������������������������������������������}
function  Size_Str;
begin
  if (sz >= 0)and(sz < 10*1024*1024)
  then Size_Str:=fstr(round(sz),0,',',' ',LeftAlign) else
   if (sz >= 10*1024*1024)and(sz <= 1.0*1024*1024*1024)
   then Size_Str:=fstr(round(sz/(1024*1024)),0,',',' ',LeftAlign)+' Mb' else
    if (sz > 1.0*1024*1024*1024)and(sz <= 128.0*1024*1024*1024)
    then Size_Str:=fstr(round(sz/(1024*1024*1024)),0,',',' ',LeftAlign)+' Gb'
     else Size_Str:='<OFL>';
end;
{����������������������������������������������������������������������}
function  Size_Str_kb;
begin
  if (sz >= 0)and(sz < 10*1024)
  then Size_Str_kb:=fstr(round(sz),0,',',' ',LeftAlign)+' Kb' else
   if (sz >= 10*1024)and(sz <= 1*1024*1024)
   then Size_Str_kb:=fstr(round(sz/(1024)),0,',',' ',LeftAlign)+' Mb' else
   if (sz >  1*1024*1024)and(sz <= 128*1024*1024)
   then Size_Str_kb:=fstr(round(sz/(1024*1024)),0,',',' ',LeftAlign)+' Gb'
     else Size_Str_kb:='<OFL>';
end;
{����������������������������������������������������������������������}
END.{So fucking what?! (c) MetallicA}
... and Justice 4 all. (c) MetallicA