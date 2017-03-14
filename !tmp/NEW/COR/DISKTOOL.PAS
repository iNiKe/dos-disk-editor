Unit DiskTool;
(****************************************************************************
 *                      Disk Toolkit Unit v1.03                             *
 ****************************************************************************
 * Доступ чеpез INT 13h                                                     *
 * Drive IDE features                                                       *
 * Встpоенный КЭШ (на ЧТЕHИЕ)                                               *
 *                                                                          *
 * Б*льшое спасиб°:                                                         *
 * ■ Фаронову за книгу "Практика программирования" и за исходники           *
 * ■ Linux-у & его исходникам                                               *
 * ■ A.R.G.-у за исходники Linux                                            *
 * ■ FiDO за talks.asm, ru.hacker, netmail, etc.                            *
 * ■ NiGhthAWk-у за FiDO, Internet, BBS & др.                               *
 * ■ Алексею Зайко (2:5045/66) за поинта, за HDD, etc.                      *
 * ■ ...                                                                    *
 *                                                                          *
 * Пожелания шлите на:                                                      *
 * FidoNet: 2:5045/66.45,Nikita Galaiko                                     *
 * E-Mail: djnike@math.dvgu.ru                                              *
 ****************************************************************************
 *                                                  Last Update: 30/06/2001 *
 ****************************************************************************
 * (C) NiKe'Soft UnLtd.                                                     *
 ****************************************************************************)

{$A-,B-,D+,E+,F-,G+,I+,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}

  INTERFACE

{$DEFINE UseIntCache}

Uses Hex;

const
      MaxLongName       = 255;
      DosSectorSize     = 512;
      Boot_Signature    = $AA55;
      FSector_Signature = $41615252; {"RRaA"}
      FSinfo_Signature  = $61417272; {"rrAa"}

      faReadOnly    = $01;
      faHidden      = $02;
      faSysFile     = $04;
      faVolumeID    = $08;
      faDirectory   = $10;
      faArchive     = $20;
      faAnyFile     = $3F;
      faNone        = 0;
      faUnused      = faVolumeID or faArchive or faSysFile or faHidden;
      faExt         = faReadOnly or faHidden or faSysFile or faVolumeID;

      BAD_MsDOS_chars : array[0..8] of char = ('*','+','?','<','>','|','"','/','\');

      UnKnownFAT  =  0;
      FAT12       =  1;
      FAT16       =  2;
      FAT32       =  3;

      NoError     = 0;
      DiskError   : byte = NoError;
(*
 00h	BYTE	10h (size of packet)
 01h	BYTE	reserved (0)
 02h	WORD	number of blocks to transfer
 04h	DWORD	-> transfer buffer
 08h	QWORD	starting absolute block number
*)
type tTransferBlock = record
       Size   : word;
       Blocks : word;
       BufAdr : pointer;
       BegLo  : longint;
       BegHi  : longint; {0 if HDD < 1000 GB :)}
     end;

type tInt13ExtInfo = record
        majVer : byte;
        extVer : byte;
        Res : byte;
        APB : word; {API subset support Bitmap}
     end;

