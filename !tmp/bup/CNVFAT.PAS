uses crt;
const cluster_length = 16;
      incsz = cluster_length*512;

var f : file;
    ft : text;
    s : string;
    nitems,tfp,tl,startc,gsz,dcl,ncl,fp,l : longint;
    stop : boolean;
begin
  assign(f,'fat0.dat'); reset(f,4);
  assign(ft,'fat0.txt'); rewrite(ft);
  ncl := filesize(f); dcl := 0;
  nitems := 0;
  stop := false;
  while not eof(f) do
  begin
    repeat
      if keypressed then if readkey = #27 then break;
      if eof(f) then break;
      blockread(f,l,1);
    until (l > 0){and(l < $0fffffff)};
    if stop then break;
    inc(nitems);
    gsz := incsz;
    inc(dcl);
    fp := filepos(f);
    startc := fp-1;
    seek(f,fp-1);
    tl := 0;
    blockwrite(f,tl,1);
    if dcl < ncl then
    while {(not eof(f))and}(l > 0)and(l < $0ffffff0) do
    begin
      if keypressed then if readkey = #27 then break;
      seek(f,l-2);
      blockread(f,l,1);
      tfp := filepos(f);
      seek(f,tfp-1);
      blockwrite(f,tl,1);
      gsz := gsz + incsz;
      inc(dcl);
      if dcl >= ncl then break;
    end;
    if stop then break;
    seek(f,fp);
    writeln(ft,'Item  SClust:',startc:10,',  GSize:',gsz:8);
    write(#13,filepos(f),'/',ncl,'  (',round((filepos(f)/ncl)*100),'%)  nItems:',nitems);
  end;
  close(f);
  close(ft);
end.