uses textmodeutil,crt;
var l : longint;
begin
  for l:=0 to 10000 do
  begin
    delay(30);
    if keypressed then break;
    cwritest(char(random(26)+ord('a')),-1,-1);
  end;
end.