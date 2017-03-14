Program DDE;
(*****************************************************************************
 *                      DOS DiskEditOR v2.01 beta 1                          *
 *****************************************************************************
 *                                                                           *
 * Части кода взяты из:                                                      *
 * ■ DOS Navigator OSP by RIT Research Labs & OSP Team                       *
 * ■ HDDSpeed 2.1 by Michael Radchenko, 2:5025/25                            *
 *                                                                           *
 *                                                         Since: 01/04/Y2k  *
 * (C) NiKe'Soft UnLtd.                              Last UpDate: 01/07/2001 *
 *****************************************************************************)
{$DEFINE DEBUG}
{$DEFINE RussianLang}
{.$DEFINE Beta}
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
{$M 65521,0,655360}

Uses DiskTool,vFAT,Service,TextModeUtil,Keyboard,Hex,HelpZ;

const CopyRight  = '(c) NiKe''Soft UnLtd';
      appName    = 'DOS DiskEditOR (DDE)';
      STappName  = 'DOS DiskEditOR ('+'~'+char(16*cBlack+cLCyan)+'~'+'DDE'+'~'+char(16*cBlack+cGray)+'~'+')';
      appBuild   = '01/07/2001';
{$IFDEF DEBUG}
  {$IFDEF BETA}
      appVer     = 'v2.01d beta 1';
  {$ELSE}
      appVer     = 'v2.01d';
  {$ENDIF}
{$ELSE}
  {$IFDEF BETA}
      appVer     = 'v2.01 beta 1';
  {$ELSE}
      appVer     = 'v2.01';
  {$ENDIF}
{$ENDIF}
const
      Max_Items  = 4096;
      Max_Drives = 4{FDD}+6{HDD}+2{Reserved};

      nRetries = 2;

      vtHex    = 0;
      vtHex64  = 1;

      ViewType    : byte = vtHex64;
      ViewChLimit : byte = 0;
      CharLimits  : array[0..2] of string[6] =
      (('00..FF'),
       ('20..7F'),
       ('20..FF')
       );
      Wrap        : byte = 0;
      TabSize     : byte = 8;

      pt_None    = 0;
      pt_Drives  = 1;
      pt_LDrives = 2;
      pt_Dirs    = 3;

      SavingPath: string = 'c:\rec\';

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

const max_buf = 32767;
type  tBuf = array[0..max_buf] of char;

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
        OldClus      : longint;
        SortMode     : byte;
        SortAsc      : boolean;
        UseLFN       : boolean;
        ShowDeleted  : boolean;
        ShowDot      : boolean; {Show '.' dir el.}
     end;

Var Panel   : array[0..1] of tPanel;
    CurPnl  : byte;
    Drives  : array[1..Max_Drives] of tBios_Drive;
    Pts     : array[1..Max_Partitions] of tPartition;
    oldx,oldy,nDrives : byte;
    buf     : array512;

procedure DDEFont; external; {$L DDEFont.Obj}

function ShowError(err : string) : integer;
var tt : byte;
    x1,y1,ww,hh : byte;
    act : byte;
    key : word;
begin
  ShowError := -1;
  SaveScr(5);
  err := ' Error: '+err+' ';
  tt := length(err) + 1;
  ww := 10;
  if tt > ww then
  begin
    if tt > 78 then tt := 78;
    ww := tt;
  end;
  x1 := (80 - ww) div 2 - 1;
  y1 := 09; hh := 4;
  tt := cLRed;
  Set_Window(x1,y1,x1+ww,y1+hh,Borders[brd_double],pa(15,tt),15,tt,pa(14,tt),' ',err,true);
  writest('ESC/N - Break',x1+2,y1+1);
  writest('Y/R - ReRead',x1+2,y1+2);
  writest('S - Skip [sector]',x1+2,y1+3);
  while keypressed do getkey;
  act := 0;
  while true do
  begin
    key := getkey;
    if key<>kbnokey then
    begin
      if key = kbESC then act := 1 else
       if (upcase(chr(lo(key))) = 'Y')or(upcase(chr(lo(key))) = 'R')or(key = kbEnter) then act := 2 else
        if (upcase(chr(lo(key))) = 'N') then act := 3 else
         if (upcase(chr(lo(key))) = 'S') then act := 4 else

    end;
    if act <> 0 then break;
  end;
  PutScr(5);
  ShowError := act;
end;

function AddSlash(s : string) : string;
begin
  if length(s) >= 1 then if s[length(s)] <> '\' then s := s + '\' else else s := '\';
  AddSlash := s;
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

{$DEFINE UseBuffering}
function ViewFile(Pnl : byte; It : word) : integer;


{$IFDEF UseBuffering}
const MaxClusBuf = 255;
      MaxSectBuf = 10;
var   clusbufpos,sectbufpos : word;
      SectBuf : array[0..MaxSectBuf] of record
        SectN : longint;
        Data  : array[0..511] of char;
      end;
      ClusBuf : array[0..MaxClusBuf] of record
        Clus  : longint;
        ClusN : longint;
      end;
{$ENDIF}

var hh,h,hexpos : word;
    key,mkey  : word;
    hexing,done : boolean;
    clus,clse,DsP,Size : longint;
    bufdsp : longint;
    bf : array[0..6666] of char;
    s : string;
    fnd : boolean;
    LastClust : record
      Clus  : longint;
      ClusN : longint;
    end;

