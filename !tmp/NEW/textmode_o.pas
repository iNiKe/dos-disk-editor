Unit TextModeUtil;
(****************************************************************************
 *             Œ®¤ã«ì ¤«ï à ¡®âë ¢ â¥ªáâ®¢®¬ à¥¦¨¬¥ v1.00 beta 3            *
 ****************************************************************************
 * ş ‚ ®á­®¢­®¬, ­  assembler-¥                                             *
 * ş ¯â¨¬¨§¨à®¢ ­ ¯®¤ ¡ëáâàë¥ â çª¨ ;)                                     *
 *                                                        Since: 30/04/2000 *
 * (c) NiKe'Soft UnLtd.                             Last UpDate: 10/03/2001 *
 ****************************************************************************)
{$A+,B-,D+,E+,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}

  INTERFACE

type tBorder = array [1..8] of char;
     pScreen_Buf = ^tScreen_Buf;
     tScreen_Buf = array[0..80*25*2] of char;

const
     Text_Seg   : word = $B800;
     oText_Seg  : word = $B800;
     Scr_Buf    : pScreen_Buf = nil;
     Text_MaxX  : word = 80;
     Text_MaxY  : word = 25;
     FG_Color   : byte = 07; {Foreground text color}
     BG_Color   : byte = 00; {Background text color}
     nBrd       = 6;
     Borders : array[0..nBrd] of tBorder = ((' ',' ',' ',' ',' ',' ',' ',' '),
                                            ('Ú','Ä','¿','³','À','Ä','Ù','³'),
                                            ('É','Í','»','º','È','Í','¼','º'),
                                            ('Õ','Í','¸','³','Ô','Í','¾','³'),
                                            ('Ö','Ä','·','º','Ó','Ä','½','º'),
                                            ('Ö','Ä','·','º','È','Í','¼','º'),
                                            ('É','Í','»','º','Ó','Ä','½','º'));
     brd_None   = 0;
     brd_Single = 1;
     brd_Double = 2;
     brd_Mix1   = 3;
     brd_Mix2   = 4;
     brd_Mix3   = 5;
     brd_Mix4   = 6;

     cBlack    = 00;
     cBlue     = 01;
     cGreen    = 02;
     cCyan     = 03;
     cRed      = 04;
     cMagenta  = 05;
     cBrown    = 06;
     cGray     = 07;
     cDGray    = 08;
     cLBlue    = 09;
     cLGreen   = 10;
     cLCyan    = 11;
     cLRed     = 12;
     cLMagenta = 13;
     cYellow   = 14;
     cWhite    = 15;


procedure WRetr;
procedure WRetrI;
procedure Set_Blinking(Switch : byte);
procedure Set_Mode(Mode : byte);
function  Get_Mode : Byte;
procedure Set_Cursor(Mode : boolean);
procedure Set_Cursor_Size(cY1,cY2: byte);
procedure Set_Max_Cursor;
procedure Set_Cursor_Pos(X,Y : byte);
procedure Get_Cursor_Pos(var X,Y : byte);
function  GetFG(xx,yy : word) : byte;
function  GetBG(xx,yy : word) : byte;
procedure SetFG(xx,yy : word; FG : byte);
procedure SetBG(xx,yy : word; BG : byte);
procedure VidB(x1,y1,x2: word; bg: byte);
procedure VidF(x1,y1,x2: word; fg: byte);
procedure RecolBG(x1,y1,x2,y2,bg : byte);
procedure RecolFG(x1,y1,x2,y2,fg : byte);
procedure RecolA(x1,y1,x2,y2,attr : byte);
procedure Fil(x1,y1,x2: word; chb : char);
procedure FillScr(x1,y1,x2,y2 : word; chb : char);
procedure PutScr(num : word);
procedure SaveScr(num : word);
function  GetCh(xx,yy : word) : char;
function  PA(fg,bg : byte) : byte;
procedure SetChar(charnum : word; var data);
procedure PutCh (xx,yy : word; chb : char);
procedure PutChA(xx,yy : word; chb : char; attr : byte);
procedure PutChF(xx,yy : word; chb : char; fg : byte);
procedure PutChB(xx,yy : word; chb : char; bg : byte);
function  GetAttr(xx,yy : word) : byte;
procedure SetAttr(xx,yy : word; attr : byte);
procedure WriteSt (st : string; xx,yy : integer);
function  ColSt(col : byte) : string;
procedure cWriteSt(st : string; xx,yy : integer);
procedure WriteStF(st : string; xx,yy : integer; FG: byte);
procedure WriteStA(st : string; xx,yy : integer; attr: byte);
function  Offset(xx,yy : word) : word;
procedure CharVLine(x1,y1,y2,c : byte; ch : char);
procedure CharHLine(x1,y1,x2,c : byte; ch : char);
procedure Scroll_Down(x1,y1,x2,y2: byte; yp: integer);
procedure Scroll_Up(x1,y1,x2,y2: byte; yp: integer);
procedure Draw_Border(x1,y1,x2,y2,BC : byte; Border : tBorder);
procedure Set_Window(x1,y1,x2,y2 : byte; brd : tBorder; bc,fg,bg,hdc: byte;
                     fillch : char; Header : string; Shadow : boolean);
