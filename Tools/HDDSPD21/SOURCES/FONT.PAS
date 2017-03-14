unit Font;

interface

procedure LoadNewFont;

implementation

procedure Load8x16Font(var Font); assembler;
asm
  push    es
  push    bp
  les     bp,Font         { BP->таблицy символов }
  mov     cx,128          { К-во символов }
  mov     dx,128          { Код пеpвого символа }
  mov     bl,0            { Блок знакогенеpатоpа 0 }
  mov     bh,16           { К-во линий в символе }
  mov     ax,1100h        { Фyнкция 11h загpyзить символы в знакогенеpатоp }
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
