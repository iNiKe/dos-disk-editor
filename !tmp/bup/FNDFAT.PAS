uses service;
const nitems = 87259;
var f,nf : text;
    cl,i,j : longint;
    st,s,ts : string;
    srp,e : integer;
    fnd,p,maxit : longint;
begin
  val(paramstr(1),maxit,e);
  if e <> 0 then maxit := 0;
  assign(f,'fat0.txt'); reset(f);
  i := 0; fnd := 0;
  assign(nf,'fat0s.txt'); rewrite(nf);
  while not eof(f) do
  begin
    if keypressed then break;
    inc(i);
    readln(f,s);
    p := pos('GSize:',s);
    if p > 0 then
    begin
      ts := trim(copy(s,p+6,255));
      val(ts,p,e);
      if e = 0 then
      begin
        if p > maxit then
        begin
          inc(fnd);
          writeln(nf,s);
        end;
      end;
    end;
    write(#13,i,'/',nitems,'  (',round((i/nitems)*100),'%)  Found:',fnd);
  end;
  close(f);
  close(nf);
end.