uses disktool,service;
var ft : text;
    tfs,cluster,fs,c : longint;
    dir : array[1..16] of tdirelement;
    j,dirsf,i : integer;
    srne1,srne2 : array[0..10] of char;
    s,t,tt : string;
    stop : boolean;
begin
  assign(ft,'dirc.dat'); reset(ft);
  fillchar(srne1,sizeof(srne1),' ');
  srne1[0] := '.';
  fillchar(srne2,sizeof(srne2),' ');
  srne2[0] := '.'; srne2[1] := '.';
  stop := false;

  c :=
  for c := 2 to fd^.clusters - 2 do
  begin
    s := strf(c,1) +' / '+ strf(fd^.clusters,1) + '  ('+strf(round((c / fd^.clusters)*100),1)+'%) DirsF:'+strf(dirsf,1);
    while length(s) < 80 do s := s + ' ';
    writestf(s,2,25,14);
    if keypressed then break;
    fs := get_cluster_sector(fd^,c);
    if fs <= 0 then break;
    fs := fd^.start_sector+fs;
    stop := false;
    ReadAbsSector(fd^.Drive,fs,1,dir);
    if dir[1].nameext = srne1 then
    begin
      if dir[2].nameext = srne2 then
      begin
        inc(dirsf);
        cluster  := ((dir[1].cluster) + (longint(dir[1].Clus_hi) shl 16));
        writeln(ft,'SubDir Found at sec. ',fs,'  clus:',cluster);
        for i := 3 to 16 do
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
            writeln(ft,'  Item: "',t:13,'" Clus: ',cluster,' Size:',dir[i].size);
          end;
        end;
        for tfs := fs+1 to fs+fd^.cluster_length-1 do
        begin
          if keypressed then break;
          ReadAbsSector(fd^.Drive,tfs,1,dir);
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
              writeln(ft,'  Item: "',t:13,'" Clus: ',cluster,' Size:',dir[i].size);
            end;
          end;
        end;
      end;
    end;
  end;

  close(ft);
end;