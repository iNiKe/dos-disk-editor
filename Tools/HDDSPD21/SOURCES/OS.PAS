{$X+,G+,D-,L-,S-,R-}
Unit os;

INTERFACE

const
  mtNone        = 0; {No MultiTasking}
  mtWindows     = 1; {Windows}
  mtOS2         = 2; {OS/2}
  mtDV          = 3; {DESQview}
  mtTV          = 4; {TopView}

Type
  TaskRec = record
    OS      : Word;
    Version : Word; {writeln('Version ',hi(Version), '.', lo(Version) );}
    Delay   : Word;
  end;

Const
  Task    : TaskRec = (
    OS      : 0;
    Version : 0;
    Delay   : 100
  );

Procedure TimeSlice;
Procedure InitMulti;

IMPLEMENTATION

uses dos;

Procedure InitMulti; Assembler;
Asm
  mov  Task.OS, 0
  mov  Task.Version, 0
  mov  Ah, 30h
  mov  Al, 01h
  int  21h
  cmp  Al, 20
  je   @OS2
  mov  Ax, 160Ah
  int  2Fh
  cmp  Ax, 0
  je   @Windows
  mov  Ax, 1022h
  mov  Bx, 0000h
  int  15h
  cmp  Bx, 0
  jne  @DESQview
  mov  Ah, 2Bh
  mov  Al, 01h
  mov  Cx, 4445h
  mov  Dx, 5351h
  int  21h
  cmp  Al, $FF
  jne  @TopView
  jmp  @Fin
@Windows:
  Mov  Task.OS, 1
  Mov  Task.Version, BX
  jmp  @Fin
@OS2:
  Mov  Task.OS, 2
  Mov  Bh, Ah
  Xor  Ah, Ah
  Mov  Cl, 10
  Div  Cl
  Mov  Ah, Bh
  Xchg Ah, Al
  cmp  ax,021Eh
  jne  @1
  mov  ax,0300h
@1:
  cmp  ax,0228h
  jne  @2
  mov  ax,0400h
@2:
  Mov  Task.Version, AX
  jmp  @Fin
@DESQview:
  mov  Task.OS, 3
  jmp  @Fin
@TopView:
  mov  Task.OS, 4
@Fin:
End;


Procedure TimeSlice; Assembler;
Asm
  cmp  Task.OS, 0
  je   @Fin
  cmp  Task.OS, 1
  je   @Win_OS2
  cmp  Task.OS, 2
  je   @Win_OS2
@DV_TV:
  mov  Ax, 1000h
  int  15h
  jmp  @Fin
@Win_OS2:
  mov  Ax, 1680h
  int  2Fh
@Fin:
End;

end.
