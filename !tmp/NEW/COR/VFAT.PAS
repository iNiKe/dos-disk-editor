Unit vFAT;
(****************************************************************************
 *   Модуль для работы с FAT-совместимыми файловыми системами v1.0 beta 2   *
 ****************************************************************************
 * Поддержка FAT12                                                          *
 * Поддержка FAT16                                                          *
 * Поддержка FAT32 (+FSInfo)                                                *
 *                                                                          *
 * Большое спасибо:                                                         *
 * ■ Фаронову за книгу "Практика программирования" и исходники к ней        *
 * ■ Linux-у & его исходникам                                               *
 * ■ A.R.G.-у за исходники Linux                                            *
 * ■ FiDO за talks.asm, ru.hacker, , nice.sources, netmail, etc.            *
 * ■ NiGhthAWk-у за FiDO, Internet, BBS & др.                               *
 * ■ ...                                                                    *
 *                                                                          *
 * Пожелания шлите на:                                                      *
 * FidoNet: 2:5045/66.45,Nikita Galaiko                                     *
 * E-Mail: djnike@chat.ru                                                   *
 ****************************************************************************
 *                                                   Last Update: 17/06/Y2k *
 ****************************************************************************
 * (C) NiKe'Soft                                                            *
 ****************************************************************************)

  INTERFACE Uses DiskTool,Service,Unicode;

