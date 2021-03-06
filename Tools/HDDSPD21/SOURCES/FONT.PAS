unit Font;

interface

procedure LoadNewFont;

implementation

procedure Load8x16Font(var Font); assembler;
asm
  push    es
  push    bp
  les     bp,Font         { BP->⠡���y ᨬ����� }
  mov     cx,128          { �-�� ᨬ����� }
  mov     dx,128          { ��� ��p���� ᨬ���� }
  mov     bl,0            { ���� ���������p��p� 0 }
  mov     bh,16           { �-�� ����� � ᨬ���� }
  mov     ax,1100h        { �y���� 11h ���py���� ᨬ���� � ���������p��p }
  int     10h
  pop     bp
  pop     es
end;

procedure NewFont; external; {$L NewFont.Obj}

procedure LoadNewFont;
begin
  Load8x16Font(Pointer(@NewFont)^);
end;

begin
end.
