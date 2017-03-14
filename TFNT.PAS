uses textmodeutil;

procedure DDEFont; external; {$L Font.Obj}
var f: file;
begin
{
  Load8x16Font(Pointer(@DDEFont)^);
}
   assign(f,'fnt.bin');
   rewrite(f,1);
   blockwrite(f,Pointer(@DDEFont)^,4096);
   close(f);
end.