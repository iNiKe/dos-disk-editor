{$X+,G+,D-,L-,S-,R-}
unit VGA;

interface
function  GetMode : Byte;
procedure SetMode(Mode : Byte);
procedure SetCursorPos(X,Y:Byte);
procedure PutPixel(X,Y:Integer; Color:Byte);
function  GetPixel(X, Y:Integer): Byte;
procedure Line(A,B,C,D,Color:integer);

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function GetMode : Byte; assembler;
asm
   mov ah,0Fh
   int 10h
   xor ah,ah
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure SetMode(Mode : Byte); assembler;
asm
   xor ax,ax
   mov al,[Mode]
   int 10h
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure SetCursorPos(X,Y:Byte);assembler;
asm
   mov  ah,2
   mov  bh,0
   mov  dl,[X]
   dec  dl
   mov  dh,[Y]
   dec  dh
   int  10h
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure PutPixel(X,Y:Integer;Color:Byte);assembler;
asm
   mov  ah,0Ch
   mov  al,[Color]
   mov  cx,[X]
   mov  dx,[Y]
   mov  bx,[0]
   int  10h
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function GetPixel(X, Y:Integer): Byte; assembler;
asm
   mov  ah,0Dh
   mov  cx,[X]
   mov  dx,[Y]
   mov  bx,[0]
   int  10h
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure Line(A,B,C,D,Color:integer);
  { This draws a line from x1,y1 to x2,y2 using the first method }

    function sgn(a:real):integer;
    begin
         if a>0 then sgn:=+1;
         if a<0 then sgn:=-1;
         if a=0 then sgn:=0;
    end;

var u,s,v,d1x,d1y,d2x,d2y,m,n:real;
    i:integer;
begin
     u:= c - a;
     v:= d - b;
     d1x:= SGN(u);
     d1y:= SGN(v);
     d2x:= SGN(u);
     d2y:= 0;
     m:= ABS(u);
     n := ABS(v);
     IF NOT (M>N) then
     BEGIN
          d2x := 0 ;
          d2y := SGN(v);
          m := ABS(v);
          n := ABS(u);
     END;
     s := INT(m / 2);
     FOR i := 0 TO round(m) DO
     BEGIN
          PutPixel(A,B,Color);
          s := s + n;
          IF not (s<m) THEN
          BEGIN
               s := s - m;
               a:= a +round(d1x);
               b := b + round(d1y);
          END
          ELSE
          BEGIN
               a := a + round(d2x);
               b := b + round(d2y);
          END;
     end;
END;

begin
end.
