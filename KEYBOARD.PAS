Unit KeyBoard;

  INTERFACE

CONST
  kbEsc       = $011B;  kbAltSpace  = $C200;  kbCtrlIns    = $9200;
  kbShiftIns  = $C300;  kbCtrlDel   = $9300;  kbShiftDel   = $C400;
  kbBack      = $0E08;  kbCtrlBack  = $0E7F;  kbShiftTab   = $0F00;
  kbTab       = $0F09;  kbAltQ      = $1000;  kbAltW       = $1100;
  kbAltE      = $1200;  kbAltR      = $1300;  kbAltT       = $1400;
  kbAltY      = $1500;  kbAltU      = $1600;  kbAltI       = $1700;
  kbAltO      = $1800;  kbAltP      = $1900;  kbCtrlEnter  = $1C0A;
  kbEnter     = $1C0D;  kbAltA      = $1E00;  kbAltS       = $1F00;
  kbAltD      = $2000;  kbAltF      = $2100;  kbAltG       = $2200;
  kbAltH      = $2300;  kbAltJ      = $2400;  kbAltK       = $2500;
  kbAltL      = $2600;  kbAltZ      = $2C00;  kbAltX       = $2D00;
  kbAltC      = $2E00;  kbAltV      = $2F00;  kbAltB       = $3000;
  kbAltN      = $3100;  kbAltM      = $3200;  kbF1         = $3B00;
  kbF2        = $3C00;  kbF3        = $3D00;  kbF4         = $3E00;
  kbF5        = $3F00;  kbF6        = $4000;  kbF7         = $4100;
  kbF8        = $4200;  kbF9        = $4300;  kbF10        = $4400;
  kbHome      = $4700;  kbUp        = $4800;  kbPgUp       = $4900;
  kbGrayMinus = $4A2D;  kbLeft      = $4B00;  kbRight      = $4D00;
  kbGrayPlus  = $4E2B;  kbEnd       = $4F00;  kbDown       = $5000;
  kbPgDn      = $5100;  kbIns       = $5200;  kbDel        = $5300;
  kbShiftF1   = $5400;  kbShiftF2   = $5500;  kbShiftF3    = $5600;
  kbShiftF4   = $5700;  kbShiftF5   = $5800;  kbShiftF6    = $5900;
  kbShiftF7   = $5A00;  kbShiftF8   = $5B00;  kbShiftF9    = $5C00;
  kbShiftF10  = $5D00;  kbCtrlF1    = $5E00;  kbCtrlF2     = $5F00;
  kbCtrlF3    = $6000;  kbCtrlF4    = $6100;  kbCtrlF5     = $6200;
  kbCtrlF6    = $6300;  kbCtrlF7    = $6400;  kbCtrlF8     = $6500;
  kbCtrlF9    = $6600;  kbCtrlF10   = $6700;  kbAltF1      = $6800;
  kbAltF2     = $6900;  kbAltF3     = $6A00;  kbAltF4      = $6B00;
  kbAltF5     = $6C00;  kbAltF6     = $6D00;  kbAltF7      = $6E00;
  kbAltF8     = $6F00;  kbAltF9     = $7000;  kbAltF10     = $7100;
  kbCtrlPrtSc = $7200;  kbCtrlLeft  = $7300;  kbCtrlRight  = $7400;
  kbCtrlEnd   = $7500;  kbCtrlPgDn  = $7600;  kbCtrlHome   = $7700;
  kbAlt1      = $7800;  kbAlt2      = $7900;  kbAlt3       = $7A00;
  kbAlt4      = $7B00;  kbAlt5      = $7C00;  kbAlt6       = $7D00;
  kbAlt7      = $7E00;  kbAlt8      = $7F00;  kbAlt9       = $8000;
  kbAlt0      = $8100;  kbAltMinus  = $8200;  kbAltEqual   = $8300;
  kbCtrlPgUp  = $8400;  kbAltBack   = $0E00;  kbNoKey      = $0000;
  kbDoubleAlt = $3800;  kbAltLeft   = $9B00;  kbAltRight   = $9D00;
  kbAltTAB    = $A500;  kbCtrlTAB   = $9400;  kbCtrlESC    = $0E00;
  kbAltEnter  = $1C00;  kbDoubleCtrl = $1D00; kbGrayAst    = $372A;
  kbSpace     = $3920;  kbCtrlGPlus  = $9000; kbCtrlGMinus = $8E00;
  kbCtrlGAst  = $9600;  kbAltSlash   = $A400; kbAltIns     = $A200;
  kbShortCut  = $FFFF;  kbAltDel     = $A300; kbCtrlSlash  = $9500;
  kbAltGPlus  = $4E00;  kbAltGMinus  = $4A00; kbAltPgUp    = $9900;
  kbAltPgDn   = $A100;  kbF11        = $8500; kbF12        = $8600;
  kbShiftF11  = $8700;  kbShiftF12   = $8800; kbAltHome    = $9700;
  kbCtrlF11   = $8900;  kbCtrlF12    = $8A00; kbAltEnd     = $9F00;
  kbAltF11    = $8B00;  kbAltF12     = $8C00; kbCtrlBSlsh  = $2B1C;
  kbCtrlUp    = $8D00;  kbCtrlDown   = $9100; kbCtrlSTab   = kbAltTab;
  kbAltDot    = $3400;  kbAst        = $092A;

  kbCtrlA = $1E01;  kbCtrlB = $3002;  kbCtrlC = $2E03;  kbCtrlD = $2004;
  kbCtrlE = $1205;  kbCtrlF = $2106;  kbCtrlG = $2207;  kbCtrlH = $2308;
  kbCtrlI = $1709;  kbCtrlJ = $240A;  kbCtrlK = $250B;  kbCtrlL = $260C;
  kbCtrlM = $320D;  kbCtrlN = $310E;  kbCtrlO = $180F;  kbCtrlP = $1910;
  kbCtrlQ = $1011;  kbCtrlR = $1312;  kbCtrlS = $1F13;  kbCtrlT = $1414;
  kbCtrlU = $1615;  kbCtrlV = $2F16;  kbCtrlW = $1117;  kbCtrlX = $2D18;
  kbCtrlY = $1519;  kbCtrlZ = $2C1A;

  shsNone   = $00;
  shsRShift = $01;
  shsLShift = $02;
  shsCtrl   = $04;
  shsAlt    = $08;
  shsCaps   = $10;
  shsScroll = $20;
  shsNum    = $40;

