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
    f : text;
    cluster,dirsf,maxfs,ss : longint;
    i,head,sect : byte;
    track : word;
    srne1,srne2 : array[0..10] of char;
    t,tt : string;

procedure showpr;
begin
  write(#13,ss,' / ',maxfs,' [df:',dirsf,'] (',round((ss/maxfs)*100),'%)');
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
  track := 000000;
  head  := 001;
  sect  := 001;
  ss := CalcFS(drvi,track,head,sect);
  dirsf := 0;
  assign(f,'dirs.txt'); rewrite(f);
  fillchar(srne1,sizeof(srne1),' ');
  srne1[0] := '.';
  fillchar(srne2,sizeof(srne2),' ');
  srne2[0] := '.'; srne2[1] := '.';
  while (true) do
  begin
    ReadDataS(drv,track,head,sect, 1,dir);
    if dir[1].nameext = srne1 then
    begin
      if dir[2].nameext = srne2 then
      begin
        inc(dirsf);
        cluster  := ((dir[1].cluster) + (longint(dir[1].Clus_hi) shl 16));
        writeln(f,'SubDir Found at sec. ',ss,' [T:',track,', H:',head,', S:',sect,']  clus:',cluster);
        writeln(#13#10'SubDir Found at sec. ',ss,' [T:',track,', H:',head,', S:',sect,']  clus:',cluster);
        for i := 3 to 16 do
        begin
          if dir[i].nameext[0] = #0 then break;
          t  := trim(dir[i].name);
          tt := trim(dir[i].ext);
          if tt <> '' then t := t + '.' + tt;
          cluster  := ((dir[i].cluster) + (longint(dir[i].Clus_hi) shl 16));
          writeln(f,'  Item: "',t:13,'" Clus: ',cluster,' Size:',dir[i].size);
        end;
        showpr;
      end;
    end;

    inc(ss);
    if ss mod 1000 = 0 then ShowPr;
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
  end;
  close(f);
end.