var f : text;
    s : string;
    i : integer;
begin
  assign(f,'dirs.dat'); reset(f);
  while not eof(f) do
  begin
    readln(f,s);
    i := pos('clus:',s);
    if i > 0 then
    begin
      s := copy(s,i+5,255);
      for i := 1 to length(s) do if not (s[i] in ['0'..'9']) then break;
      if i < length(s) then s[0] := chr(i);
      writeln(s);
    end;
  end;
  close(f);
end.