Program DDE;
(*****************************************************************************
 *                       DOS DiskEdit v2.00 beta 11                          *
 *****************************************************************************
 *                                                                           *
 * Части кода взяты из:                                                      *
 * ■ DOS Navigator by RIT Research Labs                                      *
 *                                                                           *
 *                                                          Since: 01/04/Y2k *
 * (C) NiKe'Soft UnLtd.                               Last UpDate: 19/01/Y2+ *
 *****************************************************************************)
{$DEFINE DEBUG}
{$DEFINE RussianLang}
{$DEFINE Beta}
{.$DEFINE EnableWrite}
{$DEFINE TestDrive}

{$A- Word aligned data}
{$E- 80x87 Emulation}
{$N+ Numeric co-processor}
{$F- Far calls}
{$X+ Extended syntax}
{$B- Boolean evaluation}
{$G- Group unit segments}
{$O- Overlays}
{$IFDEF DEBUG}
  {$D+ Debug information}
  {$I+ I/O checking}
  {$L+ Local symbols information}
  {$Y+ Symbol information}
  {$T+ Type-checked pointers}
  {$R+ Range checking}
  {$P+ Open strings parameters}
  {$Q- Overflow checking}
  {$S+ Stack-overflow checking}
  {$V+ Var-string checking}
{$ELSE}
  {$D- Debug information}
  {$I- I/O checking}
  {$L- Local symbols information}
  {$Y- Symbol information}
  {$T- Type-checked pointers}
  {$R- Range checking}
  {$P- Open strings parameters}
  {$Q- Overflow checking}
  {$S- Stack-overflow checking}
  {$V- Var-string checking}
{$ENDIF}
{$M 16384,0,655360}

Uses DiskTool,vFAT,Service,TextModeUtil,Keyboard,Hex,HelpZ;

const CopyRight  = '(c) NiKe''Soft UnLtd';
      appName    = 'DOS DiskEdit (DDE)';
      STappName  = 'DOS DiskEdit ('+'~'+char(16*cBlack+cLCyan)+'~'+'DDE'+'~'+char(16*cBlack+cGray)+'~'+')';
      appBuild   = '19/01/Y2+';
{$IFDEF DEBUG}
  {$IFDEF BETA}
      appVer     = 'v2.00d beta 11';
  {$ELSE}
      appVer     = 'v2.00d';
  {$ENDIF}
{$ELSE}
  {$IFDEF BETA}
      appVer     = 'v2.00 beta 11';
  {$ELSE}
      appVer     = 'v2.00';
  {$ENDIF}
{$ENDIF}
const
      Max_Items  = 4096;
      Max_Drives = 2{FDD}+4{HDD}+3{Reserved};

      nRetries = 2;

      vtHex    = 0;
      vtHex64  = 1;

      ViewType    : byte = vtHex64;
      ViewChLimit : byte = 0;
      Wrap        : byte = 0;
      TabSize     : byte = 8;

      pt_None    = 0;
      pt_Drives  = 1;
      pt_LDrives = 2;
      pt_Dirs    = 3;

{$IFDEF RussianLang}
      stDrive         = 'Диск';
      stHdr01         = ' Выберите Диск ';
      stHdr02         = ' Выберите Раздел ';
      stInit_Drives   = 'Инициируем таблицы Дисков ... ';
      stFound         = 'найден(о)';
      stErroR         = 'Ошибка';
      stNum           = 'No.';
      stSize          = 'Размер';
      stHeads         = 'Сторон';
      stHead          = 'Стор.';
      stTracks        = 'Дорож.';
      stTrack         = 'Дорож.';
      stSector        = 'Сект.';
      stActive        = 'Акт.';
      stSystem        = 'ID Системы';
      stYes           = 'Да';
      stNo            = 'Нет';
      stCluster       = 'Кластер';
      stDirectory     = 'Каталог';
      st_NORMAL_st    = '~'+char(16*cGray+cRed)+'~'+#25#24#27#26'/End/Home/PgDn/PgUp'+'~'+char(16*cGray+cBlack)+'~'+
                        ' - перемещ. '+'~'+char(16*cGray+cRed)+'~'+'Enter'+'~'+char(16*cGray+cBlack)+'~'+' - в каталог. '+
                        '~'+char(16*cGray+cRed)+'~'+'F12'+'~'+char(16*cGray+cBlack)+'~'+' - зкран. '+
                        '~'+char(16*cGray+cRed)+'~'+'ESC'+'~'+char(16*cGray+cBlack)+'~'+' - выход';
      st_Shift_st     = '~'+char(16*cGray+cRed)+'~'+#25#24#27#26'/End/Home/PgDn/PgUp'+'~'+char(16*cGray+cBlack)+'~'+
                        ' - перемещ. '+'~'+char(16*cGray+cRed)+'~'+'Enter'+'~'+char(16*cGray+cBlack)+'~'+' - в каталог. '+
                        '~'+char(16*cGray+cRed)+'~'+'ESC'+'~'+char(16*cGray+cBlack)+'~'+' - выход';
      st_Alt_st       = '~'+char(16*cGray+cRed)+'~'+'F1/F2'+'~'+char(16*cGray+cBlack)+'~'+' - выбор диска. '+
                        '~'+char(16*cGray+cRed)+'~'+'R'+'~'+char(16*cGray+cBlack)+'~'+' - перечитать. '+
                        '~'+char(16*cGray+cRed)+'~'+#27#26'/Home/End'+'~'+char(16*cGray+cBlack)+'~'+' - LFNofs'+
                        '~'+char(16*cGray+cRed)+'~'+' I'+'~'+char(16*cGray+cBlack)+'~'+' инфо';
      st_Ctrl_st      = '~'+char(16*cGray+cRed)+'~'+'F1-F5'+'~'+char(16*cGray+cBlack)+'~'+' - сортировки. '+
                        '~'+char(16*cGray+cRed)+'~'+'R'+'~'+char(16*cGray+cBlack)+'~'+' - перечитать. '+
                        '~'+char(16*cGray+cRed)+'~'+'End/Home'+'~'+char(16*cGray+cBlack)+'~'+' - перемещение. '+
                        '~'+char(16*cGray+cRed)+'~'+'T'+'~'+char(16*cGray+cBlack)+'~'+' - Тест '+'~'+char(16*cGray+cRed)+'~'+
                        '+/-'+'~'+char(16*cGray+cBlack)+'~'+' Hапp.';
      stTesting       = ' Тестрование/проверка диска ';
      stFrom          = 'из';
      stEstimated     = 'Расчетное';
      stElapsed       = 'Прошло';
      stTimeLeft      = 'Осталось';
      stDriveInfo     = 'Информация о диске';
      stViewingFile   = ' Пpосмотp файла';
      stBytes         = 'байт';
      stNew           = 'новых';
      stBad           = 'Плохих:';
      stBiosDrv       = 'BIOS-Диск ';
      stRootElements  = ' элементов корня';
      stRootCluster   = 'Кластер корня ';
      stPartFrom      = 'Раздел от ';
      stFileSys       = 'Файловая система - ';
      stFreeClusters  = ' cвободных кластеров';
      stClusterLength = ' секторов в кластере';
      stClusters      = ' кластеров';
      stFatLength     = ' секторов в FAT';
      stCopies        = 'копии';
      stPartLength    = ' секторов в разделе';
      stSectora       = ' сектора';
      stOtnSec        = ' о.с.';
      stFaultCluster  = 'B - сбойный';
      stErrorCluster  = 'E - ошибочный';
      stResCluster    = 'R - резервный';
      stGoodBye       = 'Спасибо. До встреч на "борту" моего софта :-)';
{$ELSE}
      stDrive         = 'Drive';
      stHdr01         = ' Choose Drive ';
      stHdr02         = ' Choose Partition ';
      stInit_Drives   = 'Initializing DRiVE Tables ... ';
      stFound         = 'found';
      stErroR         = 'ErroR';
      stNum           = 'No.';
      stTracks        = 'Tracks';
      stTrack         = 'Track';
      stHeads         = 'Heads';
      stHead          = 'Head';
      stSector        = 'Sect.';
      stSize          = ' Size';
      stActive        = 'Act.';
      stSystem        = 'System ID';
      stYes           = 'Yes';
      stNo            = 'No';
      stCluster       = 'Cluster';
      stDirectory     = '  DIR  ';

      st_NORMAL_st    = '~'+char(16*cGray+cRed)+'~'+#25#24#27#26'/End/Home/PgDn/PgUp'+'~'+char(16*cGray+cBlack)+'~'+
                        ' - moving '+'~'+char(16*cGray+cRed)+'~'+'Enter'+'~'+char(16*cGray+cBlack)+'~'+' - Goto DIR '+
                        '~'+char(16*cGray+cRed)+'~'+'F12'+'~'+char(16*cGray+cBlack)+'~'+' - Scr.Off '+
                        '~'+char(16*cGray+cRed)+'~'+'ESC'+'~'+char(16*cGray+cBlack)+'~'+' - Exit';
      st_Shift_st     = '~'+char(16*cGray+cRed)+'~'+#25#24#27#26'/End/Home/PgDn/PgUp'+'~'+char(16*cGray+cBlack)+'~'+
                        ' - moving '+'~'+char(16*cGray+cRed)+'~'+'Enter'+'~'+char(16*cGray+cBlack)+'~'+' - Goto DIR '+
                        '~'+char(16*cGray+cRed)+'~'+'ESC'+'~'+char(16*cGray+cBlack)+'~'+' - exit';
      st_Alt_st       = '~'+char(16*cGray+cRed)+'~'+'F1/F2'+'~'+char(16*cGray+cBlack)+'~'+' - Select Drive '+
                        '~'+char(16*cGray+cRed)+'~'+'R'+'~'+char(16*cGray+cBlack)+'~'+' - ReRead '+
                        '~'+char(16*cGray+cRed)+'~'+#27#26'/Home/End'+'~'+char(16*cGray+cBlack)+'~'+' - LFNofs'+
                        '~'+char(16*cGray+cRed)+'~'+' I'+'~'+char(16*cGray+cBlack)+'~'+' Info';
      st_Ctrl_st      = '~'+char(16*cGray+cRed)+'~'+'F1-F5'+'~'+char(16*cGray+cBlack)+'~'+' - sortings '+
                        '~'+char(16*cGray+cRed)+'~'+'R'+'~'+char(16*cGray+cBlack)+'~'+' - ReRead '+
                        '~'+char(16*cGray+cRed)+'~'+'End/Home'+'~'+char(16*cGray+cBlack)+'~'+' - moving '+
                        '~'+char(16*cGray+cRed)+'~'+'T'+'~'+char(16*cGray+cBlack)+'~'+' - Test '+'~'+char(16*cGray+cRed)+'~'+
                        '+/-'+'~'+char(16*cGray+cBlack)+'~'+' Sort direction';

      stTesting       = ' Testing/recovering drive ';
      stFrom          = 'from';
      stEstimated     = 'Estimated';
      stElapsed       = 'Elapsed';
      stTimeLeft      = 'Time left';
      stDriveInfo     = 'Drive info';
      stViewingFile   = ' Viewing file';
      stBytes         = 'bytes';
      stNew           = 'new';
      stBad           = 'Bad:';
      stBiosDrv       = 'BIOS-Drv ';
      stRootElements  = ' root elements';
      stRootCluster   = 'Root cluster ';
      stPartFrom      = 'Partition from ';
      stFileSys       = 'File System - ';
      stFreeClusters  = ' free clusters';
      stClusterLength = ' sectors per cluster';
      stClusters      = ' clusters';
      stFatLength     = ' sectors per FAT';
      stCopies        = 'copies';
      stPartLength    = ' sectors in partition';
      stSectora       = ' sector';
      stOtnSec        = ' r.s.';
      stFaultCluster  = 'B - BAD cluster';
      stErrorCluster  = 'E - Errored';
      stResCluster    = 'R - Reserved';
      stGoodBye      = 'T|-|a|\|x 4 |_|$i|\|G /\/\y $*Ft, $ee y/-\ |_/-\teR :-)';
{$ENDIF}

      DriveDlgW      = 49;
      LDriveDlgW     = 63;
      Max_Partitions = 20;

      smUnsorted     = 0;
      smName         = 1;
      smExtension    = 2;
      smSize         = 3;
      smDateTime     = 4;

const max_buf = 32768;
type tBuf = array[0..max_buf] of char;
     tAlias = record
       case byte of
       0:( name : array[0..7] of char;
           ext  : array[0..2] of char);
       1: ( nameext : array[0..10] of char);
       end;

type pString = ^String;
type pFile_Item = ^tFile_Item;
     tFile_Item = record
     case byte of
     0:( Name     : array[0..7] of char;
         Ext      : array[0..2] of char;
         Attr     : byte;
         lCase    : byte;          {Char case of name & ext}
         cTime_ms : byte;          {Creation time, milliseconds}
         cTime    : word;          {Creation time}
         cDate    : word;          {Creation date}
         aDate    : word;          {Last access date}
         Year     : word;
         Month,Day: byte;
         Hour,Minute,Sec: byte;
         Cluster  : longint;
         Size     : longint;
         LFName   : pString;
         Sel      : boolean;
         ShowSize : boolean);
     1:( NameExt : array[0..10] of char);
     end;
type pLDrive = ^tLDrive;
     tLDrive = record
       BiosDrv : byte;
       Part    : tPartition;
     end;
type pItem = ^tItem;
     tItem = record
     case byte of
     1: ( F : tFile_Item);
     2: ( D : tBios_Drive);
     3: ( L : tLDrive);
     end;

type tPanel = record
        FD           : pFat_Device;
        Items        : array[0..Max_Items] of pItem;
        nItems,_dp,
        _ds,_x,_y    : word;
        x1,y1,x2,y2  : word;
        PathName     : string;
        PathType     : byte;
        Cluster      : longint;
        Visible      : boolean;
        LFNOfs       : byte;
        MaxLfnOfs    : byte;
        LastClus     : longint;
        SortMode     : byte;
        SortAsc      : boolean;
        UseLFN       : boolean;
        ShowDeleted  : boolean;
        ShowDot      : boolean; {Show '.' dir el.}
     end;

type tDirectory = array[1..16] of tdirelement;

Var Panel   : array[0..1] of tPanel;
    CurPnl  : byte;
    Drives  : array[1..Max_Drives] of tBios_Drive;
    Pts     : array[1..Max_Partitions] of tPartition;
    oldx,oldy,nDrives : byte;
    buf     : array512;

procedure DDEFont; external; {$L DDEFont.Obj}

