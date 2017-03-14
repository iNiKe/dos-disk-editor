{$X+,G-,D-,L+,S-,R-}
unit Timer;

interface

var
  BIOSTimer : LongInt absolute $40:$6c;

procedure StartTimer;
function ReadTimer : Word;

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure StartTimer; assembler;
asm
  in   al,$61
  and  al,$FC         {Speaker - off}
  out  $61,al
  mov  al,$B4         {10110110b - Channel 2, mode 2, both hi&lo bytes}
  out  $43,al         {Out to command register}
  mov  ax,$0000       {Counter value - maximum: FFFFh}
  out  $42,al         {Out lo byte to channel 2}
  mov  al,ah
  out  $42,al         {Out hi byte to channel 2}
  in   al,$61
  or   al,$01
  out  $61,al
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
function ReadTimer : Word; assembler;
{Stop timer and read value}
asm
  in      al,$42
  mov     bl,al
  in      al,$42
  mov     bh,al
  neg     bx
  in      al,$61
  and     al,$FD
  out     $61,al
  mov     ax,bx
end;

begin
end.
