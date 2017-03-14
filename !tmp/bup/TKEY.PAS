uses keyboard,hex;
var k : word;
begin
while true do
begin
  if keypressed then
  begin
    k:=getkey;
    writeln(hexw(k)+'h');
    if k=kbEsc then break;
  end;
end;
end.