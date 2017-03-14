uses vfat;
var b : byte;
begin
  writeln;
  for b:=0 to 255 do if DosChar(char(b)) then write((b),' ');
  writeln;
  for b:=0 to 255 do if WinChar(char(b)) then write(char(b));
  writeln;
end.