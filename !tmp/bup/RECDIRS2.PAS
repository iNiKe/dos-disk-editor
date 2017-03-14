uses disktool,hex,crt;
const drv = $80;

function Trim(s : string) : string;
var i : integer;
begin
  while length(s) > 0 do if s[1] in [' '] then delete(s,1,1) else break;
  i := length(s);
  while i > 0 do if not (s[i] in [' ']) then break else dec(i);
  s[0] := chr(i);
  Trim := s;
end;

var de  : tDirElement;
    dir : array[1..16] of tdirelement;
    DrvI : tDrvBIOSInfo;
    f,f2 : text;
    l,cluster,dirsf,maxfs,ss : longint;
    j,i,head,sect : byte;
    track : word;
    srne1,srne2 : array[0..10] of char;
    s,t,tt : string;
    e : integer;
    stop : boolean;

procedure showpr;
begin
{  write(#13,ss,' / ',maxfs,' [df:',dirsf,'] (',round((ss/maxfs)*100),'%)');}
end;

begin
  writeln;
  writeln('Using Drive '+hexb(drv)+'h');
  if not GetDrvBiosInfo(drv,drvi) then
  begin
    writeln('Error GetInfo!');
    halt(1);
  end;
  maxfs := longint(drvi.sehd) * longint(drvi.maxtrack+1);
  ss := CalcFS(drvi,track,head,sect);
  dirsf := 0;
  fillchar(srne1,sizeof(srne1),' ');
  srne1[0] := '.';
  fillchar(srne2,sizeof(srne2),' ');
  srne2[0] := '.'; srne2[1] := '.';
  assign(f,'dirs.txt'); reset(f);
  assign(f2,'dirs2.txt'); rewrite(f2);
  while not eof(f) do
  begin
    if keypressed then break;
    readln(f,s);
    if copy(s,1,6) <> 'SubDir' then continue;
    inc(dirsf);
    write(#13,dirsf);
{SubDir Found at sec. 24274 [T:1, H:130, S:19]  clus:135}

    t := copy(s,pos('[T:',s)+3,255);
    t[0] := chr(pos(',',t)-1);
    val(t,l,e);
    if e <> 0 then continue;
    track := l;

    t := copy(s,pos(' H:',s)+3,255);
    t[0] := chr(pos(',',t)-1);
    val(t,l,e);
    if e <> 0 then continue;
    head := l;

    t := copy(s,pos(' S:',s)+3,255);
    t[0] := chr(pos(']',t)-1);
    val(t,l,e);
    if e <> 0 then continue;
    sect := l;

    ReadDataS(drv,track,head,sect, 1,dir);
    if dir[1].nameext = srne1 then
    begin
      if dir[2].nameext = srne2 then
      begin
      end else continue
    end else continue;
    cluster  := ((dir[1].cluster) + (longint(dir[1].Clus_hi) shl 16));
    writeln(f2,'SubDir Found at sec. ',ss,' [T:',track,', H:',head,', S:',sect,']  clus:',cluster);
    stop := false;
    while (true) do
    begin
      for i := 1 to 16 do
      begin
        if dir[i].nameext[0] = #0 then break;
        if dir[i].nameext[0] = #$E5 then continue;
        for j := 0 to 10 do
        begin
          if not (dir[i].nameext[j] in ['A'..'Z',' ','.']) then
          begin
            if dir[i].size <> -1 then stop := true;
            break;
          end;
        end;
        if stop then break;
        if dir[i].size >= 0 then
        begin
          t  := trim(dir[i].name);
          tt := trim(dir[i].ext);
          if tt <> '' then t := t + '.' + tt;
          cluster  := ((dir[i].cluster) + (longint(dir[i].Clus_hi) shl 16));
          writeln(f2,'  Item: "',t:12,'" Clus: ',cluster,' Size:',dir[i].size);
        end;
      end;
      if stop then break;
      showpr;

      inc(ss);
{      if ss mod 1000 = 0 then ShowPr;}
      if keypressed then break;
      if sect >= drvi.maxsector then
      begin
        sect := 1;
        if head >= drvi.maxhead then
        begin
          head := 0;
          if track >= drvi.maxtrack then
          begin
            Track := 0;
            break;
          end else
          begin
            inc(track);
          end;
        end else
        begin
          inc(head);
        end;
      end else
      begin
        inc(sect);
      end;
      ReadDataS(drv,track,head,sect, 1,dir);
    end;
  end;
  close(f);
  close(f2);
  writeln;
end.