function  GetKey : word;
function  KeyPressed : boolean;

var ShiftState: Byte absolute $40:$17;


  IMPLEMENTATION

function GetKey : word; {assembler;}
var key : record case byte of 0:(w:word);1:(chc : char ;scan : byte); end;
begin
  asm
        MOV     AH,11h
        INT     16H
        MOV     AX,0
        JE      @@1
        MOV     AH,10h
        INT     16H


        cmp     ah,$E0
        jne     @NotExt

        cmp     al,$0D
        jne     @NotEnter
        mov     bx,kbEnter
        xchg    ax,bx
@NotEnter:

@NotExt:

@@1:
    mov key,ax
  end;
  if (key.chc = #$e0) and
     (key.scan in [$52,$92,$A2,
                   $47,$77,$97,
                   $49,$84,$99,
                   $93,$53,$A3,
                   $4F,$75,$9F,
                   $51,$76,$A1,
                   $48,$8D,$98,
                   $4B,$73,$9B,
                   $50,$91,$A0,
                   $4D,$9D,$74])
  then key.ChC := #00
  else
    if (key.ChC >= '0') and (key.ChC <= '9') and
     (ShiftState and 3 <> 0) then key.ChC := #0;
  GetKey:=word(key);
end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function  keyPressed: boolean;assembler;
asm
   mov    ah,0Bh
   int    21h
   and    al,0FEh
end;
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}

END.