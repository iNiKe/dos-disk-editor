uses dos;

const cased : boolean = false;

function uppercase(s : string) : string;
var i : integer;
begin
  for i := 1 to length(S) do s[i] := upcase(s[i]);
  uppercase := s;
end;

var f : file;
    buf : array[1..255] of char;
    s : string;
    sr : searchrec;
    srpos : longint;
    i,nr : integer;
    fnd : boolean;
    c : char;
begin
{$I-}
  findfirst('*.*',AnyFile,sr);
  srpos := 09;
  cased := false;
  s := 'Unit ';
  if not cased then s := uppercase(s);
  mkdir('moved');
  while (DosError = 0) do
  begin
    if sr.attr and Directory = 0 then
    begin
      assign(f,sr.name); reset(f,1);
      blockread(f,buf,sizeof(buf),nr);
      if IOResult = 0 then
      begin
        if nr <= srpos + length(s) then continue;
        fnd := true;
        for i := 1 to length(s) do
        begin
          c := buf[srpos+i];
          if not cased then c := upcase(c);
          if c <> s[i] then
          begin
            fnd := false;
            break;
          end;
        end;
        if fnd then
        begin
          writeln('move '+sr.name+' moved\'+sr.name);
        end;
      end;
      close(f);
    end;
    findnext(sr);
  end;
end.