const
     EOF_FAT12 = $0FF8;
     EOF_FAT16 = $FFF8;
     EOF_FAT32 = $0FFFFFF8;  {F$%#%g M$ "FAT32" is really FAT28  8( | ) }
                 {^ - see it ?!}
     FS_Auto   = $00;
     FS_FAT12  = $01;  {FAT12}
     FS_FAT16  = $01;  {FAT16}
     FS_FAT32  = $03;  {F$%$#%g M$ FAT32 aKa "FAT28"}
     FS_None   = $FF;
{
     AllowLFN : boolean = true;
}

type pFat_Device = ^tFat_Device;
     tFat_Device = record
       Drive          : tBIOS_Drive;
       DrvBiosInfo    : tDrvBiosInfo;
       Sector_Length  : word;          {Размер сектора в байтах}
       Start_Sector   : longint;       {}
       Fat_bits       : byte;
       Fats           : byte;          {Число копий FAT}
       Root_Size      : word;          {Размер корневого каталога}
       BAD_Mark,
       EOF_Mark,
       Max_Mark       : longint;
       Root_Cluster   : longint;
       Root_Start     : longint;
       Sectors        : longint;
       Clusters       : longint;
       Cluster_Length : word;
       Fat_Start      : longint;
       Fat_Length     : longint;
       FSInfo_Sector  : longint;
       Free_Clusters  : longint;
       Next_Free      : longint;
       Data_Start     : longint;
       Data_Sectors   : longint;
     end;

type tFat_Device_File = record
       Name       : string[255];
       Cluster    : longint;
       DirCluster : longint;
       lCase      : byte;          {Char case of name & ext}
       cTime_ms   : byte;          {Creation time, milliseconds}
       cTime      : word;          {Creation time}
       cDate      : word;          {Creation date}
       aDate      : word;          {Last access date}
       Date       : longint;
       Size       : longint;
       Pos        : longint;
       Attr       : byte;
       Mode       : byte;
       fd         : pFat_Device;
     end;

var  Buffer : array[0..511] of byte;

function  Mount_FAT_Device(Drv : tBIOS_Drive; Part : TPartition; FS_Type : byte; var FatDev : TFat_Device) : integer;
function  UnMount_FAT_Device(var FatDev : TFat_Device) : integer;
function  Get_Cluster_Sector(FatDev : TFat_Device; Cluster : longint) : longint;
function  Get_Sector_Cluster(FatDev : TFat_Device; Sector : longint) : longint;
function  Read_Cluster(FatDev : TFat_Device; Cluster, Len : longint; var Buf) : integer;
function  Get_FAT_Item(FatDev : TFat_Device; Item : longint) : longint;
function  Set_FAT_Item(FatDev : TFat_Device; Item : longint; Value : longint) : integer;
function  Read_Sectors(FatDev : TFat_Device; Sector : longint; n : byte; var buf) : integer;
function  Write_Sectors(FatDev : TFat_Device; Sector : longint; n : byte; var buf) : integer;
function  Get_Dir_Cluster(FatDev : TFat_Device; StartCluster : longint; Path: String) : longint;

function  Make_Directory(FatDev : tFat_Device; DirCluster : longint; DirName : string) : integer;
function  Remove_Directory(FatDev : tFat_Device; DirCluster : longint; DirName : string) : integer;

procedure AddLfn(var lfn : string; l : tLFNelement);
function  lCRC(buf : array of char) : byte;
function  Valid_Alias(alias : array of char) : boolean;

  IMPLEMENTATION

var Boot_Sector : tBoot16;

function  Valid_Alias;
var i : byte;
begin
  Valid_Alias := true;
  for i:=0 to 10 do if not DosChar(alias[i]) then
  begin
    Valid_Alias := false;
    exit;
  end else if alias[i]=#0 then
  begin
    inc(i);
    for i:=i to 10 do if not (alias[i] in [#0,#255]) then
    begin
      Valid_Alias := false;
      exit;
    end
  end;
end;

function lCRC;
var c,s:byte;
begin
  c:=0;
  for s:=0 to 10 do
  begin
    asm ror c,1 end;
    inc(c,byte(buf[s]));
  end;
  lcrc:=c;
end;

procedure AddLfn;
var i : byte; ts : string;
begin
  ts:='';
  for i:=0 to 4 do ts:=ts+Uni2char(l.name1[i]);
  for i:=0 to 5 do ts:=ts+Uni2char(l.name2[i]);
  for i:=0 to 1 do ts:=ts+Uni2char(l.name3[i]);
  lfn := ts+lfn;
end;

function  Mount_Fat_Device;
var e,i : integer; t : word; s : byte;
label Exit;
begin
  with FatDev do
  begin
    e := 0;
    Drive:=drv;
    Recalibrate(Drive.Drive);
    if (GetDrvBiosInfo(Drv.Drive,DrvBiosInfo))and(DrvBiosInfo.MaxSector>0)and(DrvBiosInfo.SeHD>0) then
    begin
      with Part do if ReadSectors(Drv,BegHD,BegSC, 1, boot_sector) then with boot_sector do
      begin
        if (fatcnt<=0)or(fatcnt>16)or((FatSize<=0)and(tBoot32(boot_sector).fat32size<=0))or((TotSec16<=0)
           and (TotSec32<=0))or(ClusSize<=0) then
        begin
          e:=3;
          goto Exit;
        end;
        Fat_Start := ResSecs;
        fats := FATcnt;
        if fatcnt=0 then
        begin
          e:=3;
          goto Exit;
        end;
        Cluster_Length := clussize;
        Sector_Length  := DosSectorSize;
        with drvbiosinfo do
        begin
          SeHd := longint(longint(MaxSector)*longint(MaxHead+1));
          UnpackCylSec(BegSC,t,s);
          Start_Sector := longint(t)*longint(SeHD) + longint(BegHD)*longint(MaxSector) + longint(s);
        end;
        if TotSec16=0 then Sectors:=TotSec32 else Sectors:=TotSec16;
        Root_Size    := rootsize;
        EOF_Mark:=0;
        if FatSize=0 then Fat_length:=tBoot32(boot_sector).fat32size else Fat_length:=FatSize;
        Root_Start := Fat_Start + Fats*Fat_length;
        Data_Start := Root_Start + longint(longint(Root_Size) shl longint(5)) shr 9;
        Clusters := (Sectors) div Cluster_Length + 2;
        if (Clusters > 65526)or(fs_type=fs_fat32) then with tBoot32(boot_sector) do
        begin
          Fat_bits := 32;
          EOF_Mark := EOF_FAT32;
          Fat_Length := tBoot32(boot_sector).fat32size;
          Root_Cluster := rootclus;
          fsinfo_sector := fsect;
          Free_Clusters := -1;
          Next_Free     := -1;
          if Read_Sectors(fatdev,fsinfo_sector,1,buffer) = NoError then
          begin
            if tFSInfoSector(Buffer).Sector_Sign = FSector_Signature then
            if tFSInfoSector(Buffer).Signature = FSinfo_Signature then
            begin
              Free_Clusters := tFSInfoSector(Buffer).Free_Clusters;
              Next_Free     := tFSInfoSector(Buffer).Next_Free;
              if Free_Clusters < 0 then Free_Clusters := -1;
              if (Next_Free < 0)or(Next_Free > Clusters-2) then Next_Free := 2;
            end;
          end;
        end else
        begin
          if (Clusters>4086)or(fs_type=fs_fat16) then
          begin
            EOF_Mark := EOF_FAT16;
            Fat_Bits := 16
          end else
          if (clusters>0) then
          begin
            EOF_Mark := EOF_FAT12;
            Fat_bits := 12;
          end else
          begin
            e:=3;
            goto exit;
          end;
          Fat_Length := FatSize;
          Root_Cluster := 0;
          fsinfo_sector := -1;
          Free_Clusters := -1;
        end;
        BAD_Mark  := EOF_Mark - 1;
        Max_Mark  := EOF_Mark + $F-$8;
      end else e:=2;
    end else e:=1;
  end;

Exit:
  if e<>NoError then
  begin
    fillchar(fatdev,sizeof(fatdev),#0);
  end;

  Mount_FAT_Device := e;
end;

function  UnMount_FAT_Device;
var e : integer;
begin
  e := NoError;
  UnMount_FAT_Device:=e;
end;

function  Get_FAT_Item;
var k,j,n : integer;
    ft : record
    case byte of
    0: (fat16: array[0..512 div 2 - 1] of word);
    1: (fat12: array[0..512*3 - 1] of byte);
    3: (fat32: array[0..512 div 4 - 1] of longint);
    end;
    it : longint;
begin
  with FatDev do
  begin
    Get_FAT_Item := Max_Mark;
    n := 0;
    if (Item < 0) or (Item > Clusters) then Exit;
    if (Fat_Bits = 32) then
    begin
      k := Item div 128;
      j := Item mod 128;
      n := 1;
    end else
    if (Fat_bits = 16) then
    begin
      k := Item div 256;
      j := Item mod 256;
      n := 1;
    end else
    if (Fat_Bits = 12) then
    begin
      k := Item div 1024;
      j := (3*Item) shr 1 - k*1536;
      n := 3;
    end;
    if Read_Sectors(FatDev,Fat_Start + k*n,n,ft)=0 then
    begin
      if (fat_bits = 32) then
      begin
        Get_FAT_Item := longint(ft.fat32[j]) and $0FFFFFFF; {F$%#%g M$ "FAT32" is really FAT28 :(}
      end else
      if (fat_bits = 16) then
      begin
        Get_FAT_Item := word(ft.fat16[j]);
      end else
      if (fat_bits = 12) then
      begin
        it := word(ft.fat12[j] + ft.fat12[j+1] shl 8);
        if odd(Item) then Get_FAT_Item := it shr 4 else Get_FAT_Item := it and $FFF;
      end;
    end;
  end;
end;

function  Set_FAT_Item;
var k,j,n : integer;
    ft : record
    case byte of
    0: (fat16: array[0..512 div 2 - 1] of word);
    1: (fat12: array[0..512*3 - 1] of byte);
    3: (fat32: array[0..512 div 4 - 1] of longint);
    end;
    it : longint;
begin
  with FatDev do
  begin
    if (Item>0)or(Item>Clusters) then
    begin
      Set_FAT_Item := 1;
      exit;
    end;
    n := 0;
    if (Item < 0) or (Item > Clusters) then Exit;
    if (Fat_Bits = 32) then
    begin
      k := Item div 128;
      j := Item mod 128;
      n := 1;
    end else
    if (Fat_bits = 16) then
    begin
      k := Item div 256;
      j := Item mod 256;
      n := 1;
    end else
    if (Fat_Bits = 12) then
    begin
      k := Item div 1024;
      j := (3*Item) shr 1 - k*1536;
      n := 3;
    end;
    if Read_Sectors(FatDev,Fat_Start + k*3,n,ft)=0 then
    begin
      if (fat_bits = 32) then
      begin
        ft.fat32[j] := (longint(Value) and $0FFFFFFF) or (ft.fat32[j] and $F0000000);
      end else
      if (fat_bits = 16) then
      begin
        ft.fat16[j] := word(Value);
      end else
      if (fat_bits = 12) then
      begin
        if odd(Item) then Value := Value shl 4 + ft.fat12[j] and $F
          else Value := Value + (ft.fat12[j+1] and $F0) shl 12;
        ft.fat12[j  ]:=lo(word(Value));
        ft.fat12[j+1]:=hi(word(Value));
        j := k*n;
        while(j+n > Fat_Length) do dec(n);
      end;
      for k:=0 to pred(Fats) do Write_Sectors(FatDev,Fat_Start + j + k*Fat_Length,n,ft);
    end;
  end;
end;

function Read_Cluster;
begin
  Read_Cluster := 0;
end;

function  Get_Cluster_Sector;
begin
  with FatDev do
  begin
    if cluster=0 then cluster:=root_cluster;
    if Cluster>1 then
    begin
      Get_Cluster_Sector := longint(Data_Start) + (longint(Cluster)-2)*longint(Cluster_Length);
    end else if cluster=0 then
    begin
      Get_Cluster_Sector:= root_start;
    end else Get_Cluster_Sector:=Max_Mark;
  end;
end;

function  Get_Sector_Cluster;
begin
  with FatDev do
  begin
    Get_Sector_Cluster := 0;
  end;
end;

function  Read_Sectors;
var tr : word; hd,se : byte;
begin
  if n>0 then with FatDev do
  begin
    if ReadAbsSector(Drive.Drive,Start_Sector + Sector,n,buf) then Read_Sectors := NoError else Read_Sectors := 2;
(*
    DecalcFS(DrvBiosInfo,Start_Sector + Sector,tr,hd,se);
    if ReadDatas(Drive,tr,hd,se,n,buf) then Read_Sectors := NoError else Read_Sectors := 2;
*)
  end else Read_Sectors := 1;
end;

function  Write_Sectors;
var tr : word; hd,se : byte;
begin
  if n>0 then with FatDev do
  begin
    if WriteAbsSector(Drive.Drive,Start_Sector + Sector,n,buf) then Write_Sectors := NoError else Write_Sectors := 2;
(*
    DecalcFS(DrvBiosInfo,Start_Sector + Sector,tr,hd,se);
    if WriteDatas(Drive,tr,hd,se,n,buf) then Write_Sectors := NoError else Write_Sectors := 2;
*)
  end else Write_Sectors := 1;
end;

function Get_Dir_Cluster;
{Возвращает адрес сектора, в котором содержится начало
 нужного каталога, или Max_Mark, если каталог не найден}
var i,j,k : longint;                      {Вспомогательные переменные}
    Find  : Boolean;                      {Признак поиска}
    m     : array [0..10] of Char;        {Массив имени каталога}
    s     : String;                       {Вспомогательная переменная}
    s3    : string[3];
    Dir   : array [1..16] of tDirElement; {Сектор каталога}
    Clus  : longint;                      {Текущий кластер каталога}
    DirSz : word;
    DirS  : longint;
label err,done;
begin
  Clus:=0;
  if Path = '' then goto Done;
  while (Path[1] in [' ',#0,#$FF])and(length(Path)>0) do Delete(Path,1,1);
  if Path[2]=':' then Delete(Path,1,2);
  if Path[1]='\' then begin Delete(Path,1,1); startcluster:=0 end;
  while (Path[1] = '\')and(length(Path)>0) do Delete(Path,1,1);
  while (Path[Length(Path)] = '\')and(length(Path)>0) do Delete(Path,Length(Path),1);
  if Path='' then goto done;
  Path := UpCaseStr(Path);
  Clus := StartCluster;                             {Кластер начала каталога}
  if clus=0 then clus:=fatdev.root_cluster;
  DirS := Get_Cluster_Sector(FatDev,Clus);          {Сектор}
  if Read_Sectors(FatDev,Dirs,1,Dir)<>0 then goto Err;
{Цикл поиска по каталогам}
  if startcluster = 0 then
   if (FatDev.Root_Size=0)and(fatdev.fat_bits<>32) then DirSz := 512 div sizeof(tDirElement)
    else DirSz := FatDev.Root_Size
     else DirSz := 0;
  Find  := Path='';
  while not Find do with FatDev do
  begin
    s := Path;
    j := pos('\',s);
    if j > 0 then s[0] := chr(j-1);
    i := length(s);
    if s[1]<>'.' then
    begin
      j := pos('.',s);
      if j > 0 then
      begin
        delete(s,j,1);
        if length(s)-j > 3 then goto err; {EXTention more than 3 chars}
        k:= 3 - (length(s)-j);
        while(length(s) - k < 8) do insert(' ',s,j);
      end;
    end;
    while(length(s) < 11) do s:=s+' ';
    if length(s) > 11 then goto Err;
    FillChar(m,11,' ');
    move(s[1],m,ord(s[0]));
    Delete(Path,1,i);
    while (Path[1] = '\')and(length(Path)>0) do Delete(Path,1,1);
    k := 0; {Количество просмотренных элементов каталога}
    j := 1;
    repeat
      if Dir[j].Name[1]=#0 then Goto Err;    {начинается c 0 - это конец каталога}
      if (Dir[j].Attr and faDirectory = faDirectory) then
       if (Dir[j].Attr and faVolumeID <> faVolumeID) then
      begin
        Find := True;
        i := 0;
        while Find and (i<=10) do
        begin {Проверяем имя}
          Find := m[i] = Dir[j].NameExt[i];
          inc(i)
        end
      end;
      if not Find then inc(j);
      if j >= 17 then
      begin         {Исчерпан сектор каталога}
        j := 1;
        inc(k,16);  {k - сколько элементов просмотрели}
        if DirSz > 0 then if k >= DirSz then goto err; {Дошли до конца каталога}
        if (k div 16) mod Cluster_Length = 0 then
        begin     {Исчерпан кластер - ищем следующий}
          Clus := Get_FAT_Item(FatDev,Clus);
          if Clus >= BAD_Mark then goto Err;
          DirS := Get_Cluster_Sector(FatDev,Clus)
        end else inc(DirS);
        if Read_Sectors(FatDev,Dirs,1,Dir)<>NoError then goto Err;
      end
    until Find;
{Наден каталог для очередного имени в маршруте}
    Clus  := Dir[j].Cluster;                    {Кластер начала}
    DirSz := 0;
    DirS  := Get_Cluster_Sector(FatDev,Clus);           {Сектор}
    if Read_Sectors(FatDev,Dirs,1,Dir)<>NoError then goto Err;
    Find  := Path = ''
  end; {while not Find}
  if not find then
  begin
Err:
    Get_Dir_Cluster := -1;
  end else
  begin
Done:
    Get_Dir_Cluster := Clus;
  end;
end;  {GetDirSector}

function  Make_Directory;
begin

end;

function  Remove_Directory;
begin

end;

END.
... and Justice 4 all. (c) MetallicA