const nitems = 87259;
var f,nf : tex;
    cl,i,j : longint;
    st,s,ts : string;
    srp,p,e : integer;
begin
  assign(nf,'fat0s.txt'); rewrite(f);
  for i := 1 to nitems do
  begin
    write(#13,i,'/',nitems,'  (',round((i/nitems)*100),'%)');
    assign(f,'fat0.txt'); reset(f);
    for j := 1 to i do readln(f,s);
    p := pos('GSize:',s);
    if p > 0 then
    begin
      val(copy(s,p+6,255),p,e);
      if e = 0 then
      begin
        srp := p;
        j := i+1;
        while not eof(f) do
        begin
          readln(f,ts);
          p := pos('GSize:',ts);
          if p > 0 then
          begin
            val(copy(ts,p+6,255),p,e);
            if e = 0 then
            begin
              if srp > p then ;
            end
          end;
          inc(j);
          if j >= nitems then break;
        end;
      end;
    end;
    close(f);
  end;
  close(nf);
end.