procedure Load8x16Font(var Font);

  IMPLEMENTATION Uses Service;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Cursor_Pos; assembler;
asm
   mov  ah,2
   mov  bh,0   {page}
   mov  dl,[X]
   dec  dl
   mov  dh,[Y]
   dec  dh
   int  10h
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Get_Cursor_Pos; {assembler;}
var xx,yy : byte;
begin
  asm
     mov  ah,3
     mov  bh,0  {page}
     int  10h
     inc  dl
     mov  [xx],dl
     inc  dh
     mov  [yy],dh
  end;
  x:=xx; y:=yy;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Mode; assembler;
asm
   xor  ah,ah
   mov  al,Mode
   int  10h
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function Get_Mode : Byte; assembler;
asm
   mov ah,0Fh
   int 10h
   xor ah,ah
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WRetr; Assembler;
asm
   mov dx,3DAh
@l1:
   in  al,dx
   and al,08h
   jnz @l1
@l2:
   in  al,dx
   and al,08h
   jz  @l2
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WRetrI; Assembler;
asm
   cli
   mov dx,3DAh
@l1:
   in  al,dx
   and al,08h
   jnz @l1
@l2:
   in  al,dx
   and al,08h
   jz  @l2
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Blinking; assembler;
asm
   mov  ax,1003h
   mov  bl,Switch
   int  10h
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure VidB; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, 50h
   mov  bx, [y1]
   dec  bx
   mul  bx
   add  ax, [x1]
   dec  ax
   shl  ax, 1
   mov  cx, [x2]
   sub  cx, [x1]
   inc  cx
   mov  bx, ax
@l1:
   inc  bx
   mov  ah, es:[bx]
   mov  al, ah
   shr  al, 4
   shl  al, 4
   sub  ah, al
   mov  al, bg
   shl  al, 4
   add  ah, al
   mov  es:[bx], ah
   inc  bx
loop @l1
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure VidF; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [y1]
   dec  bx
   mul  bx
   add  ax, [x1]
   dec  ax
   shl  ax, 1
   mov  cx, [x2]
   sub  cx, [x1]
   inc  cx
   mov  bx, ax
@l1:
   inc  bx
   mov  ah, es:[bx]
   mov  al, ah
   shr  al, 4
   shl  al, 4
   mov  ah, fg
   add  al, ah
   mov  es:[bx], al
   inc  bx
loop @l1
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Fil; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [y1]
   dec  bx
   mul  bx
   add  ax, [x1]
   dec  ax
   shl  ax, 1
   mov  cx, [x2]
   sub  cx, [x1]
   inc  cx
   mov  bx, ax
   mov  al, [chb]
@l1:
   mov  es:[bx], al
   inc  bx
   inc  bx
loop @l1
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetCh; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   mov  bx, ax
   mov  al, es:[bx]
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  PA; assembler;
asm
   mov  al, bg
   shl  al, 4
   add  al, fg
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure PutCh; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   mov  bx, ax
   mov  al, [chb]
   mov  es:[bx], al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure PutChA; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   mov  bx, ax
   mov  al, [chb]
   mov  es:[bx], al
   inc  bx
   mov  al, [attr]
   mov  es:[bx], al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure PutChF; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   mov  bx, ax
   mov  al, [chb]
   mov  es:[bx], al
   inc  bx
   mov  al, es:[bx]
   mov  ah, al
   shr  al, 4
   shl  al, 4
   add  al, fg
   mov  es:[bx], al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure PutChB; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   mov  bx, ax
   mov  al, [chb]
   mov  es:[bx], al
   inc  bx
   mov  al, es:[bx]
   mov  ah, al
   shr  al, 4
   sub  ah, al
   mov  al, bg
   inc  al
   shl  al, 4
   add  ah, al
   mov  es:[bx], ah
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetAttr; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  al, es:[bx]
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure SetAttr; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  al, [attr]
   mov  es:[bx], al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetFG; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  al, es:[bx]
   and  al, $0F
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  GetBG; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  al, es:[bx]
   shr  al, 4
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure SetFG; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  al, es:[bx]
   and  al, $F0
   add  al, FG
   mov  es:[bx],al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure SetBG; assembler;