function AllowedChar(ch : char) : boolean;
begin
  case ViewChLimit of
  1:   AllowedChar := (ch >= ' ')and(ch <= '');
  2:   AllowedChar := (ch >= ' ')and(ch <= #$FF);
  else AllowedChar := true;
  end;
end;

procedure AdjustBuffer(ReRead : boolean);
var StClus,tmp,clu,sz,c,sec,cl : longint;
    t,j : word;
    oofs : word;
    bf2 : array[0..511] of char;
begin
  with Panel[Pnl] do
  begin
    if (dsp < 0)or(dsp > size) then exit;
    if not ReRead then if (dsp = bufdsp) then exit;
    sec := dsp div fd^.sector_length;
    oofs := dsp mod fd^.sector_length;
    cl := sec div fd^.cluster_length;
    j := sec mod fd^.cluster_length;
    sz := 0;
    clus := Items[it]^.f.cluster;
    if (cl > 0) then
    begin
      if (LastClust.ClusN > 1)and(LastClust.ClusN < cl)and(not ReRead) then
      begin
        StClus := LastClust.ClusN;
        clus := LastClust.Clus;
      end else StClus := 1;
      for c := StClus to cl do
      begin
{$IFDEF UseBuffering}
        fnd := false;
        if not ReRead then
        begin
          for t := 1 to MaxClusBuf do
          begin
            if ClusBuf[t].ClusN = c then begin fnd := true; break; end;
          end;
        end;
        if fnd then clu := ClusBuf[t].Clus else
{$ENDIF}
        begin
          while (true) do
          begin
            clu := Get_FAT_Item(fd^,clus);
            if (clu < 2)or((clu > fd^.clusters) and (clu < fd^.EOF_Mark)) then
            begin
              case ShowError('Illegal FAT Item! ('+hexl(clu)+')') of
               1,3: {ESC} begin break; end;
               2: {ReRead} begin clu := Get_FAT_Item(Panel[Pnl].fd^,clus); end;
               4: {Skip} begin {size := sz;} break; end;
              end;
            end else break;
          end;
{$IFDEF UseBuffering}
          ClusBuf[ClusBufPos].ClusN := c;
          ClusBuf[ClusBufPos].Clus  := clu;
          if ClusBufPos >= MaxClusBuf then ClusBufPos := 0 else inc(ClusBufPos);
{$ENDIF}
        end;
        if (clu < 2)or(clu >= fd^.BAD_Mark) then
        begin
          break;
        end else
        begin
          clus := clu;
          sz := sz + longint(fd^.cluster_length)*fd^.sector_length;
          if (sz >= size) then break;
        end;
      end;
      if not((clu < 2)or(clu >= fd^.BAD_Mark)) then
       if LastClust.ClusN < c then begin LastClust.ClusN := c; LastClust.Clus := clu end;
    end;

    bufdsp := dsp;
    c := 0;
    sec := get_cluster_sector(fd^,clus);
    if sec < 0 then exit;
    if sz < 0 then sz := 0;
    for c := 0 to 5 do {Читаем сектора файла}
    begin
      if (sz >= size) then break;
      tmp := c*fd^.sector_length - oofs; if tmp < 0 then tmp := 0;
{$IFDEF UseBuffering}
      fnd := false;
      if not ReRead then
      begin
        for t := 1 to MaxSectBuf do
        begin
          if SectBuf[t].SectN = sec+j then begin fnd := true; break; end;
        end;
      end;
      if fnd then
      begin
        move(SectBuf[t].Data[(oofs)*byte(c=0)],bf[tmp],sizeof(SectBuf[t].Data));
      end else
{$ENDIF}
      begin
        Read_Sectors(fd^,sec+j,1,bf2);
        move(bf2[(oofs)*byte(c=0)],bf[tmp],sizeof(bf2));
{$IFDEF UseBuffering}
        move(bf2,SectBuf[SectBufPos].Data,sizeof(SectBuf[SectBufPos].Data));
        SectBuf[SectBufPos].SectN := sec+j;
        if SectBufPos >= MaxSectBuf then SectBufPos := 0 else inc(SectBufPos);
{$ENDIF}
      end;
      sz := sz + fd^.sector_length;
      if sz > size then break;
      inc(j);
      if (j mod fd^.cluster_length = 0) then
      begin
        while (true) do
        begin
          clu := Get_FAT_Item(fd^,clus);
          if (clu < 2)or((clu > fd^.clusters) and (clu < fd^.EOF_Mark)) then
          begin
            case ShowError('Illegal FAT Item! ('+hexl(clu)+')') of
             1,3: {ESC} begin break; end;
             2: {ReRead} begin clu := Get_FAT_Item(Panel[Pnl].fd^,clus); end;
             4: {Skip} begin {size := sz;} break; end;
            end;
          end else break;
        end;
        clus := clu;
        j := 0;
        sec := get_cluster_sector(fd^,clus);
        if sec < 0 then break;
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
       s := rtrim(Items[it]^.f.name);
       if rtrim(Items[it]^.f.ext)<>'' then s:=s+'.'+rtrim(Items[it]^.f.ext);
       fillscr(1,1,80,25,' ');
       Set_Window(1,1,80,24,borders[brd_double],15,07,08,PA(10,08),' ',
       stViewingFile+' "'+s+'" (C:'+hexl(Items[it]^.f.cluster)+'h) ',false);
       if (ViewType = vtHex) then
       begin
         hh := 16;
         writestf('['+hexl(DsP+hexpos div 2)+' '+hexb(DsP mod 16),2,24,15);
         for i := 1 to 15 do writestf('-'+hexb(i + DsP mod 16),14+(i-1)*3,24,15);
         writestf('['+hexl(size){fstr(size,1,',',' ',RightAlign)}{+' '+stBytes}+'] - ['+CharLimits[ViewChLimit]+']',62,24,15);
       end else
       begin
         hh := 64;
         writestf('['+hexl(DsP+hexpos div 2)+' - '+strf(round((1.0*100/size)*(DsP+hexpos div 2)),1)+'% '+
         stFrom+' '+fstr(size,1,',',' ',RightAlign)+' '+stBytes+'] - ['+CharLimits[ViewChLimit]+']',2,24,15);
       end;
       if (Size - DsP) > hh*22 then w := hh*22 else w := Size-DsP;
       ww := w div hh;
       if (w mod hh <> 0) then inc(ww);{}
       for i := 1 to ww do
       begin
         writestf(hexl(DsP+(i-1)*hh),02,01+i,07);
         putchf(10,01+i,':',07);
         for a := 0 to hh-1 do
         begin
           if longint(DsP+(i-1)*hh+a) >= Size then begin dec(a); break; end;
           if ((i-1)*hh+a) < sizeof(bf) then
           begin
             if (ViewType = vtHex) then
             begin
               c := bf[(i-1)*hh+a];
               writestf(hexb(byte(c)),15+(a-1)*3,01+i,07);
               if (a+1) mod 4<>0 then putchf(17+(a-1)*3,01+i,' ',07);
               if AllowedChar(c) then putchf(62+a,01+i,c,07);
             end else
             begin
               c := bf[(i-1)*hh+a];
               if AllowedChar(c) then putchf(12+a,01+i,c,07) else putchf(12+a,01+i,' ',07);
             end;
           end;
         end;
         for a := a+1 to hh-1 do
         begin
           if (ViewType = vtHex) then
           begin
             writestf('  ',15+(a-1)*3,01+i,07);
             putchf(62+a,01+i,' ',07);
           end else putchf(12+a,01+i,' ',07);
         end;
         if (ViewType = vtHex64) then fil(76,01+i,79,' ');
         if (ViewType = vtHex) then
         begin
           putchf(23,01+i,'│',15);
           putchf(35,01+i,'│',15);
           putchf(47,01+i,'│',15);
           putchf(60,01+i,'║'{│},15);
         end;
       end;
       for i := ww+1 to 22 do fil(2,01+i,78,' ');
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
  if longint(size - dsp) > hh*22 then h := hh*22*2 else h := (size - dsp)*2;
  if (hexpos >= h) then hexpos := h-1;

  if (not hexing)or(ViewType = vtHex64) then
  begin
    x := (hexpos div 2) mod (hh) + 12;
    if (ViewType = vtHex) then inc(x,50);
  end else
  begin
    h := (hexpos mod (hh*2));
    x := h + h div 2 + 12;
  end;
  Set_Cursor_Pos(x,hexpos div (hh*2) + 2)
end;

begin
  ViewFile := 1;
  with LastClust do begin ClusN := 0; Clus := 0; end;
  SaveScr(4);
{$IFDEF UseBuffering}
  FillChar(ClusBuf,sizeof(clusbuf),#0); clusbufpos := 0;
  fillchar(SectBuf,sizeof(sectbuf),#0); sectbufpos := 0;
{$ENDIF}
  with Panel[Pnl] do if (nItems > 0)and(it < nItems) then if (Items[it] <> nil) then
  begin
    dsp := 0; bufdsp := 0;
    hexpos := 0; hexing := true; {пеpемещение по HEX-числам а не по ASCII}
    case ViewType of
     vtHex: hh := 16;
     vtHex64: hh := 64;
    end;
    Size := Items[it]^.f.Size;
    fillchar(bf,sizeof(bf),#0);
    done := false; mkey := kbnokey;
    AdjustBuffer(true);
    AdjustCursor;
    DrawScr(DsP);
    set_cursor(true);
    while (not done) do
    begin
      if (mkey <> kbnokey) then begin key := mkey; mkey := kbnokey; end else key := getkey;
      if (key <> kbNoKey) then
      begin
        if dsp > size then dsp := size-1;
        if dsp < 0 then dsp := 0;
        case key of
        kbDown: {Down}
        begin
          if longint(size - dsp) > hh*22 then h := hh*22*2 else h := (size - dsp)*2;
          if (hexpos+hh*2 < h) then
          begin
            inc(hexpos,hh*2);
          end else
          if (longint(Size - DsP) > hh*22) then inc(DsP,hh);
        end;
        kbUp: {Up}
        begin
          if (hexpos >= hh*2) then
          begin
            dec(hexpos,hh*2);
          end else
          if (DsP-hh >= 0) then
          begin
            dec(DsP,hh);
          end else DsP := 0;
        end;
        kbRight: {Right}
        begin
          if longint(size - dsp) > hh*22 then h := hh*22*2 else h := (size-dsp)*2;
          if (not hexing)or(ViewType = vtHex64) then
          begin
            if (hexpos+2 < h) then inc(hexpos,2) else begin hexpos := h-1; if (DsP+h div 2< Size) then mkey := kbCtrlRight end;
          end else
           if (Hexpos+1 < h) then inc(hexpos) else begin Hexpos := h-1; if (DsP+h div 2 < Size) then mkey := kbCtrlRight end;
        end;
        kbLeft: {Left}
        begin
          if (not hexing)or(ViewType = vtHex64) then
          begin
            if (Hexpos > 1) then dec(hexpos,2)
             else if (DsP > 0) then begin mkey := kbCtrlLeft; hexpos := 0; end else Hexpos := hh*2-1;
          end else
          begin
            if (Hexpos > 0) then dec(hexpos)
             else if (DsP > 0) then begin mkey := kbCtrlLeft; hexpos := 0; end else Hexpos := hh*2-1;
          end;
          if longint(size - dsp) > hh*22 then h := hh*22*2 else h := (size - dsp)*2;
          if (hexpos >= h) then hexpos := h-1;
        end;
        kbTab: {Tab}
        begin
          if ViewType = vtHex then hexing := not hexing{ else hexing:=true};
        end;
        kbF4: {F4}
        begin
          if ViewType = vtHex then
          begin
            ViewType := vtHex64;
            hh := 64;
          end else
          begin
            ViewType := vtHex;
            hh := 16;
          end;
          if longint(size-dsp) > hh*22 then h := hh*22*2 else h := (size-dsp)*2;
          if (hexpos >= h) then hexpos := h-1;
        end;
        kbF6: {F6}
        begin
          if ViewChLimit >= 2 then ViewChLimit := 0 else inc(ViewChLimit);
        end;
        kbHome: {Home}
        begin
          hexpos := (hexpos div (hh*2))*hh*2
        end;
        kbEnd: {End}
        begin
          if longint(size-dsp) > hh*22 then h := hh*22*2 else h := (size-dsp)*2;
          hexpos := (hexpos div (hh*2)+1)*hh*2-1;
          if hexpos > h then hexpos := h-1;
        end;
        kbCtrlHome: {CtrlHome}
        begin
          hexpos := hexpos mod (hh*2);
        end;
        kbCtrlEnd: {CtrlEnd}
        begin
          if longint(size-dsp) > hh*22 then h := hh*22*2 else h := (size-dsp)*2;
          hexpos := hexpos+(h div (hh*2) - hexpos div (hh*2)-1*byte((h div 2) mod hh=0))*hh*2;
          if (hexpos >= h) then
          begin
            dec(hexpos,hh*2);
            if (hexpos >= h) then hexpos := h-1;
          end;
        end;
        kbCtrlPgUp: {CtrlPageUp}
        begin
          dsp := 0; hexpos := 0;
        end;
        kbCtrlPgDn: {CtrlPageDown}
        begin
          if (size >= hh*22) then DsP := ((Size - hh*22) div hh+1)*hh else dsp := 0;
          if longint(size-dsp) > hh*22 then hexpos := hh*22*2 else hexpos := (size-dsp)*2;
          dec(hexpos);
        end;
        kbPgDn: {PageDown}
        begin
          if longint(Size-hh*22) > 0 then
          if (DsP+hh*21 <= Size-hh*22) then inc(DsP,hh*21) else
            DsP := ((Size-hh*22) div hh+1)*hh;
        end;
        kbPgUp: {PageUp}
        begin
          if longint(Size-hh*22) > 0 then
          if (DsP-hh*21 >= 0) then dec(DsP,hh*21) else
           DsP := 0;
        end;
        kbCtrlLeft: {CtrlLeft}
        begin
          if (DsP > 0) then dec(DsP);
        end;
        kbCtrlRight: {CtrlRight}
        begin
          if (DsP < Size-1) then inc(DsP);
          if longint(size-dsp) > hh*22 then h := hh*22*2 else h := (size-dsp)*2;
          if (hexpos > h) then hexpos := h-1;
        end;
        kbCtrlR:
        begin
          AdjustBuffer(true);
        end;
        kbESC: {ESCAPE} done := true;
        end;
        if dsp <> bufDSP then AdjustBuffer(false);
        AdjustCursor;
        DrawScr(DsP);
      end; {if key<>kbNoKey then}
    end;
    ViewFile := 0;
    set_cursor(false);
  end;
  PutScr(4);
end;

function Init_Drives : boolean;
var i : byte;

procedure chk(d : byte);
begin
  if GetDriveInfo(d,Drives[nDrives+1]) = 0 then
  begin
    inc(nDrives);
  end;
end;

begin
  nDrives := 0; fillchar(Drives,SizeOf(Drives),#0);
  for i := $00 to $03 do if nDrives >= Max_Drives then break else
  begin
    chk(i);
  end;
  for i := $80 to $85 do if nDrives >= Max_Drives then break else
  begin
    chk(i);
  end;
  for i := $02 to $80-1 do if nDrives >= Max_Drives then break else
  begin
    chk(i);
  end;
  for i := $85 to $FF-1 do if nDrives >= Max_Drives then break else
  begin
    chk(i);
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
    if Selected then c := 03 else c:=01;
    VidB(x,y,x+DriveDlgW,c);
    if Selected then c := 00 else c:=15;
    writestf(strf(i,2),x+1,y,c);
    if Selected then c := 00 else c:=10;
    writestf(GetDrvSt(Drives[i].Drive),x+6,y,c);
    if Selected then c:=00 else c:=07;
    with Drives[i] do
    begin
      writestf(strf(MaxTrack+1,6),x+14,y,c);
      writestf(strf(MaxHead+1,6),x+23,y,c);
      writestf(strf(MaxSector,5),x+32,y,c);
      sz := (1.0*(SEHD)*(MaxTrack+1)*SecSiz/1024);
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
    writestf(fstr(fd^.clusters,1,',',' ',RightAlign),21+length(stFrom)+1,21,11);
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

      writestf(fstr(cl,8,',',' ',RightAlign),12,21,11);
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
      i := get_fat_item(fd^,cL);
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
      cl,clu : longint;
      tlfn   : string;
      dt     : datetime;
      id,crc : byte;
      fl     : boolean;
  begin
    ReadDir := 0;
    FreeItems(Pnl);
    with Panel[Pnl] do
    begin
{      OldClus := -1;{}
      lfnofs  := 0; maxlfnofs := 0;
      tlfn:=''; id:=0; crc:=0;
      k  := 0;                       {Количество просмотренных элементов}
      j  := 0;                       {Текущий элемент каталога}
      cl := Cluster;
      if cl < 0 then exit;
      if cl < 2 then cl := fd^.root_cluster;
      DirS := Get_Cluster_Sector(fd^,cl);
      fillchar(Dir,sizeof(dir),#0);
      while Read_Sectors(fd^,DirS,1,Dir) <> 0 do
      begin
        case ShowError('Error Reading DIR sector! ('+fStr(dirs,1,',',' ',RightAlign)+')') of
         1,3: {ESC} begin {StopSaving := true; }exit; break; end;
         2: {ReRead} begin Read_Sectors(fd^,DirS,1,Dir); end;
         4: {Skip} break;
         end;
      end;  {Читаем первый сектор}
      repeat
        if Dir[j].Name[0] = #0 then break; {Обнаружен конец списка}
        fl := false;
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
          if (fl) then if Dir[j].name[0]=' ' then fl := false;
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
            while (true) do
            begin
              clu := Get_FAT_Item(fd^,cl);
              if (clu < 2)or((clu > fd^.clusters) and (clu < fd^.EOF_Mark)) then
              begin
                case ShowError('Illegal FAT Item! ('+hexl(clu)+')') of
                 1,3: {ESC} begin {StopSaving := true; }break; end;
                 2: {ReRead} begin Get_FAT_Item(Panel[Pnl].fd^,cl); end;
                 4: {Skip}  break;
                end;
              end else break;
            end;
            cl := clu;
            if (cl >= fd^.bad_mark)or(cl < 2) then break;
            {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
            DirS := Get_Cluster_Sector(fd^,cl); {Получаем нoвый сектор}
            if DirS < 0 then break;
          end;
          while Read_Sectors(fd^,DirS,1,Dir) <> 0 do
          begin
            case ShowError('Error Reading DIR sector! ('+fStr(dirs,1,',',' ',RightAlign)+')') of
             1,3: {ESC} begin {StopSaving := true; }exit; break; end;
             2: {ReRead} begin Read_Sectors(fd^,DirS,1,Dir); end;
             4: {Skip} break;
            end;
          end;  {Читаем первый сектор}
        end else inc(j);
        if nItems >= max_items then break;
      until false;
    end;
    QSort(Pnl);
  end;

var exsrsz : boolean;
    downlevel : longint;
const MaxDownLevel = 1000;

  function GetDirSize(Pnl : byte; DirC : longint) : longint;
  var k,j,i  : longint;
      Dir    : array[0..15] of tDirElement;
      DirS   : longint;
      cl,clu,sz,cls : longint;
  begin
    GetDirSize := 0;
    if downlevel >= MaxDownLevel then exit else inc(downlevel);
    sz := 0;
    if exsrsz then exit;
    with Panel[Pnl] do
    begin
      k  := 0;                       {Количество просмотренных элементов}
      j  := 0;                       {Текущий элемент каталога}
      cl := DirC;
      if cl < 0 then exit;
      if cl<2 then cl:=fd^.root_cluster;
      DirS := Get_Cluster_Sector(fd^,cl);
      if DirS < 0 then exit;
      fillchar(Dir,sizeof(dir),#0);
      while Read_Sectors(fd^,DirS,1,Dir) <> 0 do
      begin
        case ShowError('Error Reading DIR sector! ('+fStr(dirs,1,',',' ',RightAlign)+')') of
         1,3: {ESC} begin {StopSaving := true; }exit; break; end;
         2: {ReRead} begin Read_Sectors(fd^,DirS,1,Dir); end;
         4: {Skip} break;
         end;
      end;  {Читаем первый сектор}
      repeat
        if Dir[j].Name[0] = #0 then break; {Обнаружен конец списка}
        if keypressed then if getkey = kbESC then begin exsrsz := true; GetDirSize := 0; exit; end;
        begin
          if (Dir[j].Attr and faVolumeID=0)
           then if (Valid_Alias(dir[j].nameext))
            then if (Dir[j].Name[0]<>#$E5)
             then if (dir[j].name[0]<>'.') then
          begin
            if (dir[j].attr and faDirectory<>0) then
            begin
              cls := (dir[j].cluster) + (longint(dir[j].Clus_hi) shl 16);
              if not ((cls<2)or((cls > fd^.clusters) and (cls < fd^.EOF_Mark))) then
              begin
                sz := sz + GetDirSize(Pnl,cls);
              end;
              if exsrsz then exit;
            end else sz := sz + dir[j].size;
          end;
        end;
        if j >= 15 then
        begin         {Исчерпан сектор каталога}
          j := 0;     {Продолжаем с 1-го элемента следующего сектора}
          inc(k,16);  {k - сколько элементов просмотрели}
          inc(dirs);
          if (cl < 2) then
          begin
            if (fd^.root_size > 0) then if (k >= fd^.root_size) then break;
          end else
          if (k div 16) mod fd^.Cluster_length = 0 then
          begin     {Исчерпан кластер - ищем следующий}
            {Получаем новый кластер}
            while (true) do
            begin
              clu := Get_FAT_Item(fd^,cl);
              if (clu<2)or((clu > fd^.clusters) and (clu < fd^.EOF_Mark)) then
              begin
                case ShowError('Illegal FAT Item! ('+hexl(clu)+')') of
                 1,3: {ESC} begin {StopSaving := true; }break; end;
                 2: {ReRead} begin Get_FAT_Item(Panel[Pnl].fd^,cl); end;
                 4: {Skip}  break;
                end;
              end else break;
            end;
            cl := clu;
            if (cl >= fd^.bad_mark)or(cl < 2) then break;
            {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
            DirS := Get_Cluster_Sector(fd^,cl); {Получаем нoвый сектор}
          end;
          while Read_Sectors(fd^,DirS,1,Dir) <> 0 do
          begin
            case ShowError('Error Reading DIR sector! ('+fStr(dirs,1,',',' ',RightAlign)+')') of
             1,3: {ESC} begin {StopSaving := true; }exit; break; end;
             2: {ReRead} begin Read_Sectors(fd^,DirS,1,Dir); end;
             4: {Skip} break;
             end;
          end;  {Читаем первый сектор}
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
      s := ' '+appName+' ';
      writesta(s,01+((80-01) - length(s)) div 2,1,pa(cLime,cDGray));
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
               '(C:'+colst(16*cDGray+cLCyan)+strf(fd^.Drive.maxtrack+1,1)+colst(16*cDGray+cGray)+
               ',H:'+colst(16*cDGray+cLCyan)+strf(fd^.Drive.maxhead +1,1)+colst(16*cDGray+cGray)+
               ',S:'+colst(16*cDGray+cLCyan)+strf(fd^.Drive.maxsector ,1)+colst(16*cDGray+cGray)+')',x1+2,yy);
      inc(yy);
      cwritest(stPartFrom+colst(16*cDGray+cLCyan)+fstr(fd^.start_sector,1,',',' ',RightAlign)+colst(16*cDGray+cGray)+stSectora,
       x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+fstr(fd^.sectors,1,',',' ',RightAlign)+colst(16*cDGray+cGray)+stPartLength,x1+2,yy);
      inc(yy,2);
      cwritest(stFileSys+colst(16*cDGray+cLCyan)+'FAT'+strf(fd^.fat_bits,1)+colst(16*cDGray+cGray)+
               ' ('+colst(16*cDGray+cLCyan)+strf(fd^.fats,1)+colst(16*cDGray+cGray)+' '+stCopies+')',x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+fstr(fd^.fat_length,1,',',' ',RightAlign)+colst(16*cDGray+cGray)+stFatLength,x1+2,yy);
      inc(yy);
      if (fd^.root_size<=0) then s:='VAR' else s := strf(fd^.root_size,1);
      cwritest(colst(16*cDGray+cLCyan)+s+colst(16*cDGray+cGray)+stRootElements,x1+2,yy);
      inc(yy);
      cwritest(stRootCluster+colst(16*cDGray+cLCyan)+strf(fd^.root_cluster,1)+colst(16*cDGray+cGray)+
               ' ('+colst(16*cDGray+cLCyan)+fstr(fd^.root_start,1,',',' ',RightAlign)+colst(16*cDGray+cGray)+stOtnSec+')',
       x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+fstr(fd^.clusters,1,',',' ',RightAlign)+colst(16*cDGray+cGray)+stClusters,x1+2,yy);
      inc(yy);
      cwritest(colst(16*cDGray+cLCyan)+strf(fd^.cluster_length,1)+colst(16*cDGray+cGray)+stClusterLength,x1+2,yy);
      inc(yy);
      if (fd^.free_clusters<0) then S:='0' else s := fstr(fd^.free_clusters,1,',',' ',RightAlign);
      cwritest(colst(16*cDGray+cLCyan)+s+colst(16*cDGray+cGray)+stFreeClusters,x1+2,yy);

      while keypressed do readkey;
      if readkey=#0 then readkey;
    end;
    putscr(4);
  end;

var nr,i,j,k : word;
    ods,odp,ds,dp : word;
    shs,ox,oy,x,y   : byte;
    ch : char;
    key,mkey : word;
    needupdt,ex,Done : boolean;
    SeekLast,found : boolean;
    NeedSort       : boolean;
    siz,clus,sec,l : longint;
    fs : longint;
    ts,tn : string;
    rbuf : array512;
    pr : real;
    SkipDir,StopSaving,flg,saved,islfn : boolean;

function SaveFile(Pnl : byte; Path,Name : string; Attr : byte; Size,Cluster : longint) : integer;
var tt : word;
    x1,y1,hh,ww : byte;
    ts,tts,tn : string;
    cl,sec,clus : longint;
    pr : real;
    ff : file;
    lf : lfile;

Label ReRead;

begin
  SaveFile := -1;
  if StopSaving then exit;
  if (Attr and faDirectory = 0) and (Size >= 0) then
  begin
{SaveFile2DSK}
{$I-}
    SaveScr(4);
    siz := Size;
    Path := AddSlash(Path);
    if LFNPresent then
    begin
      lAssignFile(lf,SavingPath + Path+Name); lRewriteFile(lf,1);
    end else
    begin
      Assign(ff,SavingPath + Path+Name); ReWrite(ff,1);
    end;
    if (IOResult = 0)and(Size > 0) then
    begin
      ts := ' Writing "'+Path+Name+'" ';
      tt := length(ts) + 1;
      ww := 45;
      if tt > ww then
      begin
        if tt > 74 then tt := 74;
        ww := tt;
      end;
      x1 := (80 - ww) div 2 - 1;
      y1 := 8; hh := 7;
      tt := cBlue;
      Set_Window(x1,y1,x1+ww,y1+hh,Borders[brd_double],pa(15,tt),07,tt,pa(14,tt),' ',ts,true);
      WriteStF('Size    :',x1+2,y1+2,07);
      WriteStF('Cluster :',x1+2,y1+3,07);
      WriteStF('Sector  :',x1+2,y1+4,07);
      clus := Cluster;
      sec := Get_Cluster_Sector(Panel[Pnl].fd^,clus);
      j := 0; {read sectors}
      repeat
        if keypressed then
        begin
          case GetKey of
          kbAltS: break;
          kbCtrlS: begin SkipDir := true; break; end;
          kbESC: {ESC} StopSaving := true;
          end;
        end;
        if StopSaving then break;
        if keypressed then if getkey = kbESC then break;
        tts := fStr(Size - siz,1,',',' ',LeftAlign);
        pr := ((Size - Siz) / Size);
        str(round(pr*100),ts);
        tts := tts + ' (' + ts + '%)';
        tts := tts + ' '+fStr(Size,1,',',' ',LeftAlign);;
        while length(tts) < ww - 15 do tts := tts+' ';
        writestf(tts,x1+12,y1+2,14);

        tts := hexL(Clus);
        while length(tts) < ww - 15 do tts := tts+' ';
        writestf(tts,x1+12,y1+3,14);
        tts := fStr(Sec,1,',',' ',LeftAlign);
        str(j,ts);
        tts := tts + ' ('+ts+')';
        while length(tts) < ww - 15 do tts := tts+' ';
        writestf(tts,x1+12,y1+4,14);
        if pr = 0 then k := 0 else k := round(pr*(ww - 3));
        ts := ''; for tt := 1 to k do ts := ts + '█';
        writestf(ts,x1+2,y1+5,14);
        writestf(ts,x1+2,y1+6,14);
ReRead:
        flg := Read_Sectors(Panel[Pnl].fd^,sec,1,rbuf) = 0;
        if not flg then
        begin
          case ShowError('Disk READ Error!') of
          1,3: {ESC} begin StopSaving := true; break; end;
          2: if Read_Sectors(Panel[Pnl].fd^,sec,1,rbuf) = 0 then goto ReRead else {break};
          4: {Skip} begin FillChar(rbuf,sizeof(rbuf),#0); flg := true; end;
          end;
        end;
        if flg then
        begin
          if siz < 512 then nr := siz else nr := 512;
          if LFNPresent then blockwrite(lf.f,rbuf,nr) else blockwrite(ff,rbuf,nr);
          dec(siz,nr);
          if siz > 0 then
          begin
            inc(j);
            if j < Panel[Pnl].fd^.Cluster_Length then inc(sec) else
            begin
              j := 0;
              while true do
              begin
                cl := Get_FAT_Item(Panel[Pnl].fd^,clus);
                if (cl < 2)or(cl >= Panel[Pnl].fd^.BAD_Mark) then
                begin
                  case ShowError('Illegal FAT Item found ['+hexl(clus)+']') of
                   1,3: {ESC} begin StopSaving := true; break; end;
                   2: begin cl := Get_FAT_Item(Panel[Pnl].fd^,clus); end;
                   4: {Skip} begin clus := clus; break; end;
                   end;
                end else break;
              end;
              clus := cl;
              if StopSaving then break;
              sec := Get_Cluster_Sector(Panel[Pnl].fd^,clus);
              if sec < 0 then
              begin
                break;
              end;
            end;
          end;
        end;
      until siz <= 0;
      pr := 1; k := round(pr*(60 - 20 - 3));
      ts := ''; for tt := 1 to k do ts := ts + '█';
      writestf(ts,22,13,14);
      writestf(ts,22,14,14);
    end;
    if LFNPresent then close(lf.f) else close(ff);
    PutScr(4);
{$I+}
  end;
  SaveFile := 0;
end;

function SaveDir(Pnl : byte; DirC : longint; Attr : byte; addPath,dirname : string) : integer;
var k,j,i   : longint;
    Dir     : array[0..15] of tDirElement;
    DirS    : longint;
    cls,cl,clus : longint;
    tlfn,dn : string;
    dt      : datetime;
    id,crc  : byte;
    fl      : boolean;

begin
  SaveDir := -1;
{$I-}
  if (StopSaving){or(Attr and faDirectory = 0)} then exit;
  SkipDir := false;
  with Panel[Pnl] do
  begin
    if addPath <> '' then addPath := AddSlash(addPath);
    addPath := addPath + DirName;
    if LFNPresent then
    begin
      lMkDir(SavingPath + addPath)
    end else
    begin
      MkDir(SavingPath + addPath);
    end;
    tlfn := ''; id := 0; crc := 0;
    k  := 0;                       {Количество просмотренных элементов}
    j  := 0;                       {Текущий элемент каталога}
    cl := DirC;
    if cl < 2 then cl := fd^.root_cluster;
    DirS := Get_Cluster_Sector(fd^,cl);
    FillChar(Dir,sizeof(dir),#0);
    while (Read_Sectors(fd^,DirS,1,Dir) <> 0) do  {Читаем первый сектор}
    begin
      case ShowError('Error Reading DIR (first sector)') of
       1,3: {ESC} begin StopSaving := true; break; end;
       2: if Read_Sectors(fd^,DirS,1,Dir) <> 0 then begin SaveDir := 1; exit; end;
       4: {Skip} begin FillChar(Dir,sizeof(Dir),#0); break; end;
       end;
    end;

    if not StopSaving then
    repeat
      if keypressed then
      begin
        case GetKey of
        kbCtrlS: begin break; end;
        kbESC: {ESC} StopSaving := true;
        end;
      end;
      if StopSaving then break;
      if Dir[j].Name[0]=#0 then break; {Обнаружен конец списка}
      if Dir[j].Name[0]<>'.' then
      begin
        fl := false;
        if (Dir[j].Attr = faExt)and(LFNPresent)
         then if (Dir[j].Name[0]<>#$E5) then fl := true else
         begin
           fl := true;
         end;
        if (fl) then
        begin
          if ID > 0 then
          begin
            dec(id);
            if (tLFNelement(Dir[j]).id=id)and(tLFNelement(Dir[j]).crc=crc) then
            begin
              AddLfn(tlfn,tLFNElement(Dir[j]));
            end;
          end else
          begin
            id := tLFNelement(Dir[j]).id;
            if id > $40 then dec(id,$40);
            crc := tLFNelement(Dir[j]).crc;
            tlfn := '';
            AddLfn(tlfn,tLFNElement(Dir[j]));
          end;
        end else
        begin
          fl := false;
          if (Dir[j].Attr and faVolumeID=0)
           then if (Valid_Alias(dir[j].nameext))
            then if (Dir[j].Name[0]<>#$E5) then fl:=true else
             {if (ShowDeleted) then };
          if (fl) then if dir[j].name[0] = '.' then fl := false;
          if (fl) then
          begin
{          if UseLFN then}
            if (id = 1)and(tlfn<>'') then
            begin
              if lcrc(dir[j].NameExt) = crc then
              begin
                tlfn := RTrim(tlfn);
              end else tlfn := '';
            end;
            dn := rTrim(Dir[j].ext);
            if dn<>'' then dn := '.'+dn;
            dn := rTrim(Dir[j].name) + dn;
            if (tlfn = '')or(not LFNPresent) then tlfn := dn;
            UnPackTime(dir[j].date,dt);
            clus := ((dir[j].cluster) + (longint(dir[j].Clus_hi) shl 16));
            if (dir[j].Attr and faDirectory = 0) then
            begin
              SaveDir := SaveFile(Pnl,addPath,tlfn,Dir[j].Attr,Dir[j].Size,Clus);
              if SkipDir then begin SkipDir := false; exit; end;
            end else
            begin
              SaveDir := SaveDir(Pnl,Clus,Dir[j].Attr,addPath,tlfn);
            end;
          end;
          tlfn := ''; id := 0; crc := 0;
        end;
      end;
      if j >= 15 then
      begin         {Исчерпан сектор каталога}
        j := 0;     {Продолжаем с 1-го элемента следующего сектора}
        inc(k,16);  {k - сколько элементов просмотрели}
        inc(dirs);
        if (cl<2) then
        begin
          if (fd^.root_size > 0) then if (k >= fd^.root_size) then break;
        end else
        if (k div 16) mod fd^.Cluster_length = 0 then
        begin     {Исчерпан кластер - ищем следующий}
          {Получаем новый кластер}
          while (true) do
          begin
            cls := Get_FAT_Item(fd^,cl);
            if (cls < 2)or((cls > fd^.clusters) and (cls < fd^.EOF_Mark)) then
            begin
              case ShowError('Illegal FAT Item found ['+hexl(cls)+']') of
               1,3: {ESC} begin StopSaving := true; break; end;
               2: begin
                    Get_FAT_Item(fd^,cl);
                    { if not (cl >= fd^.bad_mark)or(cl < 2) then begin SaveDir := 1; exit; }
                  end;
               4: {Skip} begin FillChar(Dir,sizeof(Dir),#0); break; end;
               end
            end else break;
          end;
          cl := cls;
          if StopSaving then break;
          {Можно не проверять на конец цепочки, т.к. каталог еще не исчерпан}
          DirS := Get_Cluster_Sector(fd^,cl); {Получаем нoвый сектор}
        end;
        while (Read_Sectors(fd^,DirS,1,Dir) <> 0) do  {Читаем очередной сектор}
        begin
          case ShowError('Error Reading DIR sector') of
           1,3: {ESC} begin StopSaving := true; break; end;
           2: if Read_Sectors(fd^,DirS,1,Dir) <> 0 then {begin SaveDir := 1; exit; end};
           4: {Skip} begin FillChar(Dir,sizeof(Dir),#0); break; end;
           end;
        end;
      end else inc(j);
    until false;
  end;
  SaveDir := 0;
end;

function SaveItem(pnl : byte; Item : word) : integer;
var stname : string;
    lf : boolean;
begin
  SaveItem := -1;
  if StopSaving then exit;
  with Panel[Pnl] do
  begin
    lf := false;
    if (LFNPresent) then if (Items[Item]^.f.lfname <> nil) then if Items[Item]^.f.lfname^ <> '' then lf := true;
    if lf then stname := Items[Item]^.f.lfname^ else
    begin
      stName := RTrim(Items[Item]^.F.Ext);
      if stName <> '' then stName := RTrim(Items[Item]^.F.Name) + '.' + stName;
    end;

    if Items[Item]^.f.Attr and faDirectory = 0 then
    begin
      SaveItem := SaveFile(Pnl,'',stName,Items[Item]^.f.Attr,Items[Item]^.f.Size,Items[Item]^.f.Cluster);
    end else
    begin
      SaveItem := SaveDir(Pnl,Items[Item]^.f.Cluster,Items[Item]^.f.Attr,'',stName);
    end;
  end;
end;

label ReInit,ReRead;
begin
  SaveScr(3);
  CurPnl := 0;
  for i := 0 to 1 do
  with Panel[i] do
  begin
    Set_Window(x1,y1,x2,y2,borders[brd_double],15,07,08,10,' ','',false);
    CharVLine(x1+13,y1+1,y2-4,PA(15,08),'│');
    CharVLine(x1+26,y1+1,y2-4,PA(15,08),'│');
    CharHLine(x1+1,y2-3,x2-1,PA(15,08),'─');
  end;
  ReadDir(CurPnl);
  ReadDir(1 - CurPnl);
  ShowDir(1 - CurPnl,0);
  with Panel[1-CurPnl] do
  begin
    DrawItem_Brief(1-CurPnl,_dp,_x,_y,true);
    DrawItem_Brief(1-CurPnl,_dp,_x,_y,false);
  end;
  needupdt := true;
  done := false;
  SeekLast := false;
  Panel[1-CurPnl].OldClus := -1;
  Panel[CurPnl].OldClus := -1;
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
      for i := 0 to Panel[CurPnl].nItems-1 do {if (items[i]^.f.Attr and faDirectory<>0) then}
      begin
        found := false;
        if (lastclus = 0)or(lastclus = fd^.root_cluster) then
        begin
          if RTrim(items[i]^.f.nameext) = '..' then found := true
        end else
          if (items[i]^.f.cluster = Panel[CurPnl].lastclus) then found := true;
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
  odp := dp; ods := ds; ox := x; oy := y;
  repeat
{$IFDEF DEBUG}
    writestf('['+hexl(memavail)+']',70,01,cLGreen);
{$ENDIF}
    if (ods <> ds)or(odp <> dp)or(NeedUpdt) then
    begin
      DrawItem_Brief(CurPnl,odp,ox,oy,false);
      if (ods <> ds)or(NeedUpdt) then
      begin
        ShowDir(CurPnl,ds);
        ods := ds;
      end;
      DrawItem_Brief(CurPnl,dp,x,y,true);
      odp := dp; ox := x; oy := y;
      needupdt := false;
   end;
   i := shiftstate;
   if (i <> shs) then
   begin
     fil(1,25,80,' ');
     vidb(1,25,80,07);
     if (shiftstate and shsAlt <> 0)and(shiftstate and shsCtrl = 0)
       then cwritest(st_ALT_st,1,text_maxy) else
     if (shiftstate and shsCtrl <> 0)and(shiftstate and shsAlt = 0)
       then cwritest(st_Ctrl_st,1,text_maxy) else
     if ((shiftstate and shsRShift<>0)or(shiftstate and shsLShift<>0))and(shiftstate and shsCtrl=0)and(shiftstate and shsAlt=0)
       then cwritest(st_Shift_st,1,text_maxy) else
     if (shiftstate and shsCtrl=0)and(shiftstate and shsAlt=0)and(shiftstate and shsRShift=0)and(shiftstate and shsLShift=0)
       then cwritest(st_Normal_st,1,text_maxy);
     shs:=i;
   end;
   if mkey <> kbNokey then begin key := mkey; mkey := kbNokey end else key := getkey;
   if key <> kbNoKey then
   case key of
   kbF2:
    if (Panel[CurPnl].nItems > 0) then with Panel[CurPnl] do
    begin
      isLFN := LFNPresent;
{      isLFN := false;{}
      StopSaving := false;
      SavingPath := AddSlash(SavingPath);
      saved := false;
      for i := 0 to nItems-1 do if Items[i]^.f.sel then
      begin
        if StopSaving then break;
        if SaveItem(CurPnl,i) <> 0 then begin saved := true; break; end else
        begin
          Items[i]^.f.sel := false;
          ShowDir(CurPnl,ds);
          Saved := true;
        end;
      end;
      if not StopSaving then if not saved then
      begin
        SaveItem(CurPnl,dp);
      end;
      ShowDir(CurPnl,ds);
      DrawItem_Brief(CurPnl,dp,x,y,true);
    end;
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
    if (Panel[CurPnl].nItems > 0) then
    begin
      if (dp > 0) then
      begin
        dec(dp); dec(y);
        if (y < 1) then
        begin
          if (x > 1) then begin y := 19; dec(x,13); end
            else begin ds := dp; y := 1; end;
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
          x := 1; y := 1;
        end;
      end else begin mkey := kbHome; end;
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
        y  := 19; x := 27;
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
        NeedUpdt := true;
      end else mkey := kbEnd;
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
     if (Panel[CurPnl].Items[dp]^.F.Cluster >= 2)and(Panel[CurPnl].Items[dp]^.F.Cluster <= Panel[CurPnl].fd^.clusters) then
       ViewFile(CurPnl,dp);
   end else
   begin
     exsrsz := false; {stop scannin' size}
     flg := false;
     for i := 0 to nItems-1 do
      if (Items[i]^.f.sel)and(Items[i]^.f.name[0]<>'.') then
      begin
        if (Items[i]^.f.attr and faDirectory <> 0)
        and(Panel[CurPnl].Items[i]^.F.Cluster >= 0)and(Panel[CurPnl].Items[i]^.F.Cluster <= Panel[CurPnl].fd^.clusters)then
        begin
          downlevel := 0;
          Items[i]^.f.size := GetDirSize(CurPnl,Items[i]^.f.cluster);
        end;
        Items[i]^.f.ShowSize := true;
        flg := true;
      end;
     if (not flg) then
     begin
       downlevel := 0;
       if (Panel[CurPnl].Items[dp]^.F.Cluster >= 0)and(Panel[CurPnl].Items[dp]^.F.Cluster <= Panel[CurPnl].fd^.clusters) then
       begin
         if (Items[dp]^.f.name[0] <> '.') then
           Items[dp]^.f.size := GetDirSize(CurPnl,Items[dp]^.f.cluster)
          else Items[dp]^.f.size := GetDirSize(CurPnl,Cluster);
         Items[dp]^.f.ShowSize := true;
       end;
     end;
     DrawItem_Brief(CurPnl,dp,x,y,true);
     _dp := dp;
     _ds := ds;
     _x := x; _y := y;
     NeedSort := true;
     NeedUpdt := true;
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
        if CurPnl = 0 then begin NeedUpdt:=true; goto ReInit end else
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
      DrawItem_Brief(CurPnl,dp,x,y,false);
      if ChoosePanelDrive(1) then
      with Panel[1] do
      begin
        _x  := 1;
        _y  := 1;
        _ds := 0;
        _dp := 0;
        LastClus := 0;
        SeekLast := false;
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
        ReadDir(1);
        if CurPnl = 1 then begin NeedUpdt := true; goto ReInit end else
        begin
          ShowDir(1,_ds);
          DrawItem_Brief(1,_dp,_x,_y,true);
          DrawItem_Brief(1,_dp,_x,_y,false);
        end;
      end;
      DrawItem_Brief(CurPnl,dp,x,y,true);
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
      NeedUpdt := true;
    end;
   kbAltEnd,kbCtrlPgDn: {Alt+End}
    if (Panel[CurPnl].nItems>0) then
    begin
      Panel[CurPnl].lfnofs := Panel[CurPnl].maxlfnofs;
      NeedUpdt := true;
    end;
   kbCtrlGPLus:
   with Panel[CurPnl] do
   begin
     SortAsc  := false;
     NeedSort := true;
     NeedUpdt := true;
     goto ReInit;
   end;
   kbCtrlGMinus:
   with Panel[CurPnl] do
   begin
     SortAsc  := true;
     NeedSort := true;
     NeedUpdt := true;
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
      NeedUpdt := true;
      SeekLast := false;
      goto ReInit;
    end;
   kbCtrlF1,kbCtrlF2,kbCtrlF3,kbCtrlF4,kbCtrlF5:
   with Panel[CurPnl] do
   begin
     if key=kbCtrlF1 then SortMode:=smName else
      if key = kbCtrlF2 then SortMode := smExtension else
       if key = kbCtrlF3 then SortMode := smSize else
        if key = kbCtrlF4 then SortMode := smDateTime else
         if key = kbCtrlF5 then
         begin
           SortMode := smUnsorted;
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
     ShowDot := not ShowDot;
     mkey := kbCtrlR;
   end;
   kbF12:
   begin
     savescr(4);
     fillscr(1,1,80,25,' ');
     recola(1,1,80,25,0);
     while keypressed do readkey;
     if readkey = #0 then readkey;
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
      CurPnl := 1-CurPnl;
      goto reinit;
    end;
   kbAltR,kbCtrlR: {Ctrl+R}
    begin
      with Panel[CurPnl] do
      begin
        if (Panel[CurPnl].nItems > 0)and(dp <= Panel[CurPnl].nItems-1) then if (Items[dp]<>nil) then
        begin
          lastclus := Items[dp]^.f.cluster;
          SeekLast := true;
          _ds := ds; _dp := dp;
          _x := x; _y := y;
        end else seeklast := false;
        Flush_Cache;
        ReadDir(CurPnl);
        fil(x1+1,y2-2,x2-1,' ');
        fil(x1+1,y2-1,x2-1,' ');
        needupdt := true;
        goto reinit;
      end;
    end;
{$IFDEF TestDrive}
   kbCtrlT: {Ctrl+T}
    begin
      TestPanelDrive(CurPnl);
      mKey := kbCtrlR;
    end;
{$ENDIF}
   kbCtrlN: {Ctrl+N}
    with Panel[CurPnl] do
    begin
      UseLFN := not UseLFN;
      mKey := kbCtrlR;
    end;
   kbCtrlX: {Ctrl+X}
    with Panel[CurPnl] do
    begin
      ShowDeleted := not ShowDeleted;
      mKey := kbCtrlR;
    end;
   kbINS:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     if (Items[dp]^.f.name[0]<>'.') then
     begin
       Items[dp]^.f.sel := not Items[dp]^.f.sel;
       DrawItem_Brief(CurPnl,dp,x,y,true);
     end;
     NeedUpdt := true;
     mkey := kbDown;
   end;
   kbAst,kbGrayAst:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i := 0 to nItems-1 do if (Items[i]^.f.attr and faDirectory =  0)and(Items[i]^.f.name[0]<>'.')
       then Items[i]^.f.Sel := not Items[i]^.f.Sel;
     NeedUpdt:=true;
   end;
   kbCtrlGAst:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i := 0 to nItems-1 do
     if {(Items[i]^.f.attr and faDirectory<>0)and}(Items[i]^.f.name[0]<>'.') then
     Items[i]^.f.Sel := not Items[i]^.f.Sel;
     NeedUpdt := true;
   end;
   kbGrayMinus:
   if (Panel[CurPnl].nItems > 0)and(dp < Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i := 0 to nItems-1 do Items[i]^.f.Sel:= false;
     NeedUpdt := true;
   end;
   kbGrayPlus:
   if (Panel[CurPnl].nItems > 0)and(dp<Panel[CurPnl].nItems) then with Panel[CurPnl] do
   begin
     for i := 0 to nItems-1 do if Items[i]^.f.name[0]<>'.' then Items[i]^.f.Sel := true;
     NeedUpdt := true;
   end;
   kbEnter: {Enter}
    if (Panel[CurPnl].nItems > 0) then
    begin
      if (Panel[CurPnl].Items[dp]^.F.Attr and faDirectory<>0) then
      begin
        if (Panel[CurPnl].Items[dp]^.F.Cluster >= 0)and(Panel[CurPnl].Items[dp]^.F.Cluster <= Panel[CurPnl].fd^.clusters)then
        begin
          DrawItem_Brief(CurPnl,dp,x,y,false);
          with Panel[CurPnl] do
          begin
            LastClus := Cluster;
            OldClus  := Cluster;
            Cluster  := Items[dp]^.F.Cluster;
            fil(x1+1,y2-2,x2-1,' ');
            fil(x1+1,y2-1,x2-1,' ');
          end;
          ReadDir(CurPnl);
          NeedUpdt := true;
          SeekLast := true;
          goto ReInit;
        end;
      end;
    end;
   kbBack:
   with Panel[CurPnl] do
   begin
     if (Cluster = 0)or(Cluster = fd^.root_cluster) then
     begin
       ReadDir(CurPnl);
       NeedUpdt := true;
       seeklast := false;
       goto ReInit;
     end else if OldClus >= 0 then
     begin
       LastClus := Cluster;
       Cluster  := OldClus;
       OldClus  := -1;
       ReadDir(CurPnl);
       NeedUpdt := true;
       SeekLast := true;
       goto ReInit;
     end else
     for i := 0 to nItems-1 do
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
        NeedUpdt := true;
        SeekLast := true;
        goto ReInit;
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
  Init := false;
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
  for i := 0 to 1 do
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
    Panel[1].fd^ := Panel[0].fd^;
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
  for d := 0 to 1 do if Panel[d].fd <> nil then dispose(Panel[d].fd);
end;

BEGIN
  if Init then Run;
  Done;
END. {of program DDE}
... and Justice 4 all. (c) MetallicA