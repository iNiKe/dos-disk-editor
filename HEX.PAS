(****************************************************************************
 *      Утилиты для работы с 16-тиричной системой счисления v1.00 beta 2    *
 *                                                                          *
 ****************************************************************************
 * (C) NiKe'Soft                                                            *
 ****************************************************************************)

Unit hex;

  INTERFACE


Function  HexB(B: Byte): string;
Function  HexW(W: Word): string;
Function  HexL(L: longint): string;

  IMPLEMENTATION

Function  HexB(B: Byte): string;
Const Digits: array[0..15] of char = '0123456789ABCDEF';
begin
  HexB[0]:=#2;
  HexB[1]:=Digits[B SHR   4];
  HexB[2]:=DIgits[B AND $0F];
end;

Function  HexW(W: Word): string;
var s: string;
begin
  s:='';
  S:=HexB(W SHR 8);
  S:=S+HexB(W AND $00FF);
  HexW:=S;
end;

Function  HexL(L: longint): string;
var s: string;
begin
  s:='';
  S:=HexW(l shr 16);
  S:=S+HexW(l AND $0000FFFF);
  HexL:=S;
end;

end.