asm
   cli
   push es
   mov  ax, text_seg
   mov  es, ax
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
   inc  ax
   mov  bx, ax
   mov  ah, es:[bx]
   and  ah, $0F
   mov  al, BG
   add  al, ah
   mov  es:[bx],al
   pop  es
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure SaveScr; assembler;
asm
   cmp  num, 0
   jc   @exit
   cmp  num, 9
   jnc  @exit
   push es
   push ds
   mov  ax, text_seg
   mov  es, ax
   mov  ds, ax
   mov  ax, $1000
   mul  num
   mov  di, ax
   xor  si, si
   mov  cx, 4000
   cld  {inc}
   rep movsb
   pop  ds
   pop  es
@exit:
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure PutScr; assembler;
asm
   cmp  num, 0
   jc   @exit
   cmp  num, 9
   jnc  @exit
   cli
   push es
   push ds
   mov  ax, text_seg
   mov  es, ax
   mov  ds, ax
   xor  di, di
   mov  ax, $1000
   mul  num
   mov  si, ax
   mov  cx, 4000
   cld  {inc}
   rep movsb
   pop  ds
   pop  es
   sti
@exit:
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  Offset; assembler;
asm
   mov  ax, text_maxx
   mov  bx, [yy]
   dec  bx
   mul  bx
   add  ax, [xx]
   dec  ax
   shl  ax, 1
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Cursor_Size; assembler;
asm
   mov  ah, 01h
   mov  ch, [cy1]
   mov  cl, [cy2]
   int  10h
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Cursor; assembler;
asm
   cli
   mov  ah, 01h
   cmp  Mode,0
   jz   @OFF
   mov  ch,0bh
   mov  cl,0ch
   jmp  @Done
@OFF:
   mov  ch,20h
   xor  cl,cl
@Done:
   int  10h
   sti
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Max_Cursor; assembler;
asm
   mov  ah,01h
   xor  ch,ch
   mov  cl,07h
   int  10h
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure FillScr;
var a : word;
begin
  for a := y1 to y2 do Fil(x1,a,x2,chb);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure RecolBG;
var x,y: word;
begin
  for y:=y1 to y2 do VidB(x1,y,x2,bg);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure RecolFG;
var y: word;
begin
  for y:=y1 to y2 do VidF(x1,y,x2,fg);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure RecolA;
var x,y: word;
begin
  for x:=x1 to x2 do for y:=y1 to y2 do mem[text_seg:offset(x,y)+1]:=attr;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure SetChar;
var o: word;
begin
  asm
     mov  ax, charnum
     mov  o, ax
     shl  o, 6
  end;
  inline($fa);
  portw[$3c4] := $0402;
  portw[$3c4] := $0704;
  portw[$3ce] := $0204;
  portw[$3ce] := $0005;
  portw[$3ce] := $0006;
  move(data, ptr($a000, o)^, 16);
  portw[$3c4] := $0302;
  portw[$3c4] := $0304;
  portw[$3ce] := $0004;
  portw[$3ce] := $1005;
  portw[$3ce] := $0e06;
  inline($fb);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WriteSt;
var b: byte; x,y: word;
begin
  x:=xx; y:=yy;
  for b:=1 to length(st) do
  begin
    putch(x,y,st[b]);
    if x=text_maxx then begin x:=1; if y<text_maxy then inc(y) else break end else
    inc(x);
  end;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function  ColSt;
begin
  ColSt:='~'+char(col)+'~';
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure cWriteSt;
var a,b: byte;
    x,y: byte;
    mcur : boolean;
    label Inc_B;
  procedure Inc_Y;
  begin
    if (y>=Text_MaxY) then
    begin
      Scroll_Up(01,02,text_maxx,text_maxy,1);
      y:=text_maxy;
    end else
    inc(y);
  end;
