uses textmodeutil;
begin
 asm nop; end;
 writeln;
 cwritest('~'+char(16*04+15)+'~�����',-1,-1);
 writeln;
 cwritest('~'+char(16*00+09)+'~�����',-1,-1);
 writeln;
{
 asm mov byte ptr [0058h],red*16+white end; {⨯� TextAttr:=  :}
{
 asm mov byte ptr [0058h],black*16+lightblue end; {⨯� TextAttr:=  :}
end.