type tInt13ExtDriveInfo = record {Format of IBM/MS INT 13 Extensions drive parameters}
       IOSize  : word;    {(call) size of buffer (001Ah for v1.x, 001Eh for v2.0)}
                          {(ret) size of returned data}
       Flags   : word;    {information flags}
       Cyls    : longint; {number of cylinders on drive}
       Heads   : longint; {number of heads on drive}
       Sect    : longint; {number of sectors per track}
       ToSLo   : longint; {LO total number of sectors on drive}
       ToSHi   : longint; {HI total number of sectors on drive}
       SecSize : word;    {bytes per sector}
       EnhInfo : pointer;
     end;
     tEnhDrvInfo = record {Format of Phoenix Enhanced Disk Drive Spec translated drive parameter table:}
       Cyls      : word;
       Heads     : byte;
       Sign      : byte; {A0h (signature indicating translated table)}
       SWrPCyl   : word; {starting write precompensation cylinder number}
       res       : byte;
       CtrlBt    : byte; {control byte (see #1857 at INT 41)}
       PhysCyls  : word; {number of physical cylinders}
       PhysHeads : byte; {number of physical heads}
       LandCyl   : word; {cylinder number of landing zone}
       LogSect   : byte; {number of logical sectors per track}
       CRC       : byte; {checksum}
     end;

Type
    PathStr = string[79];         { DOS File pathname string }
    DirStr  = string[67];         { DOS Drive and directory string }
    NameStr = string[8];          { DOS File name string }
    ExtStr  = string[4];          { DOS File extension string }
    tLongName = string[MaxLongName];
    Array512 = array[0..511] of char;

    tDrvBiosInfo = record
      MaxSector : byte;
      MaxHead   : byte;
      MaxTrack  : word;
      SeHD      : longint;
    end;

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

    tLFNelement = record
      ID      : byte;
      Name1   : array[0..4] of word;
      attr    : byte;
      res1    : byte;
      CRC     : byte;
      Name2   : array[0..5] of word;
      cluster : word;
      Name3   : array[0..1] of word;
    end;

    tFAT16Sec = array [0..255] of word;
    tFAT32Sec = array [0..127] of longint;

    pPartition = ^tPartition;
    tPartition = record
      BootF : Byte;     {Флаг активности раздела}
      BegHd : Byte;     {Сторона начала раздела}
      BegSC : Word;     {Сектор/цилиндр начала}
      SysID : Byte;     {Код системы}
      EndHd : Byte;     {Сторона конца раздела}
      EndSC : Word;     {Сектор/цилиндр конца}
      Secs  : LongInt;  {Относительный сектор начала}
      Size  : LongInt   {Объем в секторах}
    end;  {PartType}

    pBoot16 = ^tBoot16;
    tBoot16 = record
      JmpOp      : array[1..3] of byte;      {Обычно, "jmp short XXX; NOP"}
      SysID      : array[1..8] of char;      {ID операционной Системы}
      SectSize   : Word;                     {Количество байт в секторе}
      ClusSize   : Byte;                     {Количество секторов в кластере}
      ResSecs    : Word;                     {Количество секторов перед FAT}
      FatCnt     : Byte;                     {Количество FAT}
      RootSize   : Word;                     {Количество элементов корневого каталога}
      TotSec16   : Word;                     {Количество секторов на диске}
      Media      : Byte;                     {Дескриптор носителя}
      FatSize    : Word;                     {Размер FAT12/16 в секторах}
      SpTrk      : Word;                     {Количество секторов на дорожке для разделов <32 Мбайт или 0}
      HeadCnt    : Word;                     {Количество головок}
      HidnSecLo  : Word;                     {Количество спрятанных секторов для разделов меньше 32 Мбайт}
      HidnSecHi  : Word;                     {Вместе в HidnSecLo дает количество}
      TotSec32   : LongInt;                  {Общее количество секторов для разделов больше 32 Мбайт}
      DrvNum     : byte;                     {Номер физического диска}
      res1       : byte;                     {???}
      ExtBootSig : byte;                     {Расшириная сигнатура диска}
      SerialNum  : longint;                  {Серийный номер}
      DLabel     : array[1..11] of char;     {Метка диска}
      FatID      : array[1..8] of char;      {FAT ID}
      BootPrg    : array[1..384] of Byte;    {Boot Program}
      Part       : array[1..4] of tPartition; {Партишины}
      BootSign   : word;
    end;

    pBoot32 = ^tBoot32;
    tBoot32 = record
      JmpOp        : array[1..3] of byte;      {Обычно, "jmp short XXX; NOP"}
      SysID        : array[1..8] of char;      {ID операционной Системы}
      SectSize     : word;                     {Размер сектора в байтах}
      ClusSize     : byte;                     {Размер кластера в секторах}
      ResSecs      : word;                     {Количество Зарезервированных секторов перед FAT}
      FATcnt       : byte;                     {Количество копий FAT}
      RootSize     : word;                     {Размер корнегого каталога}
      TotSec16     : word;                     {НЕ ИСПОЛЬЗУЕТСЯ (Количество секторов для диска <32MB)}
      Media        : byte;                     {Дискриптор носителя}
      FATsize      : word;                     {Секторов в FAT12/16}
      SpTrk        : word;                     {Секторов на дорожке}
      HeadCnt      : word;                     {Количество Поверхностей}
      HidnSecLo    : word;                     {Lo(Спрятанных секторов)}
      HidnSecHi    : word;                     {Hi(Спрятанных секторов)}
      TotSec32     : longint;                  {Всего секторов}
      FAT32size    : longint;                  {Секторов в FAT32}
      Flags        : byte;                     {Флаги всякие (...,ActiveFat,...)}
      SysMajor     : byte;                     {Старший байт системы}
      SysMinor     : word;                     {Младший байт системы}
      RootClus     : longint;                  {Кластер корня}
      FSect        : word;                     {Относительный сектор информационного сектора FS}
      ResBootSec   : word;                     {Относительный сектор резервного Boot-сектора}
      res1         : array[1..12] of byte;     {???}
      DrvNum       : byte;                     {Номер физического диска}
      res2         : byte;                     {???}
      ExtBootSig   : byte;                     {Расшириная сигнатура диска}
      SerialNum    : longint;                  {Серийный номер}
      DLabel       : array[1..11] of char;     {Метка диска}
      FatID        : array[1..8] of char;      {FAT ID}
      BootPrg      : array[1..356] of byte;    {Boot Program}
      Part         : array[1..4] of tPartition; {Партишины}
      BootSign     : word;                     { = 5DAAh - сигнатура нормального Boot-сектора}
    end;

    tFSInfoSector = record
      Sector_Sign   : longint; {0x41615252}
      res1          : array[0..481] of byte;
      Signature     : longint; {0x61417272}
      Free_Clusters : longint; {Free cluster count.  -1 if unknown}
      Next_Free     : longint; {Most recently allocated cluster}
      res2          : array[0..13] of byte;
    end;

type pBIOS_Drive = ^tBIOS_Drive;
     tBIOS_Drive = record
       Drive     : byte;
       MaxTrack  : word;
       MaxHead   : word;
       MaxSector : byte;
       SEHD      : word;
       SecSiz    : word;
       DBI       : tDrvBiosInfo;
       ExtSup    : boolean;
       ExtInf    : tInt13ExtDriveInfo;
{       EnhInf    : tEnhDrvInfo;{}
     end;

    function  GetDriveInfo(Drv : byte; var DrvInf : tBIOS_Drive) : byte;
    function  GetDrvBiosInfo(Drive : byte; var DrvBIOSInf : tDrvBIOSInfo) : boolean;
    function  Int13ExtIntalled(Drive : byte; var Info : tInt13ExtInfo) : byte;
    function  GetInt13ExtDriveInfo(Drive : byte; var DrvInfo : tInt13ExtDriveInfo; var EnhInfo) : byte;
    procedure UnpackCylSec(CSec: Word; var Cyl : word; var Sec : byte);
    function  CalcFS(Drive : tBIOS_Drive; track : word; Head, Sector : byte) : longint;
    procedure DeCalcFS(Drive : tBIOS_Drive; fs : longint; var track : word; var Head, Sector : byte);
    function  ErrToStr(Error: byte): string;
    procedure Recalibrate(Drive : byte);
    function  CheckSectors(Drive : tBIOS_Drive; Track: word; Head, Sector, Num: byte): boolean;
    function  ReadSectors (Drive : tBIOS_Drive; Head: byte; CylSec: word; num : byte; var buf): boolean;
    function  WriteSectors(Drive : tBIOS_Drive; Head: byte; CylSec: word; num : byte; var buf): boolean;
    function  ReadDataS(Drive : tBIOS_Drive; Track: word; Head, Sector: Byte; num : byte; var iobuf): boolean;
    function  WriteDataS(Drive : tBIOS_Drive; Track: word; Head, Sector, num: Byte; var iobuf): boolean;
    function  Diskette_Changed(Drive : byte) : boolean;
    function  GetSysSt(sysID : byte) : string;
    function  DosChar(c : char) : boolean;
    function  WinChar(c : char) : boolean;
    function  Flush_Cache : integer;
    function  ReadAbsSector(drv : byte; s,n : longint; var bf) : boolean;
    function  WriteAbsSector(drv : byte; s,n : longint; var bf) : boolean;

{$IFDEF UseIntCache}

const Max_Cache_Pages = 128;
type pCache = ^tCache;
     tCache = record
       Drive : byte;
       Data  : array[0..DosSectorSize-1] of char;
       Track : word;
       Head  : byte;
       Sec   : byte;
     end;

var _Cache   : array[1..Max_Cache_Pages] of pCache;
    nCPages  : integer;
    CachePos : integer;
    dap : tTransferBlock;

{$ENDIF}

  IMPLEMENTATION

function ReadAbsSector(drv : byte; s,n : longint; var bf) : boolean;
var e : boolean;
begin
  dap.size := sizeof(dap);
  dap.blocks := 1;
  dap.bufadr := @bf;
  dap.beghi := 0;
  dap.beglo := s-1;
  asm
    mov     AX,4200h
    mov     DL,80h
    lea     SI,dap
    int     13h
    mov     e,al
  end;
  ReadAbsSector := not e;
end;

function WriteAbsSector(drv : byte; s,n : longint; var bf) : boolean;
var e : boolean;
begin
  dap.size := sizeof(dap);
  dap.blocks := 1;
  dap.bufadr := @bf;
  dap.beghi := 0;
  dap.beglo := s-1;
  asm
    mov     AX,4300h
    mov     DL,80h
    lea     SI,dap
    int     13h
    mov     e,al
  end;
  WriteAbsSector := not e;
end;

function GetDriveInfo(Drv : byte; var DrvInf : tBIOS_Drive) : byte;
var EnhInf : tEnhDrvInfo;
    ei : tInt13ExtInfo;
begin
  GetDriveInfo := 1; fillchar(DrvInf,sizeof(DrvInf),#0);
  if GetDrvBiosInfo(Drv,DrvInf.DBI) then
  begin
    with DrvInf do
    begin
      Drive := Drv;
      ExtSup := false;
      GetDriveInfo := 0;
      if Int13ExtIntalled(Drive,ei) = 0 then
      begin
        if GetInt13ExtDriveInfo(Drive,ExtInf,EnhInf) = 0 then
        begin
          if ExtInf.Cyls > 1 then
          begin
            MaxTrack := ExtInf.Cyls-1;
            if ExtInf.Heads > 1 then
            begin
              MaxHead := ExtInf.Heads-1;
              if ExtInf.Sect > 0 then MaxSector := ExtInf.Sect;
              begin
                if ExtInf.SecSize > 0 then
                begin
                  SecSiz := ExtInf.SecSize;
                  ExtSup := true;
                end;
              end;
            end;
          end;
        end;
      end;
      if not ExtSup then
      begin
        MaxTrack := DBI.MaxTrack;
        MaxHead := DBI.MaxHead;
        MaxSector := DBI.MaxSector;
        SecSiz := DOSSECTORSIZE;
      end;
      SEHD := (MaxSector)*(MaxHead+1);
    end;
  end;
end;

(*
INT 13 - IBM/MS INT 13 Extensions - GET DRIVE PARAMETERS
	AH = 48h
	DL = drive (80h-FFh)
	DS:SI -> buffer for drive parameters (see #0179)
Return: CF clear if successful
	    DS:SI buffer filled
	CF set on error
	    AH = error code (see #0140)
*)
function GetInt13ExtDriveInfo(Drive : byte; var DrvInfo : tInt13ExtDriveInfo; var EnhInfo) : byte;
{assembler;}
var e : byte;
begin
  DrvInfo.IOSize := sizeof(DrvInfo);
  DrvInfo.EnhInfo := @EnhInfo;
  asm
     mov ah,48h
     mov dl,Drive
     lds si,DrvInfo
     int 13h
     mov e,0
     jnc @NoError
     mov e,ah
  @NoError:
  end;
  GetInt13ExtDriveInfo := e;
end;

function Int13ExtIntalled(Drive : byte; var Info : tInt13ExtInfo) : byte;
var Inst,a,b,d : byte; c : word;
{assembler;}
begin
  asm
     mov ah,41h
     mov bx,55AAh
     mov dl,Drive
     int 13h
     jc  @NotInstalled
     mov a,ah
     mov b,al
     mov c,cx
     mov d,dh
     mov inst,1 {installed}
     jmp @End
  @NotInstalled:
     mov inst,0 {not installed}
  @End:
  end;
  if inst = 1 then
  with Info do
  begin
    majVer := a;
    extVer := d;
    Res    := b;
    APB    := c;
    Int13ExtIntalled := 0;
  end else
  begin
    fillchar(info,sizeof(info),#0);
    Int13ExtIntalled := 1;
  end;
end;

{$IFDEF UseIntCache}
function  Flush_Cache;
var i : integer;
begin
  if nCPages > Max_Cache_Pages then nCPages := Max_Cache_Pages;
  for i := 1 to nCPages do if _Cache[i] <> nil then begin dispose(_Cache[i]); _Cache[i] := nil; end;
  nCPages := 0;
  CachePos := 0;
  Flush_Cache := NoError;
end;
{$ELSE}
function  Flush_Cache; assembler;
asm
end;
{$ENDIF}

function  DosChar(c : char) : boolean;
begin
  if (c<' ')
  or(c='"')or(c='*')or(c='+')or(c='/')
  or((c>=':')and(c<='?'))
  or((c>='[')and(c<=']'))
  or((c>='[')and(c<=']'))
  or(c='|')
   then DosChar := false
    else DosChar := true;
end;

function  WinChar(c : char) : boolean;
begin
  if ((c='+')or(c=';')or(c='=')or(c='[')or(c=']')) then WinChar := true
    else WinChar := false;
end;

procedure UnpackCylSec;
{Декодирует цилиндр и сектор для прерывания $13}
begin
  Cyl := (CSec and 192) shl 2 + CSec shr 8;
  Sec := CSec and 63
end;

Function PackCylSec(Cyl : word; Sec : byte) : word;
{Упаковывает цилиндр и сектор в одно слово для прерывания $13}
begin
  PackCylSec := Sec+(Cyl and $300) shr 2 + (Cyl shl 8)
end;

procedure DeCalcFS;
begin
  with Drive do
  if (fs > 0)and(MaxSector > 0)and(SeHD > 0) then
  begin
   Track := fs div SeHD;
   fs := fs mod SeHD;
   if fs = 0 then
   begin
     fs := SeHD;
     dec(Track);
   end;
   Head := fs div MaxSector;
   Sector := fs mod MaxSector;
   if Sector = 0 then
   begin
     Sector := MaxSector;
     Dec(Head);
   end;
  end else
  begin
    Sector := 0; Track := 0; Head := 0;
  end;
end;

function CalcFS;
begin
  with Drive do
  if (MaxSector > 0)and(SeHD > 0) then
  begin
    CalcFS := longint(SeHD)*longint(Track) + longint(Head)*longint(MaxSector) + Sector;
  end else
  begin
    CalcFS := 0;
  end;
end;

function  CheckSectors;
{assembler;}
begin
  asm
     cli
     mov  dl, Drive.Drive
     mov  dh, Head
     mov  cx, Track
     xchg cl, ch
     shl  cl, 6
     add  cl, Sector
     mov  al, num
     mov  ah, 04h
     int  13h
     mov  DiskError, ah
     mov  al, 1
     jnc  @NoError
     xor  al, al
  @NoError:
     sti
  end;
end;

function  ReadSectors;
{$IFDEF UseIntCache}
var f,e : boolean;
    i,t : word;
    s   : byte;
begin
  e := false;
  if num < 1 then exit;
  if num = 1 then
  begin
    if Drive.Drive < 2 then if Diskette_Changed(Drive.Drive) then Flush_Cache;
    UnPackCylSec(cylsec,t,s);
    f := false;
    for i := 1 to nCPages do if _Cache[i] <> nil then
    begin
      if _Cache[i]^.Drive  = Drive.Drive then
       if _Cache[i]^.Track = t then
        if _Cache[i]^.Head = Head then
         if _Cache[i]^.Sec = s then begin f := true; break; end;
    end;
  end else f := false;
  if f then
  begin
    e := true;
    move(_Cache[i]^.data,buf,DosSectorSize)
  end else
  begin
{$ELSE}
assembler;
{$ENDIF}
asm
   mov  dl, Drive.Drive
   mov  dh, Head
   mov  cx, CylSec
   les  bx, buf
   mov  al, num
   mov  ah, 02h
   int  13h
   mov  al, 1
   jnc  @NoError
   xor  al, al
@NoError:
{$IFDEF UseIntCache}
   mov  e,al
{$ENDIF}
end;
{$IFDEF UseIntCache}
    if (e){and(num = 1)} then
    begin
      if CachePos < Max_Cache_Pages then inc(CachePos) else CachePos := 1;
      if (nCPages < CachePos) then
      begin
        inc(nCPages);
        new(_Cache[nCPages]);
      end else if _Cache[CachePos]=nil then new(_Cache[CachePos]);
      if _Cache[CachePos]<>nil then
      begin
        _Cache[CachePos]^.Drive := Drive.Drive;
        _Cache[CachePos]^.Head  := Head;
        _Cache[CachePos]^.Track := T;
        _Cache[CachePos]^.Sec   := S;
        move(buf,_Cache[CachePos]^.data,sizeof(_Cache[1]^.data));
      end;
    end;
  end;
  ReadSectors := e;
end;
{$ENDIF}

Function  ReadDataS;
var SecBeg : longint;
{$IFDEF UseIntCache}
var f,e : boolean;
    i   : word;
begin
  e := false;
  if num < 1 then exit;
  if (num = 1) then
  begin
    if Drive.Drive < 2 then if Diskette_Changed(Drive.Drive) then Flush_Cache;
    f := false;
    for i := 1 to nCPages do if _Cache[i] <> nil then
    begin
      if _Cache[i]^.Drive = Drive.Drive then
       if _Cache[i]^.Track = Track then
        if _Cache[i]^.Head = Head then
         if _Cache[i]^.Sec = Sector then begin f := true; break; end;
    end else
    begin
      nCPages := i-1; break;
    end;
  end else f := false;
  if f then
  begin
    e := true;
    move(_Cache[i]^.data,iobuf,DosSectorSize)
  end else
  begin
{$ELSE}
{assembler;}
begin
{$ENDIF}
  if Drive.ExtSup then
  begin
    SecBeg := CalcFS(Drive,Track,Head,Sector-1);
    dap.size := sizeof(dap);
    dap.Blocks := num;
    dap.bufadr := @iobuf;
    dap.BegLo := SecBeg;
    dap.BegHi := 0;
    asm
       mov DL,Drive.Drive
       lea si,dap
       mov AX,4200h
       int 13h
    end;
    e := true;
  end else
asm
   cli
   mov  dl, Drive.Drive
   mov  dh, Head
   mov  cx, Track
   xchg cl, ch
   shl  cl, 6
   add  cl, Sector
   les  bx, ioBuf
   mov  al, num
   mov  ah, 02h
   int  13h
   mov  DiskError,ah
   mov  al, 1
   jnc  @NoError
   xor  al, al
@NoError:
   sti
{$IFDEF UseIntCache}
   mov  e,al
{$ELSE}
end;
{$ENDIF}
end;
{$IFDEF UseIntCache}
    if (e){and(num = 1)} then
    begin
      if CachePos < Max_Cache_Pages then inc(CachePos) else CachePos := 1;
      if (nCPages < CachePos) then
      begin
        inc(nCPages);
        new(_Cache[nCPages]);
      end else if _Cache[CachePos]=nil then new(_Cache[CachePos]);
      if _Cache[CachePos]<>nil then
      begin
        _Cache[CachePos]^.Drive := Drive.Drive;
        _Cache[CachePos]^.Head  := Head;
        _Cache[CachePos]^.Track := Track;
        _Cache[CachePos]^.Sec   := Sector;
        move(iobuf,_Cache[CachePos]^.data,sizeof(_Cache[1]^.data));
      end;
    end;
  end;
  ReadDataS:=e;
end;
{$ENDIF}

Function  WriteDataS;
{$IFDEF UseIntCache}
begin
  Flush_Cache;
{$ELSE}
assembler;
{$ENDIF}
asm
   cli
   mov  dl, Drive.Drive
   mov  dh, Head
   mov  cx, Track
   xchg cl, ch
   shl  cl, 6
   add  cl, Sector
   les  bx, ioBuf
   mov  al, num
   mov  ah, 03h
   int  13h
   mov  DiskError,ah
   mov  al, 1
   jnc  @NoError
   xor  al, al
@NoError:
   sti
{$IFDEF UseIntCache}
end;
{$ENDIF}
end; {WriteDataS}

function  WriteSectors;
{$IFDEF UseIntCache}
begin
  Flush_Cache;
{$ELSE}
assembler;
{$ENDIF}
asm
   mov  dl, Drive.Drive
   mov  dh, Head
   mov  cx, CylSec
   les  bx, buf
   mov  al, num
   mov  ah, 03h
   int  13h
   mov  al, 1
   jnc  @NoError
   xor  al, al
@NoError:
{$IFDEF UseIntCache}
end;
{$ENDIF}
end; {WriteSectorS}

procedure Recalibrate; assembler;
asm
{Recalibrate}
   xor  ah,ah
   mov  dl,Drive
   int  13h
{Re-Init according 2 Drive table}
   mov  ah,09h
   mov  dl,Drive
   int  13h
end;

function  Diskette_Changed; assembler;
asm
   mov   ah,16h
   mov   dl,Drive
   int   13h
   cmp   ah,06h
   je    @Changed
   mov   al,0
   jmp @Exit
@Changed:
   mov   al,1
@Exit:
end;

function  GetDrvBiosInfo;
var tt : word; hh,sec : byte;
begin
  asm
   cli
   mov  ah, 08h
   mov  dl, Drive
   int  13h
   mov  DiskError, ah
   jc  @Error
   dec  dl
   mov  HH,dh
   mov  al,cl
   and  al,3fh
   mov  Sec,al
   xor  ax,ax
   and  cl,0C0h
   mov  al,cl
   shl  ax,2
   mov  al,ch
   mov  TT,ax
   xor  al, al
   jmp  @NoError
@Error:
   mov  al,1
   mov  Sec,0
   mov  HH,0
   mov  TT,0
@NoError:
   sti
  end;
  with DrvBiosInf do
  begin
    MaxSector := Sec;
    MaxHead   := hh;
    MaxTrack  := tt;
    SeHD      := (MaxHead+1)*MaxSector;
    GetDrvBiosInfo := (SeHD>0);
  end;
end;

function  GetSysSt;
begin
  case sysID of
 $00:    GetSysSt := 'UnUsed';
 $01:    GetSysSt := 'DOS FAT12';
 $02:    GetSysSt := 'XENIX root';
 $03:    GetSysSt := 'XENIX /usr';
 $04:    GetSysSt := 'DOS FAT16 < 32mb';
 $05:    GetSysSt := 'Extended';
 $06:    GetSysSt := 'DOS FAT16 > 32mb';
 $07:    GetSysSt := 'NTFS ???';
 $08:    GetSysSt := 'AIX ???';
 $09:    GetSysSt := 'AIX';
 $09:    GetSysSt := 'Coherent FS';
 $0A:    GetSysSt := 'OS/2 ???';
 $0B:    GetSysSt := 'M$ Win FAT32';
 $0C:    GetSysSt := 'M$ Win FAT32x';
 $0E:    GetSysSt := 'BigDOSx';
 $0F:    GetSysSt := 'Extended-X';
 $10:    GetSysSt := 'OPUS';
 $11:    GetSysSt := 'OS/2 FAT12-h';
 $12:    GetSysSt := 'Compaq';
 $14:    GetSysSt := 'OS/2 FAT16-h < 32mb';
 $16:    GetSysSt := 'OS/2 FAT16-h > 32mb';
 $17:    GetSysSt := 'OS/2 HPFS-h';
 $18:    GetSysSt := 'AST Windows swap';
 $24:    GetSysSt := 'NEC MS-DOS 3.x';
 $3C:    GetSysSt := 'PQ PM recovery';
 $40:    GetSysSt := 'VENIX 80286';
 $42:    GetSysSt := 'SFS';
 $50:    GetSysSt := 'DM, read-only';
 $51:    GetSysSt := 'Novell???';
 $52:    GetSysSt := 'CP/M ???';
 $56:    GetSysSt := 'GoldenBow VFeature';
 $61:    GetSysSt := 'SpeedStor';
 $63:    GetSysSt := 'Unix SysV/386 ???';
 $64:    GetSysSt := 'Novell NetWare';
 $65:    GetSysSt := 'Novell NetWare+';
 $70:    GetSysSt := 'DiskSecure M-Boot';
 $75:    GetSysSt := 'PC/IX';
 $80:    GetSysSt := 'Minix';
 $81:    GetSysSt := 'Linux ???';
 $82:    GetSysSt := 'Linux Swap';
 $83:    GetSysSt := 'Linux EXT2fs/xIAfs';
 $84:    GetSysSt := 'OS/2-renumbered';
 $93:    GetSysSt := 'Amoeba FS';
 $94:    GetSysSt := 'Amoeba Bad Block';
 $A5:    GetSysSt := 'FreeBSD';
 $B7:    GetSysSt := 'BSDI FS (1 Swap)';
 $B8:    GetSysSt := 'BSDI Swap (2 FS)';
 $C1:    GetSysSt := 'DR-DOS FAT12-s';
 $C4:    GetSysSt := 'DR-DOS FAT16-s';
 $C6:    GetSysSt := 'DR-DOS Huge-s';
 $C7:    GetSysSt := 'Cyrnix Boot';
 $DB:    GetSysSt := 'CP/M ???';
 $E1:    GetSysSt := 'SpeedStor FAT12';
 $F2:    GetSysSt := 'DOS sec.';
 $E4:    GetSysSt := 'SpeedStor FAT16';
 $FE:    GetSysSt := 'LANstep';
 $FF:    GetSysSt := 'Xenix bad block';
  else   GetSysSt := 'UnKnown ('+hexb(sysID)+'h)';
  end;
end;

Function ErrToStr;
begin
  case Error of
NoError: ErrToStr:='';
$01: ErrToStr:='Неправильная команда';
$02: ErrToStr:='Не найдена адресная метка';
$03: ErrToStr:='Диск защищен от записи';
$04: ErrToStr:='Сектор не найден';
$05: ErrToStr:='Ошибка рекалибровки';
$06: ErrToStr:='Произошла замена дискеты';
$07: ErrToStr:='Ошибка в параметрах DBT диска';
$08: ErrToStr:='Переполнение канала DMA';
$09: ErrToStr:='Выход за границу 64k DMA';
$0a: ErrToStr:='Плохой сектор';
$0b: ErrToStr:='Плохая дорожка';
$0c: ErrToStr:='Неправильный номер дорожки';
$0d: ErrToStr:='Неправильный номер сектора';
$0e: ErrToStr:='Обнаружена адресная метка управляющих данных';
$0f: ErrToStr:='Ошибка DMA';
$10: ErrToStr:='Ошибка данных (CRC failed)';
$11: ErrToStr:='Данные скорректированы схемами контроля';
else ErrToStr:='Неизвестная ошибка';
  end;
End;

function DosStr(st : string) : boolean;
var i : integer;
begin
  DosStr := true;
  for i := 1 to byte(st[0]) do if not DosChar(st[i]) then begin DosStr:=false; break; end;
end;

{$IFDEF UseIntCache}
var i : integer;
BEGIN
  for i := 1 to Max_Cache_Pages do _Cache[i] := nil;
  nCPages  := 0;
  CachePos := 0;
{$ENDIF}
END. {of unit}
... and Justice 4 all. (c) MetallicA