begin
  x:=xx; y:=yy; a:=255;
  if (xx<=0)or(yy<=0) then
  begin
    get_cursor_pos(x,y);
    if (xx>0) then x:=xx;
    if (yy>0) then y:=yy;
    mcur:=true;
  end;
  b:=1;
  while (b<=length(st)) do
  begin
    if (st[b]='~') then
    begin
      if b<length(st) then if st[b+1]<>'~' then
      begin
        if b+2<=length(st) then if st[b+2]='~' then
        begin
          a:=byte(st[b+1]);
          inc(b,2);
          goto Inc_B;
        end;
      end else goto Inc_B;;
    end else
    if (st[b]=#13) then begin x:=1; goto Inc_B; end else
    if (st[b]=#10) then begin inc_Y; goto Inc_B; end;

    if b<=length(st) then if a=255 then putch(x,y,st[b]) else putcha(x,y,st[b],a);
    if (x>=text_maxx) then begin x:=1; inc_Y; end else
    inc(x);
Inc_B:
    inc(b);
  end;
  if mcur then set_cursor_pos(x,y);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WriteStF;
var b: byte; x,y : word;
begin
  x := xx; y := yy;
  for b:=1 to length(st) do
  begin
    putcha(x,y,st[b],(getattr(x,y) div 16)*16+FG);
    if x >= text_maxx then begin x:=0; if y<text_maxy then inc(y) else break end else inc(x);
  end;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure WritestA;
var b: byte; x,y: word;
begin
  x:=xx; y:=yy;
  for b:=1 to length(st) do
  begin
    putchA(x,y,st[b],attr);
    if x=text_maxx then begin x:=1; if y<text_maxy then inc(y) else break end else
    inc(x);
  end;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Scroll_Up;
var  xx,yy: byte;
begin
  for yy:=y1 to y2 do for xx:=x1 to x2 do putchf(xx,yy-yp,getch(xx,yy),getfg(xx,yy));
  fil(x1,y2,x2,' ');
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Scroll_Down;
var  xx,yy: byte;
begin
  for yy:=y2 downto y1 do for xx:=x1 to x2 do putchf(xx,yy+yp,getch(xx,yy),getfg(xx,yy));
  fil(x1,y1,x2,' ');
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure CharVLine;
var y : byte;
begin
  for y:=y1 to y2 do PutChA(x1,y,ch,c);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure CharHLine;
var x : byte;
begin
  for x:=x1 to x2 do PutChA(x,y1,ch,c);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Draw_Border;
var a : byte;
begin
  if (x1=x2)or(y1=y2) then exit;
  if x1>x2 then begin a:=x1; x1:=x2; x2:=a; end;
  if y1>y2 then begin a:=y1; y1:=y2; y2:=a; end;
  for a:=x1+1 to x2-1 do
  begin
    putchf(a,y1,Border[2],BC);
    putchf(a,y2,Border[6],BC);
  end;
  for a:=y1+1 to y2-1 do
  begin
    putchf(x1,a,Border[4],BC);
    putchf(x2,a,Border[8],BC);
  end;
  putchf(x1,y1,Border[1],BC);
  putchf(x2,y1,Border[3],BC);
  putchf(x1,y2,Border[5],BC);
  putchf(x2,y2,Border[7],BC);
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Set_Window;
var a,b : word;
begin
  if (x1=x2)or(y1=y2) then exit;
  if x1>x2 then begin a:=x1; x1:=x2; x2:=a; end;
  if y1>y2 then begin a:=y1; y1:=y2; y2:=a; end;
  Draw_Border(x1,y1,x2,y2,bc, Brd);
  if fillch<>#0 then
  begin
    recolbg(x1,y1,x2,y2,bg);
    recolfg(x1+1,y1+1,x2-1,y2-1,fg);
    FillScr(x1+1,y1+1,x2-1,y2-1,fillch);
  end;
  if (Shadow) then
  begin
    b := min(x2+1,text_maxx);
    for a:=x1+1 to b do setattr(a,y2+1,08);
    b := min(y2+1,text_maxy);
    for a:=y1+1 to b do setattr(x2+1,a,08);
  end;
  if (byte(header[0]) > 0)and(x2-x1 > 2) then
  begin
    a := x2-x1; b := a-1;
    if (byte(header[0]) > b) then
    begin
      header[0] := chr(b);
      b := x1+1;
    end else b := x1+1 + b div 2 - (byte(header[0])) div 2;
    if byte(header[0]) > 0 then writestA(header,b,y1,hdc);
  end;
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure Load8x16Font; assembler;
asm
  push    es
  push    bp
  les     bp,Font         { BP->â ¡«¨æy á¨¬¢®«®¢ }
  mov     cx,256          { Š-¢® á¨¬¢®«®¢ }
  mov     dx,000          { Š®¤ ¯¥p¢®£® á¨¬¢®«  }
  mov     bl,0            { «®ª §­ ª®£¥­¥p â®p  0 }
  mov     bh,16           { Š-¢® «¨­¨© ¢ á¨¬¢®«¥ }
  mov     ax,1100h        { ”y­ªæ¨ï 11h § £py§¨âì á¨¬¢®«ë ¢ §­ ª®£¥­¥p â®p }
  int     10h
  pop     bp
  pop     es
end;
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

BEGIN
  New(Scr_Buf);
END.
... and Justice 4 all. (c) MetallicA                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       