procedure WriteFAT;
var f : file;
    ft : text;
    i,startc,endc,c,clust : longint;
    pr : real;
    s : string;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(f,'fat0.dat'); rewrite(f,1);
    fil(1,1,80,' ');
    fil(1,25,80,' ');
    vidf(1,1,80,14);
    vidb(1,1,80,00);
    startc := 2; endc := fd^.clusters - 2;
    for c := 2 to endc do
    begin
      if keypressed then break;
      pr := (c / (endc - startc));
      i := round(79*pr)-1; if i <= 0 then i := 1;
      pr := pr*100;
      fil(1,1,i,'█');
      s := strf(c,1) +' / '+ strf(endc,1) + '  ('+strf(round(pr),1)+'%)';
      while length(s) < 80 do s := s + ' ';
      writestf(s,2,25,14);
      clust := get_fat_item(fd^,c);
      blockwrite(f,clust,sizeof(clust));
    end;
    close(f);
  end;
  while keypressed do getkey;
  putscr(4);
end;

const nstitems = 87259;

procedure DoFileDefines;
var ft,f,nf,kf : text;
    clust,tfs,knownf,unknownf,z,fs,cl,i,j : longint;
    t,tt,st,s,ts : string;
    srp,e : integer;
    fnd,p,maxit : longint;
    pr : real;
    buf : array512;
    dir : tDirectory absolute buf;
    srne1,srne2 : array[0..10] of char;
    isflag : boolean;
    stop : boolean;

function cmp(s : string; cased : boolean) : boolean;
var fnd : boolean;
    i : integer;
    c : char;
begin
  if not cased then s := upcasestr(s);
  cmp := true;
  for i := 1 to length(s) do
  begin
    if not cased then c := upcase(buf[i-1]) else c := buf[i-1];
    if c <> s[i] then
    begin
      cmp := false;
    end;
  end;
end;

begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(f,'fat0.txt'); reset(f);
    assign(nf,'file_un.txt'); rewrite(nf);
    assign(kf,'file_kn.txt'); rewrite(kf);
    assign(ft,'dirs_N.txt'); rewrite(ft);
    fil(1,1,80,' ');
    fil(1,25,80,' ');
    vidf(1,1,80,14);
    vidb(1,1,80,00);
    z := 0; knownf := 0; unknownf := 0;
    fillchar(srne1,sizeof(srne1),' ');
    srne1[0] := '.';
    fillchar(srne2,sizeof(srne2),' ');
    srne2[0] := '.'; srne2[1] := '.';

    while not eof(f) do
    begin
      inc(z);
      if keypressed then break;
      pr := (z / nstitems);
      i := round(79*pr)-1; if i <= 0 then i := 1;
      pr := pr*100;
      fil(1,1,i,'█');
      s := strf(z,1) +' / '+ strf(nstitems,1) + '  ('+strf(round(pr),1)+'%)  Known:'+
       strf(knownf,1)+' UnKnown:'+strf(unknownf,1);
      while length(s) < 80 do s := s + ' ';
      writestf(s,2,25,14);

      readln(f,s);
      p := pos('SClust:',s);
      if p > 0 then
      begin
        ts := copy(s,p+7,255);
        ts := trim(copy(ts,1,pos(',',ts)-1));
        val(ts,p,e);
        if e = 0 then
        begin
          clust := p+2;
          fs := get_cluster_sector(fd^,clust);
          Read_Sectors(fd^,fs,1,buf);
          isflag := false;

          if dir[1].nameext = srne1 then
          begin
            if dir[2].nameext = srne2 then
            begin
{              if dir[1].attr = $20 then}
              begin
                isflag := true;
              end;
            end;
          end;
          if isflag then
          begin
            writeln(kf,s,' Type:','Sub-Dir');
            inc(knownf);
            writeln(ft,'SubDir Found at sec. ',fs,'  clus:',clust);
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
              if stop then {break};
              if dir[i].size >= 0 then
              begin
                t  := trim(dir[i].name);
                tt := trim(dir[i].ext);
                if tt <> '' then t := t + '.' + tt;
                clust  := ((dir[i].cluster) + (longint(dir[i].Clus_hi) shl 16));
                writeln(ft,'  Item: "',t:13,'" Clus: ',clust,' Size:',dir[i].size);
              end;
            end;
            for tfs := fs+1 to fs+fd^.cluster_length-1 do
            begin
              if keypressed then break;
              ReadAbsSector(fd^.Drive.Drive,tfs,1,dir);
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
                if stop then {break};
                if dir[i].size >= 0 then
                begin
                  t  := trim(dir[i].name);
                  tt := trim(dir[i].ext);
                  if tt <> '' then t := t + '.' + tt;
                  clust  := ((dir[i].cluster) + (longint(dir[i].Clus_hi) shl 16));
                  writeln(ft,'  Item: "',t:13,'" Clus: ',clust,' Size:',dir[i].size);
                end;
              end;
            end;


          end else
          if cmp(#$FF#$FB#$90,true) then
          begin
            writeln(kf,s,' Type:','MP3?');
            inc(knownf);
          end else
          if cmp(#$FF#$D8#$FF#$E0#$00#$10'JFIF',true) then
          begin
            writeln(kf,s,' Type:','JPEG?');
            inc(knownf);
          end else
          if cmp('GIF89a',true) then
          begin
            writeln(kf,s,' Type:','GIF?');
            inc(knownf);
          end else
          if cmp('PK',true) then
          begin
            writeln(kf,s,' Type:','PKZIP?');
            inc(knownf);
          end else
          if cmp('MZ',true) then
          begin
            if buf[2] = 'P' then writeln(kf,s,' Type:','EXE-MZP?') else
              writeln(kf,s,' Type:','EXE?');
            inc(knownf);
          end else
          if cmp('Rar!',true) then
          begin
            writeln(kf,s,' Type:','RAR?');
            inc(knownf);
          end else
          if cmp('RIFF',true) then
          begin
            writeln(kf,s,' Type:','Riff-File?');
            inc(knownf);
          end else
          if cmp('unit ',false) then
          begin
            writeln(kf,s,' Type:','PAS.UNIT? Content:');
(*
            for j := 0 to 5 do
            begin
              Read_Sectors(fd^,fs+j,1,buf);
              for i := 0 to 511 do if (char(buf[i]) >= #0)and(char(buf[i]) <= '~') then write(kf,char(buf[i]))
               else write(kf,' ');
            end;
            writeln(kf);
*)
            inc(knownf);
          end else
          if cmp('Program ',false) then
          begin
            writeln(kf,s,' Type:','PAS? Content:');
(*
            for j := 0 to 5 do
            begin
              Read_Sectors(fd^,fs+j,1,buf);
              for i := 0 to 511 do if (char(buf[i]) >= #0)and(char(buf[i]) <= '~') then write(kf,char(buf[i]))
               else write(kf,' ');
            end;
            writeln(kf);
*)
            inc(knownf);
          end else
          begin
            writeln(nf,s,' Type:','UNKNOWN  Content:');
(*
            for j := 0 to 0 do
            begin
              Read_Sectors(fd^,fs+j,1,buf);
              for i := 0 to 511 do if (char(buf[i]) >= ' ')and(char(buf[i]) <= {'~'}#$FF) then write(nf,char(buf[i]))
               else write(nf,' ');
            end;
            writeln(nf);
*)
            inc(unknownf);
          end;
        end;
      end;
    end;
    close(f);
    close(nf);
    close(kf);
    close(ft);
  end;
  while keypressed do getkey;
  putscr(4);
end;

procedure DoDirs;
var ft : text;
    tfs,clust,nfs,fs,c : longint;
    dir : tDirectory;
    direl : tDirElement;
    ndir,e,j,dirsf,i : integer;
    s,t,tt : string;
    stop : boolean;
label ex;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(ft,'dirc.dat'); reset(ft);
    i := 3;
    clust := 113004;
    fs := get_cluster_sector(fd^,clust);
    nfs := 0;
    ndir := 0;
    Read_Sectors(fd^,fs,1,dir);
    s := '.';
    if length(s) > 8 then s[0] := #8 else
    begin
      while length(s) < 8 do s := s + ' ';
    end;
    for j := 1 to 8 do direl.name[j-1] := s[j];
    for j := 0 to 2 do direl.ext[j] := ' ';
    direl.attr := faDirectory;
    direl.lcase := 0;
    direl.cTime_ms := 0;
    direl.cTime := 0;
    direl.cDate := 0;
    direl.aDate := 0;
    c := 113004;
    direl.Clus_Hi := c shr 16;
    direl.cluster := c and $ffff;
    direl.date := 0;
    direl.size := 0;
    dir[1] := direl;
    direl.name[1] := '.';
    c := 0;
    direl.Clus_Hi := c shr 16;
    direl.cluster := c and $ffff;
    dir[2] := direl;

    while not eof(ft) do
    begin
      readln(ft,s);
      val(s,c,e);
      if (e = 0)and(c <= fd^.clusters - 2) then
      begin
        inc(ndir);
        str(ndir,s);
        if length(s) > 8 then s[0] := #8 else
        begin
          while length(s) < 4 do s:= '0' + s;
          while length(s) < 8 do s := s + ' ';
        end;
        for j := 1 to 8 do direl.name[j-1] := s[j];
        for j := 0 to 2 do direl.ext[j] := ' ';
        direl.attr := faDirectory;
        direl.lcase := 0;
        direl.cTime_ms := 0;
        direl.cTime := 0;
        direl.cDate := 0;
        direl.aDate := 0;
        direl.Clus_Hi := c shr 16;
        direl.cluster := c and $ffff;
        direl.date := 0;
        direl.size := 0;

        dir[i] := direl;
(*
    tDirElement = record
      case byte of
      0:( Name     : array[0..7] of char;
          Ext      : array[0..2] of char;
          Attr     : byte;
          lCase    : byte;          {Char case of name & ext}
          cTime_ms : byte;          {Creation time, milliseconds}
          cTime    : word;          {Creation time}
          cDate    : word;          {Creation date}
          aDate    : word;          {Last access date}
          Clus_hi  : word;          {High 16 bits of cluster in FAT32}
          Date     : longint;
          Cluster  : word;
          Size     : longint);
      1:( NameExt : array[0..10] of char);
    end;

*)
        if i >= 16 then
        begin
          Write_Sectors(fd^,fs,1,dir);
          if nfs >= fd^.cluster_length then
          begin
            if clust >= fd^.bad_mark then goto ex;
            clust := get_fat_item(fd^,clust);
            fs := get_cluster_sector(fd^,clust);
            nfs := 0;
          end else
          begin
            inc(nfs);
            inc(fs);
          end;
          Read_Sectors(fd^,fs,1,dir);
          i := 1;
        end else inc(i);
      end;
    end;
  end;
ex:
  close(ft);
  putscr(4);
end;

procedure DoFiles;
var ft : text;
    p,tfs,clust,nfs,fs,c : longint;
    dir : array[1..16] of tdirelement;
    direl : tDirElement;
    ndir,e,j,dirsf,i : integer;
    srst,exte,s,t,ts,tt : string;
    stop : boolean;
label ex;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    fil(1,25,80,' ');
    assign(ft,'file_kn.txt'); reset(ft);
    i := 3;
    clust := 113004;
    fs := get_cluster_sector(fd^,clust);
    nfs := 0;
    ndir := 0;
    Read_Sectors(fd^,fs,1,dir);
    s := '.';
    if length(s) > 8 then s[0] := #8 else
    begin
      while length(s) < 8 do s := s + ' ';
    end;
    for j := 1 to 8 do direl.name[j-1] := s[j];
    for j := 0 to 2 do direl.ext[j] := ' ';
    direl.attr := faDirectory;
    direl.lcase := 0;
    direl.cTime_ms := 0;
    direl.cTime := 0;
    direl.cDate := 0;
    direl.aDate := 0;
    c := 113004;
    direl.Clus_Hi := c shr 16;
    direl.cluster := c and $ffff;
    direl.date := 0;
    direl.size := 0;
    dir[1] := direl;
    direl.name[1] := '.';
    c := 0;
    direl.Clus_Hi := c shr 16;
    direl.cluster := c and $ffff;
    dir[2] := direl;


    srst := 'Type:PKZIP'; exte := 'ZIP';


    while not eof(ft) do
    begin
      readln(ft,s);
      if copy(s,1,13) <> 'Item  SClust:' then continue;
      p := pos(srst,s);
      if p <= 0 then continue;
      p := pos('SClust:',s);
      direl.size := 0;
      if p > 0 then
      begin
        ts := copy(s,p+7,255);
        p := pos(',',ts);
        if p <= 0 then
        begin
          continue;
        end;
        ts := trim(copy(ts,1,p-1));
        val(ts,c,e);
        c := c+2;
        if (e = 0)and(c <= fd^.clusters - 2) then
        begin
          p := pos('GSize:',s);
          if p > 0 then
          begin
            ts := trim(copy(s,p+6,255));
            p := pos(' ',ts);
            if p <= 0 then
            begin
              continue;
            end;
            ts := trim(copy(ts,1,p-1));
            val(ts,p,e);
            if (e = 0)and(p > 0) then direl.size := p;
          end;
          inc(ndir);
          str(ndir,s);
          writestf(s,1,25,14);
          if length(s) > 8 then s[0] := #8 else
          begin
            while length(s) < 4 do s:= '0' + s;
            while length(s) < 8 do s := s + ' ';
          end;
          for j := 1 to 8 do direl.name[j-1] := s[j];
          s := exte;
          while length(s) < 3 do s := s + ' ';
          for j := 1 to 3 do direl.ext[j-1] := s[j];
          direl.attr := faArchive;
          direl.lcase := 0;
          direl.cTime_ms := 0;
          direl.cTime := 0;
          direl.cDate := 0;
          direl.aDate := 0;
          direl.Clus_Hi := c shr 16;
          direl.cluster := c and $ffff;
          direl.date := 0;

          dir[i] := direl;
          if i >= 16 then
          begin
            Write_Sectors(fd^,fs,1,dir);
            if nfs >= fd^.cluster_length then
            begin
              if clust >= fd^.bad_mark then goto ex;
              clust := get_fat_item(fd^,clust);
              fs := get_cluster_sector(fd^,clust);
              nfs := 0;
            end else
            begin
              inc(nfs);
              inc(fs);
            end;
            Read_Sectors(fd^,fs,1,dir);
            i := 1;
          end else inc(i);
        end;
      end;
    end;
    direl.name[0] := #0;
    dir[i] := direl;
    Write_Sectors(fd^,fs,1,dir);
  end;
ex:
  close(ft);
  putscr(4);
end;
(*

procedure DoSearch;
var ft : text;
    tfs,cluster,fs,c : longint;
    dir : array[1..16] of tdirelement;
    j,dirsf,i : integer;
    srne1,srne2 : array[0..10] of char;

    s,t,tt : string;
    stop : boolean;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(ft,'dirs.dat'); rewrite(ft);
    fillchar(srne1,sizeof(srne1),' ');
    srne1[0] := '.';
    fillchar(srne2,sizeof(srne2),' ');
    srne2[0] := '.'; srne2[1] := '.';
    dirsf := 0; stop := false;
    fil(1,25,80,' ');

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
  while keypressed do readkey;
  putscr(4);
end;
*)

procedure DoSearch;
var ft : text;
    startc,endc,tfs,cluster,fs,c : longint;
    buf : array512;
    j,dirsf,i : integer;
    srne1,srne2 : array[0..10] of char;
    srch,s,t,tt : string;
    stop : boolean;
    pr : real;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(ft,'search2.dat'); rewrite(ft);
    dirsf := 0; stop := false;
    fil(1,25,80,' ');
{    srch := 'Program DDE;';}
    srch := 'Unit DiskTool;';
{    startc := 2;}
    startc := 118000;
    endc := fd^.clusters - 2;
    fil(1,1,80,' ');
    fil(1,2,80,' ');
    fil(1,3,80,' ');
    fil(1,25,80,' ');
    vidf(1,1,80,14);
    vidf(1,2,80,14);
    vidf(1,3,80,14);
    vidb(1,1,80,00);
    vidb(1,2,80,00);
    vidb(1,3,80,00);
    for c := startc to endc do
    begin
      pr := (c / (endc - startc));
      i := round(79*pr)-1; if i <= 0 then i := 1;
      pr := pr*100;
      fil(1,1,i,'█');
      fil(1,2,i,'█');
      fil(1,3,i,'█');
      s := strf(c,1) +' / '+ strf(fd^.clusters,1) + '  ('+strf(round(pr),1)+'%) DirsF:'+strf(dirsf,1);
      while length(s) < 80 do s := s + ' ';
      writestf(s,2,25,14);
      if keypressed then break;
      fs := get_cluster_sector(fd^,c);
      if fs <= 0 then break;
      Read_Sectors(fd^,fs,1,buf);
      stop := true;
      for i := 1 to length(srch) do
      begin
        if buf[i-1] <> srch[i] then
        begin
          stop := false;
        end;
      end;
      if stop then
      begin
        writeln(ft,'Pattern Found at clus:',c);
        writeln(ft,' Content: ');
        for j := 0 to 5 do
        begin
          Read_Sectors(fd^,fs+j,1,buf);
          for i := 0 to 511 do if (char(buf[i]) >= #0)and(char(buf[i]) <= '~') then write(ft,char(buf[i])) else write(ft,' ');
        end;
        writeln(ft);
        writeln(ft);
        inc(dirsf);
      end;
    end;

    close(ft);
  end;
  while keypressed do readkey;
  putscr(4);
end;

procedure DoSearchFileNames;
var ft : text;
    startc,endc,tfs,clust,fs,c : longint;
    buf : array512;
    dir : tDirectory absolute buf;
    j,dirsf,i : integer;
    srne1,srne2 : array[0..10] of char;
    srch,s,t,tt : string;
    stop : boolean;
    pr : real;
begin
  savescr(4);
  with Panel[CurPnl] do
  begin
    assign(ft,'fnames.txt'); rewrite(ft);
    dirsf := 0; stop := false;
    fil(1,25,80,' ');
{    srch := 'Program DDE;';}
{    startc := 2;}
    startc := 2;
    endc := fd^.clusters - 2;
    fil(1,1,80,' ');
    fil(1,2,80,' ');
    fil(1,3,80,' ');
    fil(1,25,80,' ');
    vidf(1,1,80,14);
    vidf(1,2,80,14);
    vidf(1,3,80,14);
    vidb(1,1,80,00);
    vidb(1,2,80,00);
    vidb(1,3,80,00);
    for c := startc to endc do
    begin
      pr := (c / (endc - startc));
      i := round(80*pr); if i <= 0 then i := 1;
      pr := pr*100;
      fil(1,1,i,'█');
      fil(1,2,i,'█');
      fil(1,3,i,'█');
      s := strf(c,1) +' / '+ strf(fd^.clusters,1) + '  ('+strf(round(pr),1)+'%) DirsF:'+strf(dirsf,1);
      while length(s) < 80 do s := s + ' ';
      writestf(s,2,25,14);
      if keypressed then break;
      fs := get_cluster_sector(fd^,c);
      if fs <= 0 then break;
      Read_Sectors(fd^,fs,1,buf);
      stop := false;
      if dir[1].name[0] <> #0 then
      begin
        clust  := ((dir[1].cluster) + (longint(dir[1].Clus_hi) shl 16));
        if (clust >= 2)and(clust <= fd^.clusters) then
        begin
          if (dir[1].size >= 0)and(dir[1].size < 100000000) then
          begin
            stop := false;
            for j := 0 to 10 do
            begin
              if not (dir[1].nameext[j] in [' '..'~']) then
              begin
                stop := true;
                break;
              end;
              stop := not stop;
            end;
          end;
        end;
      end;
      if stop then
      begin
        writeln(ft,'DirClus: ',c);
        for i := 1 to 16 do
        begin
          if dir[i].nameext[0] = #0 then break;
          if dir[i].nameext[0] = #$E5 then continue;
          for j := 0 to 10 do
          begin
            if not (dir[i].nameext[j] in [' '..'~']) then
            begin
              if dir[i].size <> -1 then stop := true;
              break;
            end;
          end;
          if stop then {break};
          if (dir[i].size >= 0)and(dir[i].size < 700000000) then
          begin
            t  := trim(dir[i].name);
            tt := trim(dir[i].ext);
            if tt <> '' then t := t + '.' + tt;
            clust  := ((dir[i].cluster) + (longint(dir[i].Clus_hi) shl 16));
            if (clust >= 2)and(clust <= fd^.clusters) then
            begin
              writeln(ft,'  "',t:13,'" Clus: ',clust,' Size:',dir[i].size);
            end;
          end;
        end;
        writeln(ft);
        inc(dirsf);
      end;
    end;

    close(ft);
  end;
  while keypressed do readkey;
  putscr(4);
end;

function IsExe(it : pItem) : boolean;
var e : string;
begin
  e:=UpCaseStr(RTrim(it^.f.ext));
  IsExe:=true;
  if (e<>'EXE') then
   if (e<>'COM') then
    if (e<>'BAT') then
     IsExe:=false;
end;

function IsArchive(it : pItem) : boolean;
var e : string;
begin
  e:=upcasestr(RTrim(it^.f.ext));
  IsArchive:=true;
  if length(e)<2 then IsArchive:=false else
   if length(e)=2 then
   begin
    if (e<>'HA') then
     if (e<>'GZ') then IsArchive:=false else
   end else
  if (e[1]='A') then
  begin
    if not((e[2]='C')and(e[3]='E')) then
     if not((e[2]='R')and(e[3]='J')) then
      if not((e[2]='R')and(e[3]='C')) then
       if not((e[2]='I')and(e[3]='N')) then IsArchive:=false;
  end else
  if (e[1]='B') then
  begin
    if not((e[2]='S')and(e[3]='A')) then
     if not((e[2]='S')and(e[3]='2')) then IsArchive:=false;
  end else
  if (e[1]='C') then
  begin
    if not((e[2]='M')and(e[3]='Z')) then
     if not((e[2]='A')and(e[3]='B')) then IsArchive:=false;
  end else
  if (e[1]='H') then
  begin
    if not((e[2]='A')and(e[3]='P')) then
     if not((e[2]='P')and(e[3]='K')) then
      if not((e[2]='Y')and(e[3]='P')) then IsArchive:=false;
  end else
  if (e<>'RAR') then
  if (e<>'SQZ') then
  if (e<>'TAR') then
  if (e<>'UC2') then
  if (e[1]='Z') then
  begin
    if not((e[2]='H')and(e[3]='A')) then
     if not((e[2]='I')and(e[3]='M')) then
      if not((e[2]='I')and(e[3]='P')) then
       if not((e[2]='O')and(e[3]='O')) then
        if not((e[2]='X')and(e[3]='Z')) then IsArchive:=false;
  end else
  if (e<>'PAK') then
    IsArchive:=false;
end;

function GetItemColor(it : pItem) : byte;
var c  : byte;
    ex : string[3];
begin
  ex := UpCaseStr(RTrim(it^.f.ext));
  if isEXE(it) then c:=11
  else if isArchive(it) then c:=10
  else if (ex='PAS') then c:=03
  else if (ex='DPR') then c:=03
  else if (ex='BAS') then c:=03
  else if (ex='C'  ) then c:=03
  else if (ex='CPP') then c:=03
  else if (ex='H'  ) then c:=03
  else if (ex='ASM') then c:=03
  else if (ex='A86') then c:=03
  else if (ex='INC') then c:=03

  else if (ex=''   ) then c:=02
  else if (ex='INI') then c:=02
  else if (ex='CTL') then c:=02
  else if (ex='CFG') then c:=02
  else if (ex='TXT') then c:=02
  else if (ex='RTF') then c:=02
  else if (ex='DOC') then c:=02
  else if (ex='DIZ') then c:=02
  else if (ex='ME' ) then c:=02

{
  else if (ex='DBF') then c:=13
  else if (ex='WKZ') then c:=13
  else if (ex='123') then c:=13
  else if (ex='WK' ) then c:=13
  else if (ex='XLS') then c:=13
}
  else if (ex='TMP') then c:=12
  else if (ex='$$$') then c:=12
  else if (ex='BAK') then c:=12

  else if (ex='BMP') then c:=09
  else if (ex='PCX') then c:=09
  else if (ex='PIC') then c:=09
  else if (ex='GIF') then c:=09
  else if (ex='JPG') then c:=09
  else if (ex='JPE') then c:=09
  else if (ex='RLE') then c:=09
  else if (ex='ICO') then c:=09
  else if (ex='PNG') then c:=09
  else if (ex='TIF') then c:=09
  else if (ex='TGA') then c:=09
  else if (ex='KDC') then c:=09

  else if (ex='WAV') then c:=13
  else if (ex='MP3') then c:=13
  else if (ex='MP2') then c:=13
  else if (ex='MP1') then c:=13
  else if (ex='MID') then c:=13
  else if (ex='VQF') then c:=13
  else if (ex='669') then c:=13
  else if (ex='S3M') then c:=13
  else if (ex='IT' ) then c:=13
  else if (ex='MOD') then c:=13
  else if (ex='VOC') then c:=13
  else if (ex='M3U') then c:=13
  else if (ex='PLS') then c:=13
  else if (ex='NKS') then c:=13

  else c:=07;
  GetItemColor := c;
end;

function ViewFile(Pnl : byte; It : word) : integer;
var hh,h,hexpos : word;
    key,mkey  : word;
    hexing,done : boolean;
    clus,clse,DsP,Size : longint;
    bufdsp : longint;
    bf : ^tBuf;
    s : string;

function AllowedChar(ch : char) : boolean;
begin
  case ViewChLimit of
  1:   AllowedChar := (ch>=' ')and(ch<='');
  2:   AllowedChar := (ch>=' ')and(ch<=#$FF);
  else AllowedChar := true;
  end;
end;

procedure AdjustBuffer(ReRead : boolean);
var clu,sz,c,sec,cl : longint;
begin
  with Panel[Pnl] do
  begin
    if (dsp<0)or(dsp>size) then exit;
{
    sec:=get_cluster_sector(fd^,items[it]^.f.cluster);
    Read_Sectors(fd^,sec,1,bf^[0]);
}
    if not ReRead then if (dsp=bufdsp) then exit;
    fillchar(bf^,sizeof(bf^),#0);
    sec:=dsp div fd^.sector_length;
    cl:=sec div fd^.cluster_length;
    sz:=longint(fd^.cluster_length)*fd^.sector_length;
    clus:=Items[it]^.f.cluster;
    if cl>0 then
    begin
      sec:=sec mod fd^.cluster_length;
      for c:=1 to cl do
      begin
        clu:=Get_FAT_Item(fd^,clus);
        if clu>=fd^.BAD_Mark then
        begin
          Size:=sz;
          if size>hh*22 then dsp:=size-hh*22 else dsp:=0;
          break;
        end else
        begin
          clus:=clu;
          sz:=sz+longint(fd^.cluster_length)*fd^.sector_length;
        end;
      end;
    end;
    bufdsp:=dsp;
    c:=0; clu:=sec;
{
    sz:=sz-longint(fd^.cluster_length)*fd^.sector_length;
}
    sec := get_cluster_sector(fd^,clus);
    if sz<0 then sz:=0;
    while (c<3) do
    begin
      Read_Sectors(fd^,sec+clu,1,bf^[clu*fd^.sector_length]);
      inc(c);
      inc(clu); sz:=sz+fd^.sector_length;
      if (sz>=size) then break;
      if (clu mod fd^.cluster_length=0) then
      begin
        clu:=0;
        clus:=Get_FAT_Item(fd^,clus);
        if clus>=fd^.BAD_Mark then begin size:=sz; break; end;
        sec:=get_cluster_sector(fd^,clus);
      end;
    end;
  end;
end;

procedure DrawScr(DsP : longint);
var cl,a,i,w,ww : longint;
    c : char;
begin
  with Panel[Pnl] do
  begin
    if (Scr_buf<>nil) then
    begin
      move(ptr(Text_Seg,0)^,Scr_buf^,80*25*2);
      oText_Seg:=Text_Seg;
      Text_Seg:=seg(Scr_Buf^);
    end;
    case ViewType of
    vtHex,vtHex64:
     begin
       s:=rtrim(Items[it]^.f.name);
       if rtrim(Items[it]^.f.ext)<>'' then s:=s+'.'+rtrim(Items[it]^.f.ext);
       fillscr(1,1,80,25,' ');
       Set_Window(1,1,80,24,borders[brd_double],15,07,08,PA(10,08),' ',
       stViewingFile+' "'+s+'" (C:'+hexl(Items[it]^.f.cluster)+'h) ',false);
       if (ViewType=vtHex) then
       begin
         hh:=16;
         writestf('['+hexl(DsP+hexpos div 2)+' '+hexb(DsP mod 16),2,24,15);
         for i:=1 to 15 do writestf('-'+hexb(i + DsP mod 16),14+(i-1)*3,24,15);
         writestf('['+hexl(size  )+']',61,24,15);
       end else
       begin
         hh:=64;
         writestf('['+strf(round((1.0*100/size)*(DsP+hexpos div 2)),1)+'% '+stFrom+' '+strf(size,1)+' '+stBytes+']',3,24,15);
       end;
       if (Size-DsP)>hh*21 then w:=hh*22 else w:=Size-DsP;
       ww:=w div hh;
       if (w mod hh<>0) then inc(ww);
       for i:=1 to ww do
       begin
         writestf(hexl(DsP+(i-1)*hh),02,01+i,07);
         putchf(10,01+i,':',07);
         for a:=0 to hh-1 do
         begin
           if longint(DsP+(i-1)*hh+a)>=Size then
           begin dec(a); break; end;
           if ((i-1)*hh+a)<sizeof(bf^) then
           begin
             if (ViewType=vtHex) then
             begin
               writestf(hexb(byte(bf^[(i-1)*16+a])),15+(a-1)*3,01+i,07);
               if (a+1) mod 4<>0 then putchf(17+(a-1)*3,01+i,' ',07);
               c:=bf^[(i-1)*16+a];
               if AllowedChar(c) then putchf(62+a,01+i,c,07);
             end else
             begin
               c:=bf^[(i-1)*16+a];
               if AllowedChar(c) then putchf(12+a,01+i,c,07);
             end;
           end;
         end;
         for a:=a+1 to hh-1 do
         begin
           if (ViewType=vtHex) then
           begin
             writestf('  ',15+(a-1)*3,01+i,07);
             putchf(62+a,01+i,' ',07);
           end else putchf(12+a,01+i,' ',07);
         end;
         if (ViewType=vtHex64) then fil(76,01+i,79,' ');
         if (ViewType=vtHex) then
         begin
           putchf(23,01+i,'│',15);
           putchf(35,01+i,'│',15);
           putchf(47,01+i,'│',15);
           putchf(60,01+i,'║'{│},15);
         end;
       end;
       for i:=ww+1 to 22 do fil(2,01+i,78,' ');
     end;
    end;
    if (Scr_buf<>nil) then
    begin
      Text_Seg:=oText_Seg;
      wretr;
      move(Scr_buf^,ptr(Text_Seg,0)^,80*25*2);
    end;
  end;
end;

procedure AdjustCursor;
var x : byte;
begin
  if (not hexing)or(ViewType=vtHex64) then
  begin
    x:=(hexpos div 2) mod (hh) + 12;
    if (ViewType=vtHex) then inc(x,50);
  end else
  begin
    h:=(hexpos mod (hh*2));
    x:=h + h div 2 + 12;
  end;
  Set_Cursor_Pos(x,hexpos div (hh*2) + 2)
end;

begin
  ViewFile := 1;
  with Panel[Pnl] do if (nItems>0)and(it<nItems) then if (Items[it]<>nil) then
  begin
    SaveScr(4);
    dsp:=0;
    hexpos:=0;
    hexing:=true; {пеpемещение по HEX-числам а не по ASCII}
    bufdsp:=0;
    Size:=Items[it]^.f.Size;
    bf:=nil; new(bf); if (bf=nil) then exit;
    if (Size<=0) then Size:=longint(fd^.cluster_length)*fd^.sector_length*512;
    done := false; mkey:=kbnokey;
    AdjustBuffer(true);
    AdjustCursor;
    DrawScr(DsP);
    set_cursor(true);
    while (not done) do
    begin
      if mkey<>kbnokey then begin key:=mkey; mkey:=kbnokey; end else key:=getkey;
      if key<>kbNoKey then
      begin
        case key of
        kbDown: {Down}
        begin
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          if (hexpos+hh*2<h) then
          begin
            inc(hexpos,hh*2);
          end else
          if (longint(Size-DsP)>hh*22) then inc(DsP,hh);
        end;
        kbUp: {Up}
        begin
          if (hexpos>=hh*2) then
          begin
            dec(hexpos,hh*2);
          end else
          if (DsP-hh>=0) then
          begin
            dec(DsP,hh);
          end else DsP:=0;
        end;
        kbRight: {Right}
        begin
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          if (not hexing)or(ViewType=vtHex64) then
          begin
            if (hexpos+2<h) then inc(hexpos,2) else begin hexpos:=h-1; if (DsP+h div 2<Size) then mkey:=kbCtrlRight; end;
          end
          else if (Hexpos+1<h) then inc(hexpos) else begin Hexpos:=h-1; if (DsP+h div 2<Size) then mkey:=kbCtrlRight; end;
        end;
        kbLeft: {Left}
        begin
          if (not hexing)or(ViewType=vtHex64) then
          begin
            if (Hexpos>1) then dec(hexpos,2)
             else if (DsP>0) then begin mkey:=kbCtrlLeft; hexpos:=0; end else Hexpos:=hh*2-1;
          end else
          begin
            if (Hexpos>0) then dec(hexpos)
             else if (DsP>0) then begin mkey:=kbCtrlLeft; hexpos:=0; end else Hexpos:=hh*2-1;
          end;
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          if (hexpos>=h) then hexpos:=h-1;
        end;
        kbTab: {Tab}
        begin
          if ViewType=vtHex then hexing:=not hexing{ else hexing:=true};
        end;
        kbF4: {F4}
        begin
          if ViewType = vtHex then
          begin
            ViewType:=vtHex64;
            hh:=64;
          end else
          begin
            ViewType:=vtHex;
            hh:=16;
            if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
            if (hexpos>=h) then hexpos:=h-1;
          end;
        end;
        kbF6: {F6}
        begin
          if ViewChLimit=2 then ViewChLimit:=0 else inc(ViewChLimit);
        end;
        kbHome: {Home}
        begin
          hexpos:=(hexpos div (hh*2))*hh*2
        end;
        kbEnd: {End}
        begin
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          hexpos:=(hexpos div (hh*2)+1)*hh*2-1;
          if hexpos>h then hexpos:=h-1;
        end;
        kbCtrlHome: {CtrlHome}
        begin
          hexpos:=hexpos mod (hh*2);
        end;
        kbCtrlEnd: {CtrlEnd}
        begin
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          hexpos:=hexpos+(h div (hh*2) - hexpos div (hh*2)-1*byte((h div 2) mod hh=0))*hh*2;
          if (hexpos>=h) then
          begin
            dec(hexpos,hh*2);
            if (hexpos>=h) then hexpos:=h-1;
          end;
        end;
        kbCtrlPgUp: {CtrlPageUp}
        begin
          dsp:=0; hexpos:=0;
        end;
        kbCtrlPgDn: {CtrlPageDown}
        begin
          if (size>=hh*22) then DsP:=(Size-hh*22) else dsp:=0;
          if longint(size-dsp)>hh*22 then hexpos:=hh*22*2 else hexpos:=(size-dsp)*2;
          dec(hexpos);
        end;
        kbPgDn: {PageDown}
        begin
          if longint(Size-hh*22)>0 then
          if (DsP+hh*21<=Size-hh*22) then inc(DsP,hh*21) else
           DsP:=((Size-hh*22) div hh+1)*hh;
        end;
        kbPgUp: {PageUp}
        begin
          if longint(Size-hh*22)>0 then
          if (DsP-hh*21>=0) then dec(DsP,hh*21) else
           DsP:=0;
        end;
        kbCtrlLeft: {CtrlLeft}
        begin
          if (DsP>0) then dec(DsP);
        end;
        kbCtrlRight: {CtrlRight}
        begin
          if (DsP < Size-1) then inc(DsP);
          if longint(size-dsp)>hh*22 then h:=hh*22*2 else h:=(size-dsp)*2;
          if (hexpos>h) then hexpos:=h-1;
        end;
        kbESC: {ESCAPE} done:=true;
        end;
        if DsP <> bufDsP then AdjustBuffer(true) else AdjustBuffer(false);
        AdjustCursor;
        DrawScr(DsP);
      end; {if key<>kbNoKey then}
    end;
    ViewFile := 0;
    set_cursor(false);
  end;
  dispose(bf);
  PutScr(4);
end;

function Find_Alias_Item(fd : tFat_Device; DirCluster : longint; Alias : tAlias;
                       var it : tDirElement; var LFName : string) : integer;
var k,j,i  : longint;
    Dir    : array[0..15] of tDirElement;
    DirS   : longint;
    cl     : longint;
    tlfn   : string;
    dt     : datetime;
    id,crc : byte;
    found  : boolean;
begin
  Find_Alias_Item:= -1;
  LFName:=''; tlfn:=''; id:=0; crc:=0;
  k  := 0;                       {Количество просмотренных элементов}
  j  := 0;                       {Текущий элемент каталога}
  cl := DirCluster;
  if cl<2 then cl:=fd.root_cluster;
  DirS := Get_Cluster_Sector(fd,cl);
  fillchar(Dir,sizeof(dir),#0);
  Read_Sectors(fd,DirS,1,Dir);  {Читаем первый сектор}
  found:=false;
  while (not found) do
  begin
    if Dir[j].Name[0]=#0 then break; {Обнаружен конец списка}
    if (Dir[j].Attr = faExt)and(Dir[j].Name[0]<>#$E5) then
    begin
      if ID>0 then
      begin
        dec(id);
        if (tLFNelement(Dir[j]).id=id)and(tLFNelement(Dir[j]).crc=crc) then
          AddLfn(tlfn,tLFNElement(Dir[j]));
      end else
      begin
        id:=tLFNelement(Dir[j]).id;
        if id > $40 then dec(id,$40);
        crc := tLFNelement(Dir[j]).crc;
        tlfn:='';
        AddLfn(tlfn,tLFNElement(Dir[j]));
      end;
    end else
    begin
      if (Dir[j].Attr and faVolumeID=0) then
      begin
        Found := True;
        i := 0;
        while Found and (i<=10) do
        begin {Проверяем имя}
          Found := UpCaseCh(alias.nameext[i]) = UpCaseCh(Dir[j].NameExt[i]);
          inc(i)
        end;
        if found then
        begin
          Find_Alias_Item:= NoError;
          if (id=1)and(tlfn<>'') then
          begin
            if lcrc(Dir[j].NameExt) = crc then lfname := RTrim(tlfn) else lfname:='';
          end else lfname:='';
          it := dir[j];
          exit;
        end;
      end;
      tlfn:=''; id:=0; crc:=0;
    end;
    if j >= 15 then
    begin         {Исчерпан сектор каталога}
      j := 0;     {Продолжаем с 1-го элемента следующего сектора}
      inc(k,16);  {k - сколько элементов просмотрели}
      inc(dirs);
      if (cl<2) then
      begin
        if (fd.root_size>0) then if (k >= fd.root_size) then break;
      end else
      if (k div 16) mod fd.Cluster_length = 0 then
      begin     {Исчерпан кластер - ищем следующий}
        {Получаем новый кластер}
        cl := Get_FAT_Item(fd,cl);
        if (cl >= fd.bad_mark)or(cl < 2) then begin Find_Alias_Item:= 1; exit; end;
        {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
        DirS := Get_Cluster_Sector(fd,cl); {Получаем нoвый сектор}
      end;
      if Read_Sectors(fd,DirS,1,Dir)<>NoError then begin Find_Alias_Item:= 1; exit; end;
    end else inc(j);
  end; {while (not found)}
  Find_Alias_Item := 2;
end;

function Make_Alias(fd : tFat_Device; name : string; DirCluster : longint; AllowLFN, Uniq : boolean; var f : tAlias) : integer;
var dot,tilda,j,len,i : word;
    fl : boolean;
    it : tDirElement;
    tl : string;
    number : string;
begin
  Make_Alias := 0; dot:=0;
  fillchar(f,sizeof(f),#0);
  while (byte(name[0])>0)and(name[byte(name[0])]='.') do dec(name[0]);
  if byte(name[0])<=0 then exit;
  len:=byte(name[0]);
  for i:=Len downto 1 do
  begin
    if not DosChar(name[i]) then
     if not ((WinChar(name[i])) and (AllowLFN)) then begin Make_Alias := 1; exit; end;
    if dot=0 then if name[i]='.' then dot:=i;
  end;
  fl:=false;
  if (dot=0)and(len<=8) then fl:=true else
  begin
    if (pos('.',name)=dot)and(dot<=9)and(len-dot<=4)and({DosStr(name)}true)then fl:=true;
  end;
  if fl then
  begin
    if (dot=0) then
    begin
      for i:=0 to len-1 do f.name[i]:=UpCaseCh(name[i+1]);
      for i:=len to 10 do f.nameext[i]:=' ';
    end else
    begin
      for i:=0 to dot-2 do f.name[i]:=UpcaseCh(name[i+1]);
      for i:=dot-1 to 7 do f.name[i]:=' ';      {padding}
      for i:=0 to len-dot-1 do f.ext[i]:=UpcaseCh(name[dot+1+i]);
      for i:=len-dot to 2 do f.ext[i]:=' '; {padding}
      len:=dot;
    end;
    tilda:=1; {next number if not unique}
  end else {make a short alias}
  begin
    {name}
    i:=0; j:=1;
    while (j<=length(name))and(i<6) do
    begin
      if dot<>0 then if (j>dot) then break;
      if not (name[j] in ['.',' ']) then
      if DosChar(name[j]) then
      begin
        f.name[i]:=UpCaseCh(name[j]);
        inc(i);
      end else
      if WinChar(name[j]) then
      begin
        f.name[i]:='_';
        inc(i);
      end;
      inc(j);
    end;
    len:=i;
    f.name[i]:='~'{#126}; inc(i);
    f.name[i]:='1'; inc(i);
   {padding}
   for i:=i to 7 do f.name[i]:=' ';
   {EXTension}
   if (dot<>0) then
   begin
     j:=dot+1;
     i:=0;
     while (i<3) and (j<=length(name)) do
     begin
       if DosChar(name[j]) then
       begin
         f.ext[i]:=UpCaseCh(name[j]);
         inc(i);
       end else if WinChar(name[j]) then
       begin
         f.ext[i]:='_';
         inc(i);
       end;
       inc(j);
     end;
     for i:=i to 2 do f.ext[i]:=' '; {padding}
   end else fillchar(f.ext,3,' ');
   tilda:=2; {next number if not unique}
  end;
  {len=first char after name (<=6)}
  {is it unique?}
  if Uniq then
  repeat
    if Find_Alias_Item(fd,DirCluster,f,it,tl)=noerror then
    begin
      if (upcasestr(tl) <> upcasestr(name)) then{long names are the same? n: create id alias}
      begin
        number:=strf(tilda,1);
        while (len+length(number)>=8) do dec(len);
        f.name[len]:='~';
        for i:=1 to length(number) do f.name[len+i]:=number[i];
        inc(tilda);
      end else
      begin
        move(it.nameext,f.nameext,sizeof(f.nameext));
        break;
      end
    end else break;
  until (false); {until unique}
end;

function Init_Drives : boolean;
var d : byte;
begin
  nDrives := 0; fillchar(Drives,SizeOf(Drives),#0);
  for d:=$00 to $01 do if nDrives >= Max_Drives then break else
  begin
    if GetDrvBiosInfo(d,Drives[nDrives+1].DBI) then
    begin
      inc(nDrives);
      with Drives[nDrives] do Drive := d;
    end;
  end;
  for d:=$80 to $84 do if nDrives >= Max_Drives then break else
  begin
    if GetDrvBiosInfo(d,Drives[nDrives+1].DBI) then
    begin
      inc(nDrives);
      with Drives[nDrives] do Drive := d;
    end;
  end;
  for d:=$02 to $80-1 do if nDrives >= Max_Drives then break else
  begin
    if GetDrvBiosInfo(d,Drives[nDrives+1].DBI) then
    begin
      inc(nDrives);
      with Drives[nDrives] do Drive := d;
    end;
  end;
  for d:=$85 to $FF-1 do if nDrives >= Max_Drives then break else
  begin
    if GetDrvBiosInfo(d,Drives[nDrives+1].DBI) then
    begin
      inc(nDrives);
      with Drives[nDrives] do Drive := d;
    end;
  end;
  Init_Drives := nDrives > 0;
end;

function GetDrvSt(Drv : byte) : string;
begin
  if (Drv>=$00)and(Drv<=$01) then GetDrvSt := 'FDD'+chr(Drv+ord('0')) else
  if (Drv>=$80)and(Drv<=$84) then GetDrvSt := 'HDD'+chr(Drv-$80+ord('0'))
   else GetDrvSt := hexb(Drv)+'h';
end;

function Choose_Drive(x1,y1 : byte) : byte;
var od,d : byte; c : char; Done : boolean;
    sz   : double;

  procedure DrawItem(I,x,y : byte; Selected : boolean);
  var c : byte;
      s : string;
  begin
    if Selected then c:=03 else c:=01;
    VidB(x,y,x+DriveDlgW,c);
    if Selected then c:=00 else c:=15;
    writestf(strf(i,2),x+1,y,c);
    if Selected then c:=00 else c:=10;
    writestf(GetDrvSt(Drives[i].Drive),x+6,y,c);
    if Selected then c:=00 else c:=07;
    with Drives[i].DBI do
    begin
      writestf(strf(MaxTrack+1,6),x+14,y,c);
      writestf(strf(MaxHead+1,6),x+23,y,c);
      writestf(strf(MaxSector,5),x+32,y,c);
      sz := (1.0*SeHD*(MaxTrack+1)*DosSectorSize/1024);
      writestf(lz(size_str_kb(sz),09,' '),x+40,y,c)
    end;
  end;

begin
  Choose_Drive := 0;
  if (nDrives < 1) then if not Init_Drives then exit;
  SaveScr(2);
  if (x1=0) then x1 := text_maxx div 2 - DriveDlgW div 2;
  if (y1=0) then y1 := text_maxy div 2 - nDrives div 2 - 2;
  set_window(x1,y1,x1+DriveDlgW+2,y1+3+nDrives,Borders[brd_mix3],15,07,01,PA(10,01),' ',stHdr01,true);
  inc(x1);
  inc(y1);
  writestf(stNum,x1+1,y1,14);
  writestf(stDrive,x1+6,y1,14);
  writestf(stTracks,x1+14,y1,14);
  writestf(stHeads,x1+23,y1,14);
  writestf(stSector,x1+32,y1,14);
  writestf(stSize,x1+41,y1,14);
  inc(y1);
  CharVLine(x1+4,y1-1,y1+nDrives,PA(07,01),'│');
  CharVLine(x1+12,y1-1,y1+nDrives,PA(07,01),'│');
  CharVLine(x1+21,y1-1,y1+nDrives,PA(07,01),'│');
  CharVLine(x1+30,y1-1,y1+nDrives,PA(07,01),'│');
  CharVLine(x1+38,y1-1,y1+nDrives,PA(07,01),'│');
  CharHLine(x1,y1,x1+DriveDlgW,PA(07,01),'─');
  PutCh(x1+04,y1,'┼');
  PutCh(x1+12,y1,'┼');
  PutCh(x1+21,y1,'┼');
  PutCh(x1+30,y1,'┼');
  PutCh(x1+38,y1,'┼');
  for d:=1 to nDrives do DrawItem(d,x1,y1+d,false);
  d := 2; od := d; done := false;
  if (d>nDrives) then d:=nDrives;
  DrawItem(d,x1,y1+d,true);
  while not Done do if keypressed then
  begin
    c := readkey;
    if (c = #0) then
    begin
      c := readkey;
      if (c = #80)or(c = #77) then
      begin
        if (d >= nDrives) then d:=1 else inc(d);
      end else
      if (c = #72)or(c = #75) then
      begin
        if (d < 2 ) then d:=nDrives else dec(d);
      end else
      if (c = #71) then d:=1 else
      if (c = #79) then d:=nDrives;
    end else
    begin
      if (c = #27) then begin done := true; d:=0; end else
      if (c = #13)or(c = ' ') then done := true else
      if (c >= '1')and(c <= char(nDrives+ord('0'))) then begin d := byte(c)-ord('0'); done := true; end else
    end;
    if (d<>0) then if (d<>od) then
    begin
      DrawItem(od,x1,y1+od,false);

      DrawItem(d,x1,y1+d,true);
      od := d;
    end;
  end;
  PutScr(2);
  Choose_Drive := d;
end;

function Choose_Partition(x1,y1 : byte; Disk : byte; var pt : tPartition) : boolean;
var od,d,k,j,np : byte; c : char; Done : boolean; sz : real;

  procedure DrawItem(I,x,y : byte; Selected : boolean);
  var c : byte; se : byte; tr  : word;
      s  : string;
  begin
    if Selected then c:=03 else c:=01;
    VidB(x,y,x+LDriveDlgW,c);
    if Selected then c:=00 else c:=15;
    j := x+1;
    writestf(char(i-1+ord('C')),j,y,c);
    if Selected then c:=00 else c:=07;
    with pts[i] do
    begin
      inc(j,4);
      s := getsysst(sysid);
      if s='' then s:=hexb(sysid)+'h';
      writestf(s,j,y,c);
      UnPackCylSec(BegSC,tr,se);
      inc(j,23);
      writestf(strf(tr,6),j,y,c);
      inc(j,09);
      writestf(strf(BegHD,6),j,y,c);
      inc(j,09);
      writestf(strf(se,5),j,y,c);
      inc(j,08);
      sz := (1.0*(Size)*(DosSectorSize)/(1024));
      writestf(lz(size_str_kb(sz),09,' '),j,y,c)
    end;
  end;
begin
  Choose_Partition := false;
  np := 0;
  if Drives[Disk].Drive < 2 then with pt do
  begin
    Choose_Partition := true;
    begsc := 1;
    beghd := 0;
    np    := 1;
    exit;
  end else
  with tBoot16(buf) do
  begin
    Recalibrate(Drives[Disk].Drive);
    if not ReadSectors(Drives[Disk],0,1,1,buf) then exit;
    np:=0;
    repeat
      k:=1;
      inc(np);
      pts[np] := Part[1];
      while (Part[k].BegSC<1)and(k<4) do inc(k);
      if (k<=4) then
      begin
        if (np < Max_Partitions)and(Part[k].BegSC>0) then
        begin
          inc(k);
        end;
      end;
    until (Part[k].BegSC<1)or(k>4) or not ReadSectors(Drives[Disk],Part[k].beghd,Part[k].begsc,1,buf);
  end;
  if (nP < 1) then
  begin
    exit;
  end;
  SaveScr(2);
  if (x1=0) then x1 := text_maxx div 2 - LDriveDlgW div 2;
  if (y1=0) then y1 := text_maxy div 2 - nP div 2;
  Set_Window(x1,y1,x1+LDriveDlgW+2,y1+3+nP,Borders[brd_mix3],15,07,01,PA(10,01),' ',stHdr02,true);
  inc(x1);
  inc(y1);
  j := x1+1;
  writestf(':',j,y1,14);
  CharHLine(x1,y1+1,x1+LDriveDlgW,PA(07,01),'─');
  inc(j,4);
  CharVLine(j-2,y1,y1+nP+1,PA(07,01),'│');
  PutCh(j-2,y1+1,'┼');
  writestf(stSystem,j,y1,14);
  inc(j,23);
  CharVLine(j-2,y1,y1+nP+1,PA(07,01),'│');
  PutCh(j-2,y1+1,'┼');
  writestf(stTrack,j,y1,14);
  inc(j,9);
  CharVLine(j-2,y1,y1+nP+1,PA(07,01),'│');
  PutCh(j-2,y1+1,'┼');
  writestf(stHead,j,y1,14);
  inc(j,9);
  CharVLine(j-2,y1,y1+nP+1,PA(07,01),'│');
  PutCh(j-2,y1+1,'┼');
  writestf(stSector,j,y1,14);
  inc(j,8);
  CharVLine(j-2,y1,y1+nP+1,PA(07,01),'│');
  PutCh(j-2,y1+1,'┼');
  writestf(stSize,j+1,y1,14);
  inc(y1);
  for d:=1 to nP do DrawItem(d,x1,y1+d,false);
  d := 1; od := d; done := false;
  DrawItem(d,x1,y1+d,true);
  while not Done do if keypressed then
  begin
    c := readkey;
    if (c = #0) then
    begin
      c := readkey;
      if (c = #80)or(c = #77) then
      begin
        if (d >= nP) then d:=1 else inc(d);
      end else
      if (c = #72)or(c = #75) then
      begin
        if (d < 2 ) then d:=nP else dec(d);
      end else
      if (c = #71) then d:=1 else
      if (c = #79) then d:=nP;
    end else
    begin
      if (c = #27) then begin d:=0; done := true; end else
      if (c = #13)or(c = ' ')  then done := true else
      begin
        c:=UpCaseCh(c);
        if (c >= 'C')and(c <= char(nP-1+ord('C'))) then
        begin
          d := byte(c)-ord('C')+1; done := true;
        end;
      end;
    end;
    if (d > 0) then if (d<>od) then
    begin
      DrawItem(od,x1,y1+od,false);
      DrawItem(d,x1,y1+d,true);
      od := d;
    end;
  end;
  if (d > 0) then pt := Pts[d] else fillchar(pt,sizeof(pt),#0);
  PutScr(2);
  Choose_Partition := d > 0;
end;

{$IFDEF TestDrive}
function TestCluster(Pnl : byte; cl: longint): boolean;
var tm,tt2,ts,fs: longint; te,e: boolean;tt3:real;
    tt : word; ss,hh : byte;
    tp,bf,bf2 : array512;
    i,ii,iii:word;
    eq : boolean;
begin
  testcluster:=false;
  e:=false;
  with Panel[Pnl] do
  begin
    fs := get_cluster_sector(fd^,cl);
    if fs<0 then exit;
    fs:=fd^.start_sector+fs;
    DeCalcFS(fd^.Drive,fs,tt,hh,ss);
    Recalibrate(fd^.Drive.Drive);
    tm := BIOStimer;
    while (tm = BIOStimer) do;
    e := checksectors(fd^.Drive,tt,hh,ss,fd^.cluster_length);
    tt2 := BIOStimer;
    tt3:=(tt2-tm-1)*0.055;
    e:=not e{ and not (tt3>0.1)};
    if not e then
    begin
      for ts:=fs to fs+fd^.cluster_length do
      begin
        DeCalcFS(fd^.Drive,ts,tt,hh,ss);
        if ReadDataS(fd^.Drive,tt,hh,ss,1,bf) then
        begin
{$IFDEF EnableWrite}
          for i:=0 to 511 do tp[i]:=char(random(256));
          if WriteDataS(fd^.Drive,tt,hh,ss,1,tp) then
          begin
            for ii:=1 to nRetries do
            begin
              if ReadDataS(fd^.Drive,tt,hh,ss,1,bf2) then
              begin
                eq:=true;
                for i:=0 to 511 do if tp[i]<>bf2[i] then begin eq:=false; break; end;
                if not eq then begin e:=true; break; end;
              end else begin e:=true; break; end;
            end;
          end else e:=true;
          if not WriteDataS(fd^.Drive,tt,hh,ss,1,bf) then e:=true;
{$ENDIF}
        end else e:=true;
        if e then break;
      end;
    end;
  end;
  TestCluster:=not e;
end;

procedure TestPanelDrive(Pnl : byte);

  function ItemChar(i : longint; var cc : byte) : char;
  begin
    with Panel[Pnl] do
    begin
      if (i=fd^.Bad_Mark) then
      begin
        ItemChar:='B'; cc:=12;
      end else if (i>=fd^.Bad_Mark-$7)and(i<fd^.Bad_Mark) then
      begin
        ItemChar:='R'; cc:=07;
      end else if (i>fd^.Bad_Mark)and(i<=fd^.Max_Mark) then
      begin
        ItemChar:='F'; cc:=07;
      end else if (i>=2)and(i<=fd^.clusters-2) then
      begin
        ItemChar:='█'{'▓'}; cc:=07;
      end else if (i=0) then
      begin
        ItemChar:='░'; cc:=07;
      end else
      begin
        ItemChar:='E'; cc:=12;
      end;
    end;
  end;

  procedure ShowMap(sc : longint);
  var ch : char; i,ll : longint; cc,x,y : byte;
  begin
    for ll:=sc to sc+(80-2)*18-1 do with Panel[Pnl] do
    begin
      if keypressed then
      begin
        case readkey of
        #000: readkey;
        #027: exit;
        end;
      end;
      x := (ll-sc) mod (80-2)+2;
      y := (ll-sc) div (80-2)+2;
      if (ll > fd^.clusters-2) then PutchF(x,y,' ',07) else
      begin
        i := get_fat_item(fd^,ll);
        ch:=ItemChar(i,cc);
        putchf(x,y,ch,cc);
      end;
    end;
  end;

var sc,i,l,ll,cl : longint;
    nbc,tbc : longint;
    tm,starttm,curtm : longint;
    cc,x,y : byte;
    ch : char;

label done;
begin
  savescr(4);
  with Panel[Pnl] do
  begin
    Set_Window(1,1,80,24,borders[brd_double],15,15,08,PA(10,08),' ',stTesting,false);
    fil(1,25,80,' ');
    fil(2,20,79,'─');
    charvline(56,21,23,PA(15,08),'│');
    charvline(36,21,23,PA(15,08),'│');
    putch(36,20,'┬'); putch(56,20,'┬');
    putch(36,24,'╧'); putch(56,24,'╧');
    writestf(stFaultCluster,38,21,07);
    writestf(stErrorCluster,38,22,07);
    writestf(stResCluster,38,23,07);
    writestf(stCluster,3,21,07);
    writestf(stFrom,21,21,07);
    writestf(strf(fd^.clusters,1),21+length(stFrom)+1,21,11);
    writestf(stElapsed  ,58,21,07);
    writestf(stEstimated,58,22,07);
    writestf(stTimeLeft ,58,23,07);
    sc:=2; cl:=sc; tbc:=0; nbc:=0;
    ShowMap(sc);
    starttm := BIOStimer;
    while starttm = BIOStimer do;
    while (cl <= fd^.clusters-2) do
    begin
      x := (cl-sc) mod (80-2)+2;
      y := (cl-sc) div (80-2)+2;
      ch:=getch(x,y);
      putchf(x,y,'',11);

      writestf(strf(cl,8),12,21,11);
      writestf(hexl(get_fat_item(fd^,cl)),3,22,11);

      curtm := BIOStimer;
      tm:=round((curtm-starttm-1)*0.055);
      writestf(gettimest(tm),70,21,11);

      tm:=round(((curtm-starttm-1)/(cl))*(fd^.clusters-2)*0.055);
      writestf(gettimest(tm),70,22,11);

      tm:=tm-round((curtm-starttm-1)*0.055);
      writestf(gettimest(tm),70,23,11);

      if keypressed then
      begin
        case readkey of
        #000: readkey;
        #027: goto done;
        end;
      end;
      if (cl-sc+1) div (80-2)>=18 then
      begin
        sc:=cl;
        ShowMap(sc);
        x := (cl-sc) mod (80-2)+2;
        y := (cl-sc) div (80-2)+2;
        ch:= getch(x,y);
      end;
      i:=get_fat_item(fd^,cL);
      if i<>fd^.BAD_mark then
      begin
        if not TestCluster(Pnl,cl) then
        begin
          putchf(x,y,'B',12);
          recalibrate(fd^.Drive.Drive);
          i:=fd^.BAD_mark;
{$IFDEF EnableWrite}
          set_fat_item(fd^,cl,i);
{$ENDIF}
          inc(nbc);
          inc(tbc);
          cc:=12;
        end else
        begin
          cc:=14;
        end;
      end else begin inc(tbc); cc:=14; end;
      if cc<>12 then putchf(x,y,itemchar(i,byte(ch)),cc)
      else putchf(x,y,itemchar(i,byte(ch)),12);
      inc(cl);
      writestf(stBad+' '+strf(tbc,1)+' ('+strf(nbc,1)+' '+stNew+')',3,23,11);
    end;
  end;
  readkey;
Done:
  putscr(4);
end;
{$ENDIF}

  procedure QSort(Pnl : byte);
  var t,p : pointer;
    function Compare(it1,it2 : pItem) : integer;
    var
      C: Integer;
      P1P, P2P: Boolean;
      T1 : tFile_Item;
      td : datetime;
    label Done_cmp;
    begin
      Move(IT1^.F,t1,SizeOf(T1));
      C := 0;
      with IT2^.F do
      begin
          P1P:=t1.name[0]='.';
          p2p:=name[0]='.';
          if p1p and not p2p then c:=-1 else
          if p2p and not p1p then c:=+1;
          if c<>0 then goto done_cmp;
          if (Panel[Pnl].sortmode<>smSize)and(Panel[Pnl].sortmode<>smDateTime)then
           if ((T1.Attr xor Attr) and faDirectory = 0) then
          begin
            p1p:=isEXE(it1);
            p2p:=isEXE(it2);
            if p1p and not p2p then c:=-1 else
            if p2p and not p1p then c:=+1;
            if c<>0 then goto done_cmp;
            p1p:=isArchive(it1);
            p2p:=isArchive(it2);
            if p1p and not p2p then c:=-1 else
            if p2p and not p1p then c:=+1;
            if c<>0 then goto done_cmp;
          end;
          case Panel[Pnl].SortMode of
          smName: if (T1.Attr xor Attr) and faDirectory <> 0 then
              if T1.Attr and faDirectory <> 0 then C := -1 else C := 1 else
               if T1.NameExt < NameExt then C := -1
                else if T1.NameExt > NameExt then C := 1;
          smExtension: if (T1.Attr xor Attr) and faDirectory <> 0 then
              if T1.Attr and faDirectory <> 0 then C := -1 else C := 1 else
               if T1.Ext < Ext then C := -1 else
               if Ext < T1.Ext then C := 1 else
                if T1.Name < Name then C := -1 else
                if T1.Name > Name then C := 1;
          smSize: if (T1.Attr xor Attr) and faDirectory <> 0 then
              if T1.Attr and faDirectory <> 0 then C := -1 else C := 1 else
               if T1.Size > Size then C := -1 else
               if T1.Size < Size then C := 1 else
                if T1.NameExt < NameExt then C := -1 else
                if T1.NameExt > NameExt then C := 1;
          smDateTime:
              if ((T1.Attr xor Attr) and faDirectory <> 0) then
              if (T1.Attr and faDirectory <> 0) then C := -1 else C := 1 else
              begin
                if (T1.Year < Year) then C := 1 else
                if (T1.Year > Year) then C := -1 else
                 if (T1.Month < Month) then C := 1 else
                 if (T1.Month > Month) then C := -1 else
                  if (T1.Day > Day) then C := -1 else
                  if (T1.Day < Day) then C :=  1 else
                   if (T1.Hour < Hour) then C := 1 else
                   if (T1.Hour > Hour) then C := -1 else
                    if (T1.Minute < Minute) then C := 1 else
                    if (T1.Minute > Minute) then C := -1 else
                     if (T1.Sec < Sec) then C := 1 else
                     if (T1.Sec > Sec) then C := -1 else
                      if T1.NameExt < NameExt then C := -1 else
                      if T1.NameExt > NameExt then C := 1;
              end;
        end;
      end;
  Done_cmp:
      if Panel[Pnl].SortAsc then c:=-c;
      Compare := C;
    end;

  procedure QuickSort(L, R: Integer);
  var I, J: Integer;
  begin
    repeat
      I := L;
      J := R;
      P := Panel[Pnl].Items[(L + R) shr 1];
      repeat
        while Compare(Panel[Pnl].Items[I], P) < 0 do Inc(I);
        while Compare(Panel[Pnl].Items[J], P) > 0 do Dec(J);
        if I <= J then
        begin
          T := Panel[Pnl].Items[I]; Panel[Pnl].Items[I] := Panel[Pnl].Items[J]; Panel[Pnl].Items[J] := T;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then QuickSort(L, J);
      L := I;
    until I >= R;
  end;

  begin
    with Panel[Pnl] do
     if (Panel[Pnl].nItems > 0)and(SortMode<>smUnsorted) then QuickSort(0, Panel[Pnl].nItems-1);
  end;

  procedure FreeItems(Pnl : byte);
  var i : word;
  begin
    with Panel[Pnl] do
    begin
      if nItems>0 then for i:=0 to nItems-1 do if Items[i]<>nil then with Items[i]^.F do
      begin
        if LFName<>nil then freemem(LFName,byte(LFName^[0])+1);
{
        if LFName<>nil then freemem(LFName,((byte(LFName^[0])+1) div 8 + 1)*8);
        if LFName<>nil then freemem(LFName,65535);
}
        Dispose(Items[i]);
      end;
      nItems := 0;
      _ds:=0; _dp:=0;
      _x := 1; _y := 1;
    end;
  end;

  function ReadDir(Pnl : byte) : integer;
  var k,j,i  : longint;
      Dir    : array[0..15] of tDirElement;
      DirS   : longint;
      cl     : longint;
      tlfn   : string;
      dt     : datetime;
      id,crc : byte;
      fl     : boolean;
  begin
    ReadDir := 0;
    FreeItems(Pnl);
    with Panel[Pnl] do
    begin
      lfnofs  := 0; maxlfnofs := 0;
      tlfn:=''; id:=0; crc:=0;
      k  := 0;                       {Количество просмотренных элементов}
      j  := 0;                       {Текущий элемент каталога}
      cl := Cluster;
      if cl<2 then cl:=fd^.root_cluster;
      DirS := Get_Cluster_Sector(fd^,cl);
      fillchar(Dir,sizeof(dir),#0);
      Read_Sectors(fd^,DirS,1,Dir);  {Читаем первый сектор}
      repeat
        if Dir[j].Name[0]=#0 then break; {Обнаружен конец списка}
        fl:=false;
        if (Dir[j].Attr = faExt)and(UseLFN)
         then if (Dir[j].Name[0]<>#$E5) then fl:=true else
          if (ShowDeleted) then fl:=true;
        if (fl) then
        begin
          if ID>0 then
          begin
            dec(id);
            if (tLFNelement(Dir[j]).id=id)and(tLFNelement(Dir[j]).crc=crc) then
            begin
              AddLfn(tlfn,tLFNElement(Dir[j]));
            end;
          end else
          begin
            id:=tLFNelement(Dir[j]).id;
            if id > $40 then dec(id,$40);
            crc := tLFNelement(Dir[j]).crc;
            tlfn:='';
            AddLfn(tlfn,tLFNElement(Dir[j]));
          end;
        end else
        begin
          fl:=false;
          if (Dir[j].Attr and faVolumeID=0)
           then if (Valid_Alias(dir[j].nameext))
            then if (Dir[j].Name[0]<>#$E5) then fl:=true else
             if (ShowDeleted) then fl:=true;
          if (fl) then if rTrim(dir[j].name)='.' then if not ShowDot then fl:=false;
          if (fl) then
          begin
            inc(nItems);
            new(Items[nItems-1]);
            with Items[nItems-1]^.F do
            begin
              sel:=false;
              move(Dir[j].name,name,sizeof(name));
              move(Dir[j].ext,ext,sizeof(ext));
              attr := dir[j].attr;
              if (dir[j].attr and faDirectory<>0) then ShowSize:=false else ShowSize:=false;
              size := dir[j].size;
              unpacktime(dir[j].date,dt);
              Year  := dt.year; Month := dt.Month; Day   := dt.Day;
              Hour  := dt.Hour; Minute:= dt.Min; Sec   := dt.Sec;
              cluster  := ((dir[j].cluster) + (longint(dir[j].Clus_hi) shl 16));
              LFName := nil;
              if UseLFN then
              if (id=1)and(tlfn<>'') then
              begin
                if lcrc(NameExt) = crc then
                begin
                  tlfn := RTrim(tlfn);
                  if tlfn<>upcasestr(RTrim(nameext)) then
                  begin
                    if length(tlfn)>12 then if maxlfnofs<length(tlfn)-12 then
                     maxlfnofs:=length(tlfn)-12;
                    getmem(LFName,length(tlfn)+1);
                    LFName^ := tlfn;
                  end;
                end;
              end;
            end;
          end;
          tlfn:=''; id:=0; crc:=0;
        end;
        if j >= 15 then
        begin         {Исчерпан сектор каталога}
          j := 0;     {Продолжаем с 1-го элемента следующего сектора}
          inc(k,16);  {k - сколько элементов просмотрели}
          inc(dirs);
          if (cl<2) then
          begin
            if (fd^.root_size>0) then if (k >= fd^.root_size) then break;
          end else
          if (k div 16) mod fd^.Cluster_length = 0 then
          begin     {Исчерпан кластер - ищем следующий}
            {Получаем новый кластер}
            cl := Get_FAT_Item(fd^,cl);
            if (cl >= fd^.bad_mark)or(cl < 2) then break;
            {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
            DirS := Get_Cluster_Sector(fd^,cl); {Получаем нoвый сектор}
          end;
          Read_Sectors(fd^,DirS,1,Dir);
        end else inc(j);
        if nItems>=max_items then break;
      until false;
    end;
    QSort(Pnl);
  end;

var exsrsz : boolean;

  function GetDirSize(Pnl : byte; DirC : longint) : longint;
  var k,j,i  : longint;
      Dir    : array[0..15] of tDirElement;
      DirS   : longint;
      cl,sz  : longint;
  begin
    GetDirSize := 0; sz:=0;
    if exsrsz then exit;
    with Panel[Pnl] do
    begin
      k  := 0;                       {Количество просмотренных элементов}
      j  := 0;                       {Текущий элемент каталога}
      cl := DirC;
      if cl<2 then cl:=fd^.root_cluster;
      DirS := Get_Cluster_Sector(fd^,cl);
      fillchar(Dir,sizeof(dir),#0);
      Read_Sectors(fd^,DirS,1,Dir);  {Читаем первый сектор}
      repeat
        if Dir[j].Name[0]=#0 then break; {Обнаружен конец списка}
        if keypressed then if getkey=kbESC then begin exsrsz:=true; GetDirSize:=0; exit; end;
        begin
          if (Dir[j].Attr and faVolumeID=0)
           then if (Valid_Alias(dir[j].nameext))
            then if (Dir[j].Name[0]<>#$E5)
             then if (dir[j].name[0]<>'.') then
          begin
            if (dir[j].attr and faDirectory<>0) then
            begin
              sz := sz + GetDirSize(Pnl,((dir[j].cluster) + (longint(dir[j].Clus_hi) shl 16)));
              if exsrsz then exit;
            end else sz := sz + dir[j].size;
          end;
        end;
        if j >= 15 then
        begin         {Исчерпан сектор каталога}
          j := 0;     {Продолжаем с 1-го элемента следующего сектора}
          inc(k,16);  {k - сколько элементов просмотрели}
          inc(dirs);
          if (cl<2) then
          begin
            if (fd^.root_size>0) then if (k >= fd^.root_size) then break;
          end else
          if (k div 16) mod fd^.Cluster_length = 0 then
          begin     {Исчерпан кластер - ищем следующий}
            {Получаем новый кластер}
            cl := Get_FAT_Item(fd^,cl);
            if (cl >= fd^.bad_mark)or(cl < 2) then break;
            {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
            DirS := Get_Cluster_Sector(fd^,cl); {Получаем нoвый сектор}
          end;
          Read_Sectors(fd^,DirS,1,Dir);
        end else inc(j);
      until false;
    end;
    GetDirSize := sz;
  end;

  function ChoosePanelDrive(Pnl : byte) : boolean;
  var d   : byte;
      pt  : tPartition;
      tfd : tFat_Device;
  label ChooseDrv;
  begin
    ChoosePanelDrive:=false;
ChooseDrv:
    d := Choose_Drive(0,0);
    if (d < 1) then exit;
    if not Choose_Partition(0,0,D,pt) then goto ChooseDrv else
    begin
      if (Mount_Fat_Device(Drives[d],pt,fs_auto,tfd)=NoError) then
      with Panel[Pnl] do
      begin
        Visible := true;
        if (fd=nil) then new(fd);
        fd^ := tfd;
        Cluster := fd^.root_cluster;
        _x := 1; _y := 1;
        _dp:=0; _ds:=0;
        lfnofs  :=0;
        ChoosePanelDrive:=true;
      end else goto ChooseDrv;
    end
  end;

function MakeLName(LFName : String; ofs,maxlen : byte) : string;
var l  : string;
    tl : boolean;
begin
  tl:=false;
  if maxlen<1 then maxlen:=1;
  if ofs+maxlen>length(LFName) then
  begin
    l:=copy(LFName,length(LFName)-maxlen+1,maxlen);
    if (ofs>0) then if length(LFName)>maxlen then tl:=true;
  end else
  begin
    l:=copy(LFName,1+ofs,maxlen+1);
    if (ofs>0) then tl:=true;
  end;
  if tl then l[1]:=#27;
  if length(l)>maxlen then
  begin
    l[0]:=char(maxlen-1);
    l:=l+#26;
  end;
  MakeLName := l;
end;

function ListDirs : longint;

  procedure DrawItem_Brief(Pnl,I,x,y : word; selected : boolean);
  var c,cc  : byte;
      l,s,ex  : string;
      dr,lf : boolean;
      td : DateTime;
  begin
    with Panel[Pnl] do
    begin
      if (nItems<=0) then exit else if(Items[i] = nil)or(i>nItems-1)or(not Visible) then exit;
      with Items[i]^.F do
      begin
        fil(x1+x,y1+y,x1+x+11,' ');
        dr := Attr and faDirectory<>0;
        lf:=false;
        if (LFName<>nil) then if length(LFName^)>0 then
        begin
          lf:=true;
          l:=makelname(LFName^,lfnofs,12);
        end;
        s := RTrim(name);
        ex := RTrim(ext);
        if (dr) then c:=15 else
        begin
          c  := GetItemColor(Items[i]);
          s  := locase(s);
          ex := locase(ex);
        end;
        if sel then cc:=14 else
        if selected then cc:=00 else cc:=c;
        if not lf then
        begin
          writestf(s,x1+x,y1+y,cc);
          writestf(ex,x1+x+9,y1+y,cc);
        end else
        begin
          writestf(l,x1+x,y1+y,cc);
        end;
        if selected then
        begin
          fil(x1+1,y2-2,x2-1,' ');
          fil(x1+1,y2-1,x2-1,' ');
          if ex<>'' then s:=s+'.'+ex;
          writestf(s,x1+1,y2-2,11);
          writestf(hexl(cluster),x1+1,y2-1,11);
          if lf then
          begin
            l:=makelname(LFName^,lfnofs,x2-x1-10);
            writestf(l,x1+10,y2-1,c);
          end;
          if dr then
          begin
            if ShowSize then
            begin
              s:=size_str(size);
            end else
            begin
              s:=stDirectory;
              if name[1]='.' then s:=''+s+'' else s:=''+s+'';
            end;
          end else
          begin
            s:=size_str(size);
          end;
          writestf(s,x1+14,y2-2,11);
          writestf(lz(strf(day,1),2,'0')+'.'+lz(strf(month,1),2,'0')+'.'+lz(strf(year mod 100,1),2,'0')+' '+
                   lz(strf(hour,1),2,'0')+':'+lz(strf(minute,1),2,'0'),x1+25,y2-2,11);
          cc:=03;
        end else cc:=08;
        VidB(x1+x,y1+y,x1+x+11,cc);
      end;
    end;
  end;

  procedure ShowDir(Pnl : byte; dp_ : word);
  var i : integer; x,y : word;
      tdf,tff,tsz : longint;
      s : string;
  begin
    with Panel[Pnl] do
    begin
      x := 1; y := 1;
      if (Scr_buf<>nil) then
      begin
        move(ptr(Text_Seg,0)^,Scr_buf^,80*25*2);
        oText_Seg:=Text_Seg;
        Text_Seg:=seg(Scr_Buf^);
      end;
      for i:=1 to 57 do
      begin
        if (dp_ < nItems)and(dp_ >= 0) then
        begin
          DrawItem_Brief(Pnl,dp_,x,y,false)
        end else
        begin
          fil(x1+x,y1+y,x1+x+11,' ');
          vidb(x1+x,y1+y,x1+x+11,08);
        end;
        if (y >= (y2-y1)-4) then if (x+13 >= (x2-x1)-1) then break else
        begin
          y := 1; inc(x,13);
        end else inc(y);
        inc(dp_);
      end;
      if nItems>0 then
      begin
        tsz:=0; tff:=0; tdf:=0;
        for i:=0 to nItems-1 do if Items[i]^.f.sel then
        begin
          if (Items[i]^.f.attr and faDirectory<>0) then
          begin
            inc(tdf);
            if Items[i]^.f.ShowSize then
            if Items[i]^.f.size>0 then
            begin
              tsz:=tsz+Items[i]^.f.size;
            end
          end else if Items[i]^.f.size>0 then
          begin
            tsz:=tsz+Items[i]^.f.size;
            inc(tff);
          end;
        end;
        charhline(x1+1,y2-3,x2-1,pa(15,08),'─');
        if (tff>0)or(tdf>0) then
        begin
          s:=' '+fstr(tsz,1,',',' ',LeftAlign)+' (F:'+strf(tff,1)+' D:'+strf(tdf,1)+') ';
          writest(s,x1+((x2-x1) - length(s)) div 2,y2-3);
        end;
      end;
      if (Scr_buf<>nil) then
      begin
        Text_Seg:=oText_Seg;
        wretr;
        move(Scr_buf^,ptr(Text_Seg,0)^,80*25*2);
      end;
    end;
  end;

  procedure ShowPanelDriveInfo(Pnl : byte);
  var yy : byte;
      s  : string;
  begin
    savescr(4);
    with Panel[Pnl] do
    begin
      fillscr(x1+1,y1+1,x2-1,y2-1,' ');
      fil(01,25,80,' ');
      recolbg(x1+1,y1+1,x2-1,y2-1,08);
      recolfg(x1+1,y1+1,x2-1,y2-1,07);
      yy:=y1+2;
      cwritest(colst(16*08+10)+stDriveInfo,x1+1+(x2-x1) div 2 - length(stDriveInfo) div 2,yy);
      inc(yy,2);
      cwritest(stBiosDrv+colst(16*cDGray+cLCyan)+hexb(fd^.Drive.Drive)+'h'+
               colst(16*cDGray+cGray)+' '+
               '(C:'+colst(16*cDGray+cLCyan)+strf(fd^.drvbiosinfo.maxtrack+1,1)+colst(16*cDGray+cGray)+
               ',H:'+colst(16*cDGray+cLCyan)+strf(fd^.drvbiosinfo.maxhead +1,1)+colst(16*cDGray+cGray)+
               ',S:'+colst(16*cDGray+cLCyan)+strf(fd^.drvbiosinfo.maxsector ,1)+colst(16*cDGray+cGray)+')',x1+2,yy);
      inc(yy);
      cwritest(stPartFrom+colst(16*cDGray+cLCyan)+strf(fd^.start_sector,1)+colst(16*cDGray+cGray)+stSectora,x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+strf(fd^.sectors,1)+colst(16*cDGray+cGray)+stPartLength,x1+2,yy);
      inc(yy,2);
      cwritest(stFileSys+colst(16*cDGray+cLCyan)+'FAT'+strf(fd^.fat_bits,1)+colst(16*cDGray+cGray)+
               ' ('+colst(16*cDGray+cLCyan)+strf(fd^.fats,1)+colst(16*cDGray+cGray)+' '+stCopies+')',x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+strf(fd^.fat_length,1)+colst(16*cDGray+cGray)+stFatLength,x1+2,yy);
      inc(yy);
      if (fd^.root_size<=0) then s:='VAR' else s:=strf(fd^.root_size,1);
      cwritest(colst(16*cDGray+cLCyan)+s+colst(16*cDGray+cGray)+stRootElements,x1+2,yy);
      inc(yy);
      cwritest(stRootCluster+colst(16*cDGray+cLCyan)+strf(fd^.root_cluster,1)+colst(16*cDGray+cGray)+
               ' ('+colst(16*cDGray+cLCyan)+strf(fd^.root_start,1)+colst(16*cDGray+cGray)+stOtnSec+')',x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+strf(fd^.clusters,1)+colst(16*cDGray+cGray)+stClusters,x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+strf(fd^.cluster_length,1)+colst(16*cDGray+cGray)+stClusterLength,x1+2,yy);
      inc(yy);
      if (fd^.free_clusters<0) then S:='0' else s:=strf(fd^.free_clusters,1);
      cwritest(colst(16*cDGray+cLCyan)+s+colst(16*cDGray+cGray)+stFreeClusters,x1+2,yy);

      while keypressed do readkey; if readkey=#0 then readkey;
    end;
    putscr(4);
  end;

var i : word;
    ods,odp,ds,dp : word;
    shs,ox,oy,x,y   : byte;
    ch : char;
    key,mkey : word;
    needupdt,ex,Done : boolean;
    SeekLast,found : boolean;
    NeedSort       : boolean;
    mf,l : longint;

label ReInit;
begin
  SaveScr(3);
  CurPnl:=0;
  for i:=0 to 1 do
  with Panel[i] do
  begin
    Set_Window(x1,y1,x2,y2,borders[brd_double],15,07,08,10,' ','',false);
    CharVLine(x1+13,y1+1,y2-4,PA(15,08),'│');
    CharVLine(x1+26,y1+1,y2-4,PA(15,08),'│');
    CharHLine(x1+1,y2-3,x2-1,PA(15,08),'─');
  end;
  ReadDir(CurPnl);
  ReadDir(1-CurPnl);
  ShowDir(1-CurPnl,0);
  with Panel[1-CurPnl] do
  begin
    DrawItem_Brief(1-CurPnl,_dp,_x,_y,true);
    DrawItem_Brief(1-CurPnl,_dp,_x,_y,false);
  end;
  needupdt := true;
  done := false;
  SeekLast := false;
ReInit:
  with Panel[CurPnl] do
  begin
    if NeedSort then begin QSort(CurPnl); NeedSort:=false; end;
    x  := _x;
    y  := _y;
    dp := _dp;
    ds := _ds;
    mkey:=kbNokey;
    if (SeekLast)and(Panel[CurPnl].nItems>0) then
    begin
      SeekLast := false;
      for i:=0 to Panel[CurPnl].nItems-1 do {if (items[i]^.f.Attr and faDirectory<>0) then}
      begin
        found:=false;
        if (lastclus=0)or(lastclus=fd^.root_cluster) then
        begin
          if RTrim(items[i]^.f.nameext)='..' then found:=true
        end else
          if (items[i]^.f.cluster=Panel[CurPnl].lastclus) then found:=true;
        if found then
        begin
          dp:=i;
          ds:=0;
          if dp>56 then
          begin
            ds:=dp-56;
            x := ((56) div 19)*13+1;
            y := ((56) mod 19)+1;
          end else
          begin
            x := ((dp) div 19)*13+1;
            y := ((dp) mod 19)+1;
          end;
          break;
        end;
      end;
    end;
  end;
  odp:=dp; ods:=ds; ox:=x; oy:=y;
  repeat
{$IFDEF DEBUG}
    writestf('['+hexl(memavail)+']',70,01,cLGreen);
{$ENDIF}
    if (ods<>ds)or(odp<>dp)or(NeedUpdt) then
    begin
      DrawItem_Brief(CurPnl,odp,ox,oy,false);
      if (ods<>ds)or(NeedUpdt) then
      begin
        ShowDir(CurPnl,ds);
        ods:=ds;
      end;
      DrawItem_Brief(CurPnl,dp,x,y,true);
      odp:=dp; ox:=x; oy:=y;
      needupdt := false;
   end;
   i:=shiftstate;
   if (i<>shs) then
   begin
     fil(1,25,80,' ');
     vidb(1,25,80,07);
     if (shiftstate and shsAlt<>0)and(shiftstate and shsCtrl=0)
       then cwritest(st_ALT_st,1,text_maxy) else
     if (shiftstate and shsCtrl<>0)and(shiftstate and shsAlt=0)
       then cwritest(st_Ctrl_st,1,text_maxy) else
     if ((shiftstate and shsRShift<>0)or(shiftstate and shsLShift<>0))and(shiftstate and shsCtrl=0)and(shiftstate and shsAlt=0)
       then cwritest(st_Shift_st,1,text_maxy) else
     if (shiftstate and shsCtrl=0)and(shiftstate and shsAlt=0)and(shiftstate and shsRShift=0)and(shiftstate and shsLShift=0)
       then cwritest(st_Normal_st,1,text_maxy);
     shs:=i;
   end;
   if mkey<>kbNokey then begin key:=mkey; mkey:=kbNokey end else key:=getkey;
   if key<>kbNoKey then
   case key of
   kbDown: {Down}
    if (Panel[CurPnl].nItems > 0) then
    begin
      if (dp < Panel[CurPnl].nItems-1) then
      begin
        inc(dp); inc(y);
        if (y >= 20) then
        begin
          if (x < 27) then begin y:=1; inc(x,13); end else
            begin
              ds := dp-56;
              y:=19;
            end;
        end;
      end;
    end;
   kbUp: {Up}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (dp > 0) then
      begin
        dec(dp); dec(y);
        if (y < 1) then
        begin
          if (x > 1) then begin y:=19; dec(x,13); end
            else begin ds := dp; y:=1; end;
        end;
      end;
    end;
   kbRight: {Right}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (dp+19 > Panel[CurPnl].nItems-1) then begin mkey:=kbEnd; end else
      begin
        if (x >= 27) then
        begin
          if (dp+19 > Panel[CurPnl].nItems-1) then begin mkey:=kbEnd; end else inc(dp,19);
          ds := dp-56;
          x:=27; y:=19;
        end
        else
        begin
          inc(dp,19);
          inc(x,13);
        end;
      end;
    end;
   kbLeft: {Left}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (dp>18) then
      begin
        if (x>=13) then
        begin
          dec(dp,19); dec(x,13);
        end else
        begin
          dec(dp,19); ds := dp;
          x:=1; y:=1;
        end;
      end else begin mkey:=kbHome; end;
    end;
   kbHome: {Home}
    if (Panel[CurPnl].nItems>0) then
    begin
      x := 1; y := 1; ds:=0; dp:=0;
    end;
   kbEnd: {End}
    if (Panel[CurPnl].nItems>0) then
    begin
      dp := Panel[CurPnl].nItems-1;
      if (Panel[CurPnl].nItems-ds < 57) then
      begin
        x := ((Panel[CurPnl].nItems-ds-1) div 19)*13+1;
        y := (Panel[CurPnl].nItems-ds-1) mod 19+1;
      end else
      begin
        y  := 19; x:=27;
        ds := dp-56;
      end;
    end;
   kbPgUp: {PgUp}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (dp > 56) then dec(dp,57) else dp:=0;
      ds := dp;
      x:=1; y:=1;
    end;
   kbPgDn: {PgDn}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (dp+57 < (Panel[CurPnl].nItems-ds)) then
      begin
        inc(dp,57);
        ds := dp-56;
        x := 27; y := 19;
        NeedUpdt:=true;
      end else mkey:=kbEnd;
    end;
   kbCtrlHome: {Ctrl+Home}
    if (Panel[CurPnl].nItems>0) then
    begin
      x := 1; y := 1;
      dp := ds + (x div 19);
    end;
   kbCtrlEnd: {Ctrl+End}
    if (Panel[CurPnl].nItems>0) then
    begin
      if (Panel[CurPnl].nItems-ds < 57) then
      begin
        x := ((Panel[CurPnl].nItems-ds-1) div 19)*13+1;
        y := (Panel[CurPnl].nItems-ds-1) mod 19+1;
        dp := ds+(Panel[CurPnl].nItems-ds)-1;
      end else
      begin
        x  := 27; y := 19;
        dp := ds + 56;
      end;
    end;
   kbAltI:
   begin
     ShowPanelDriveInfo(CurPnl);
   end;
   kbF1:
   begin

   end;
   kbF3,kbAltF3: with Panel[CurPnl] do if (nItems>0) then if (Items[dp]<>nil) then
   if (Items[dp]^.f.attr and faDirectory=0) then
   begin
     ViewFile(CurPnl,dp);
   end else
   begin
     for i:=0 to nItems-1 do
      if Items[i]^.f.sel then
      begin
        exsrsz:=false;
        Items[i]^.f.size := GetDirSize(CurPnl,Items[i]^.f.cluster);
        Items[i]^.f.ShowSize:=true;
        NeedSort:=true;
        NeedUpdt:=true;
      end;
     DrawItem_Brief(CurPnl,dp,x,y,true);
     goto ReInit;
   end;
   kbAltF1: {Alt+F1}
    begin
      DrawItem_Brief(CurPnl,dp,x,y,false);
      if ChoosePanelDrive(0) then
      with Panel[0] do
      begin
        _x  := 1;
        _y  := 1;
        _ds := 0;
        _dp := 0;
        LastClus:=0;
        SeekLast:=false;
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
        ReadDir(0);
        if CurPnl=0 then begin NeedUpdt:=true; goto ReInit end else
        begin
          ShowDir(0,_ds);
          DrawItem_Brief(0,_dp,_x,_y,true);
          DrawItem_Brief(0,_dp,_x,_y,false);
        end;
      end;
      DrawItem_Brief(CurPnl,dp,x,y,true);
    end;
   kbAltF2: {Alt+F2}
    begin
      mf:=memavail;
      DrawItem_Brief(CurPnl,dp,x,y,false);
      if ChoosePanelDrive(1) then
      with Panel[1] do
      begin
        mf:=memavail;
        _x := 1;
        _y := 1;
        _ds := 0;
        _dp := 0;
        LastClus:=0;
        SeekLast:=false;
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
        mf:=memavail;
        ReadDir(1);
        mf:=memavail;
        if CurPnl=1 then begin NeedUpdt:=true; goto ReInit end else
        begin
          ShowDir(1,_ds);
          DrawItem_Brief(1,_dp,_x,_y,true);
          DrawItem_Brief(1,_dp,_x,_y,false);
        end;
      end;
      DrawItem_Brief(CurPnl,dp,x,y,true);
      mf:=memavail;
    end;
   kbAltRight,kbCtrlRight: {Alt,Ctrl+Right}
    if (Panel[CurPnl].nItems>0) then
    begin
      if Panel[CurPnl].lfnofs<Panel[CurPnl].maxlfnofs then
      begin
        inc(Panel[CurPnl].lfnofs);
        needupdt := true;
      end;
    end;
   kbAltLeft,kbCtrlLeft: {Alt,Ctrl+Left}
    if (Panel[CurPnl].nItems>0) then
    begin
      if Panel[CurPnl].lfnofs>0 then
      begin
        dec(Panel[CurPnl].lfnofs);
        needupdt := true;
      end else Panel[CurPnl].lfnofs:=0;
    end;
   kbAltHome,kbCtrlPgUp: {Alt+Home}
    if (Panel[CurPnl].nItems>0) then
    begin
      Panel[CurPnl].lfnofs := 0;
      NeedUpdt:=true;
    end;
   kbAltEnd,kbCtrlPgDn: {Alt+End}
    if (Panel[CurPnl].nItems>0) then
    begin
      Panel[CurPnl].lfnofs := Panel[CurPnl].maxlfnofs;
      NeedUpdt:=true;
    end;
   kbCtrlGPLus:
   with Panel[CurPnl] do
   begin
     SortAsc:=false;
     NeedSort:=true;
     NeedUpdt:=true;
     goto ReInit;
   end;
   kbCtrlGMinus:
   with Panel[CurPnl] do
   begin
     SortAsc:=true;
     NeedSort:=true;
     NeedUpdt:=true;
     goto ReInit;
   end;
   kbCtrlBSlsh: {Ctrl+\}
    begin
      DrawItem_Brief(CurPnl,dp,x,y,false);
      with Panel[CurPnl] do
      begin
        LastClus := 0;
        Cluster := Panel[CurPnl].fd^.root_cluster;
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
      end;
      ReadDir(CurPnl);
      NeedUpdt:=true;
      SeekLast:=false;
      goto ReInit;
    end;
   kbCtrlF1,kbCtrlF2,kbCtrlF3,kbCtrlF4,kbCtrlF5:
   with Panel[CurPnl] do
   begin
     if key=kbCtrlF1 then SortMode:=smName else
      if key=kbCtrlF2 then SortMode:=smExtension else
       if key=kbCtrlF3 then SortMode:=smSize else
        if key=kbCtrlF4 then SortMode:=smDateTime else
         if key=kbCtrlF5 then
         begin
           SortMode:=smUnsorted;
           fil(x1+1,y2-2,x2-1,' ');
           fil(x1+1,y2-1,x2-1,' ');
           ReadDir(CurPnl);
         end;
      _x := 1;
      _y := 1;
     _ds := 0;
     _dp := 0;
     NeedUpdt := true;
     NeedSort := true;
     goto reinit;
   end;
   kbAltDot:
   with Panel[CurPnl] do
   begin
     ShowDot:= not ShowDot;
     mkey:=kbCtrlR;
   end;
   kbF12:
   begin
     savescr(4);
     fillscr(1,1,80,25,' ');
     recola(1,1,80,25,0);
     while keypressed do readkey;
     if readkey=#0 then readkey;
     putscr(4);
   end;
   kbAltF:
   begin
     Flush_Cache;
   end;
   kbTab: {Tab}
    begin
      if (Panel[CurPnl].nItems>0) then DrawItem_Brief(CurPnl,dp,x,y,false);
      with Panel[CurPnl] do
      begin
        _x  := x;
        _y  := y;
        _ds := ds;
        _dp := dp;
        NeedUpdt := true;
        SeekLast := false;
      end;
      CurPnl:=1-CurPnl;
      goto reinit;
    end;
   kbAltR,kbCtrlR: {Ctrl+R}
    begin
      with Panel[CurPnl] do
      begin
        if (Panel[CurPnl].nItems>0)and(dp<=Panel[CurPnl].nItems-1) then if (Items[dp]<>nil) then
        begin
          lastclus:=Items[dp]^.f.cluster;
          SeekLast:=true;
          _ds:=ds; _dp:=dp;
          _x:=x; _y:=y;
        end else seeklast:=false;
        Flush_Cache;
        ReadDir(CurPnl);
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
        needupdt:=true;
        goto reinit;
      end;
    end;
{$IFDEF TestDrive}
   kbCtrlT: {Ctrl+T}
    begin
      TestPanelDrive(CurPnl);
      mKey:=kbCtrlR;
    end;
{$ENDIF}
   kbCtrlN: {Ctrl+N}
    with Panel[CurPnl] do
    begin
      UseLFN:=not UseLFN;
      mKey:=kbCtrlR;
    end;
   kbCtrlS:
   begin
     DoSearch;
   end;
   kbCtrlP:
   begin
     DoSearchFileNames;
   end;
   kbCtrlD:
   begin
     DoDirs;
   end;
   kbCtrlY:
   begin
     DoFiles;
   end;
   kbCtrlU:
   begin
     DoFileDefines;
   end;
   kbCtrlW:
   begin
     WriteFAT;
   end;
   kbCtrlX: {Ctrl+X}
    with Panel[CurPnl] do
    begin
      ShowDeleted:=not ShowDeleted;
      mKey:=kbCtrlR;
    end;
   kbBack:
   if (Panel[CurPnl].nItems > 0) then with Panel[CurPnl] do
   begin
     if (Cluster=0)or(Cluster=fd^.root_cluster) then
     begin
       ReadDir(CurPnl);
       NeedUpdt:=true;
       seeklast:=false;
       goto ReInit;
     end else
     for i:=0 to nItems-1 do
      if Items[i]<>nil then
      if (Items[i]^.f.Attr and faDirectory<>0)and(Items[i]^.f.Name[0]='.')and(Items[i]^.f.Name[1]='.') then
      begin
        DrawItem_Brief(CurPnl,dp,x,y,false);
        with Panel[CurPnl] do
        begin
          LastClus := Cluster;
          Cluster  := Items[i]^.F.Cluster;
          fil(x1+1,y2-2,x2-1,' ');
          fil(x1+1,y2-1,x2-1,' ');
        end;
        ReadDir(CurPnl);
        NeedUpdt:=true;
        SeekLast := true;
        goto ReInit;
      end;
   end;
   kbINS:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     if (Items[dp]^.f.name[0]<>'.') then
     begin
       Items[dp]^.f.sel:=not Items[dp]^.f.sel;
       DrawItem_Brief(CurPnl,dp,x,y,true);
     end;
     NeedUpdt:=true;
     mkey:=kbDown;
   end;
   kbAst,kbGrayAst:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i:=0 to nItems-1 do if (Items[i]^.f.attr and faDirectory=0)and(Items[i]^.f.name[0]<>'.')
       then Items[i]^.f.Sel:= not Items[i]^.f.Sel;
     NeedUpdt:=true;
   end;
   kbCtrlGAst:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i:=0 to nItems-1 do if (Items[i]^.f.attr and faDirectory<>0)and(Items[i]^.f.name[0]<>'.')
       then Items[i]^.f.Sel:= not Items[i]^.f.Sel;
     NeedUpdt:=true;
   end;
   kbGrayMinus:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i:=0 to nItems-1 do Items[i]^.f.Sel:= false;
     NeedUpdt:=true;
   end;
   kbGrayPlus:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i:=0 to nItems-1 do if Items[i]^.f.name[0]<>'.' then Items[i]^.f.Sel:= true;
     NeedUpdt:=true;
   end;
   kbEnter: {Enter}
    if (Panel[CurPnl].nItems > 0) then
    begin
      if Panel[CurPnl].Items[dp]^.F.Attr and faDirectory<>0 then
      begin
        if (Panel[CurPnl].Items[dp]^.F.Cluster>=0)and(Panel[CurPnl].Items[dp]^.F.Cluster<=Panel[CurPnl].fd^.clusters)then
        begin
          DrawItem_Brief(CurPnl,dp,x,y,false);
          with Panel[CurPnl] do
          begin
            LastClus := Cluster;
            Cluster := Items[dp]^.F.Cluster;
            fil(x1+1,y2-2,x2-1,' ');
            fil(x1+1,y2-1,x2-1,' ');
          end;
          ReadDir(CurPnl);
          NeedUpdt:=true;
          SeekLast := true;
          goto ReInit;
        end;
      end;
    end;
   kbEsc,kbAltX: {ESC}
    begin
      done := true;
    end;
   end;
 until Done;

  for i:=0 to 1 do FreeItems(i);
  ListDirs := 0;
  PutScr(3);
end;

Function Init : boolean;
var i : word;
begin
  Init:=false;
  set_mode($03);
  Set_Blinking(0);
  Set_Cursor(false);
  Randomize;
  Load8x16Font(Pointer(@DDEFont)^);
  writeln;
  cwritest('~'+char(16*01+15)+'~'+'▀▀▀▀▀▀'+'~'+char(16*00+07)+'~ '+STappName+' '+appVer+' build '+appBuild+#13#10,-1,-1);
  cwritest('~'+char(16*00+04)+'~'+'▀▀▀▀▀▀'+'~'+char(16*00+07)+'~ '+CopyRight+#13#10,-1,-1);
  writeln;
  write(stInit_Drives);
  if Init_Drives then writeln('[OK, ',nDrives,' '+stFound+']') else
  begin
    writeln('['+stErroR+']');
    exit;
  end;
  for i:=0 to 1 do
  with Panel[i] do
  begin
    x1 := 01+40*i; y1 := 01; x2 := 40*(i+1); y2 := 24;
    _x := 1; _y := 1;
    SortMode := smExtension;
  end;
  Init := true;
  get_cursor_pos(oldx,oldy);
end;

procedure Done;
begin
  set_cursor_pos(oldx,oldy);
  writeln;
  writeln(stGoodBye);
  writeln(CopyRight+'.');
  writeln;
  Set_Cursor(true);
end;

procedure Run;
var i,d : byte;
    a : tAlias;
    it  : tDirElement;
    tlfn  : string;
begin
  for d:=0 to 1 do with Panel[d] do
  begin
    fd:=nil;
    Visible := true;
    _ds := 0; _dp := 0;
    _x := 1; _y :=1;
    LastClus     := 0;
    SortMode     := smExtension;
    UseLFN       := true;
    SortAsc      := false;
    ShowDot      := false;
    ShowDeleted  := false;
  end;
  if ChoosePanelDrive(0) then
  begin
    new(Panel[1].fd);
    Panel[1].fd^:=Panel[0].fd^;
    Panel[1].Cluster := Panel[0].cluster;
    CurPnl := 0;

{
    make_alias(panel[0].fd^,'На Program Filess.lnk',0,true,true,a);
    for i:=0 to 10 do write(a.nameext[i]);
    writeln;
    if Find_Alias_Item(panel[0].fd^,get_dir_cluster(panel[0].fd^,0,'\'),a,it,tlfn)=NoError then
    begin
      writeln('Found. "'+tlfn+'" ',it.name+'.'+it.ext);
    end else writeln('not found :(');
    writeln;
    halt;
}
    ListDirs;
  end;
  for d:=0 to 1 do if Panel[d].fd<>nil then dispose(Panel[d].fd);
end;

BEGIN
  if Init then Run;
  Done;
END.
... and Justice 4 all. (c) MetallicA