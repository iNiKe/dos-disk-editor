Unit HelpZ;

   INTERFACE

const
      stTopic = '.topic';
      stTitle = '.title';
      hiNoTopic      = 0;
      hiAbout        = 1;
      hiChooseDrives = 2;
      hiChoosePart   = 3;
      hiViewFiles    = 4;

type  pString = ^string;

procedure ViewHelp(hlpfile : string; idx : word);

   IMPLEMENTATION Uses DOS,TextModeUtil,Service;

procedure ViewHelp;
var f : text;
    found : boolean;
    s,t : string;
    i : integer;
    lines : array[1..5000] of pString;
begin
{$I-}
  assign(f,hlpfile); reset(f);
  if IOResult<>0 then exit;
  found:=false; {ищем запрощенный топик}
  t:=upcasestr(stTopic)+' ';
  while (not eof(f))or(not found) do
  begin
    readln(f,s);
    i:=1;
    s:=ltrim(rtrim(s));
    if upcasestr(copy(s,1,length(stTopic)+1))=t then
    begin
      s:=ltrim(copy(s,length(stTopic)+1,255));
      found:=true;

    end;
  end;
  close(f);
end;

END.
... and Justice 4 all. (c) MetallicA                                                               \Data\1V9ZF9JR.DAT         DistributionUnitDirectAnimation Java Classes         Info  Ў 
   ║+                   C:\WINDOWS\SYSTEM\SHDOCVW.DLL        	 ThreadingModelApartmentй   %  й         dragdrop        % PathC:\WINDOWS\JAVA\Packages\F9NZP3H3.ZIP        * SignerC:\WINDOWS\JAVA\Packages\Data\3N333HV1.DAT         Info   _     ╗*          RJ.EXE   8      8         DEAD.EXE         DEADDEMO.DAT   L   !  L         DEMO.EXE       
  DFDEMO.BAT            DFDEMO   ;   "  ;         DOGNAPP.EXE         GAMEMAPS.RR2   5   #  5         DS.BAT         TOSTEXT.BIN   1   ░  1         DS.EXE         NDD.EXE   :   ▒  :         DRACULA.EXE         SETDRAC.EXE   n     n         InProcServer3          C:\WINDOWS\SYSTEM\SHDOCVW.DLL        	 ThreadingModelApartment╪(          :\WININST0.400 /SrcDir=D:\Win98\Win98Se.Rus /IX /IZ /IS /IQ /IT /II /NR /II /C  /U:xxxxxxxxxxxxxxxxx   H4-M	   WallPaper         TileWallpaper0   INGN  Upgrade         T InstallClassesSystem,hdc,fdc,CDROM,PCMCIA,MultiFunction,SCSIAdapter,Adapter,USB,HID,Mouse,Keyboard   S32M
  ConfigPathC:\WINDOWS\config       	  MediaPathC:\WINDOWS\media      ~  ICMPathC:\WINDOWS\SYSTEM\COLOR   regs  HWSetup1         WallPaperRestore1       
  OLSSrcPathD:\Win98\Win98Se.Rus\OLS         SetupBinarysucatreg.exe   ERN~  InstallPathType            PostDetectSrcPathD:\Win98\Win98Se.Rus\\x   K  x         Detect         ACPICheckDate12/01/99   sDir  Versionо
       	  TimeStamp04/06/01,15:33:18ї%          INDOWS       
  MachineDirC:\        
 WinAdminDirC:\WINDOWS       	 
 SharedDirC:\WINDOWS         SysDirC:\WINDOWS\SYSTEM       
  SourcePathC:\WINDOWS\SYSTEM\PRECOPY       	   OldWinDir         UninstallDirC:\UNINSTAL.000       	  BackupDirC:\UNINSTAL.000         SetupTempDirC:\WININST0.400         SetupScratchDirC:\WINDOWS\INF   C:\P  MemphisDetectedLastDriveZ        h CommandLine/T:C:\WININST0.400 /SrcDir=D:\Win98\Win98Se.Rus /IX /IZ /IS /IQ /IT /II /NR /II /C  /U:xxxxxxxxxxxxxxxxx   H4-M	   WallPaper         TileWallpaper0   INGN  Upgrade         T InstallClassesSystem,hdc,fdc,CDROM,PCMCIA,MultiFunction,SCSIAdapter,Adapter,USB,HID,Mouse,Keyboard   S32M
  ConfigPathC:\WINDOWS\config       	  MediaPathC:\WINDOWS\media      ~  ICMPathC:\WINDOWS\SYSTEM\COLOR   regs  HWSetup1         WallPaperRestore1       
  OLSSrcPathD:\Win98\Win98Se.Rus\OLS         SetupBinarysucatreg.exe   ERN~  InstallPathType            PostDetectSrcPathD:\Win98\Win98Se.Rus\\щ!          tubs MICROS         CheckSChannel1       	 < RunOnceExrundll32.exe C:\WINDOWS\SYSTEM\iernonce.dll,RunOnceExProcess   w о   Connection_Manager_MigC:\WINDOWS\SYSTEM\cmstp.exe /mp   dll| : MDAC_InstODBCDriversC:\WINDOWS\SYSTEM\odbcconf @C:\WINDOWS\SYSTEM\odbcconf.rsp        O RegSvr_MDAC_7C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msado15.dll"        P RegSvr_MDAC_14C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msador15.dll"        P RegSvr_MDAC_21C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msadrh15.dll"        O RegSvr_MDAC_28C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msadomd.dll"        N RegSvr_MDAC_35C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msadox.dll"        M RegSvr_MDAC_105C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\ado\msjro.dll"        P RegSvr_MDAC_623C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msadce.dll"        P RegSvr_MDAC_637C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msadcf.dll"        P RegSvr_MDAC_651C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msadco.dll"        P RegSvr_MDAC_672C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msadds.dll"        R RegSvr_MDAC_686C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msdaprst.dll"        Q RegSvr_MDAC_700C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msdarem.dll"        Q RegSvr_MDAC_721C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\msadc\msdfmap.dll"        R RegSvr_MDAC_455C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdaps.dll"        T RegSvr_MDAC_462C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msxactps.dll"        S RegSvr_MDAC_469C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\oledb32.dll"        T RegSvr_MDAC_476C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\oledb32x.dll"        T RegSvr_MDAC_497C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdaenum.dll"        R RegSvr_MDAC_511C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdatt.dll"        S RegSvr_MDAC_525C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdasql.dll"        S RegSvr_MDAC_574C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdaosp.dll"        S RegSvr_MDAC_581C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\msdaora.dll"        T RegSvr_MDAC_826C:\WINDOWS\SYSTEM\regsvr32.exe /s "C:\PROGRA~1\COMMON~1\System\oledb~1\sqloledb.dll"        @ RegSvr_MDAC_196C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msjtes40.dll        ? RegSvr_MDAC_217C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msjet40.dll        @ RegSvr_MDAC_245C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msrd3x40.dll        @ RegSvr_MDAC_252C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msrd2x40.dll        @ RegSvr_MDAC_266C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msrclr40.dll        @ RegSvr_MDAC_280C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msexcl40.dll        @ RegSvr_MDAC_287C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msexch40.dll        @ RegSvr_MDAC_294C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msltus40.dll        @ RegSvr_MDAC_301C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\mspbde40.dll        @ RegSvr_MDAC_308C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\mstext40.dll        @ RegSvr_MDAC_315C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msxbde40.dll        D RegSvr_MDAC_322C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msjetoledb40.dll        @ RegSvr_MDAC_323C:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\msorcl32.dll        D PowerProf SettingsRunDLL setupx.dll,InstallHinfSection PowerCfg.runonce 0 powercfg.inf    А  Q MSI_RegSvr_MSISys.OCXC:\WINDOWS\SYSTEM\regsvr32.exe /s C:\PROGRA~1\COMMON~1\MICROS~1\MSInfo\MSIsys.OCX        > MSI_RegSvr_EyeDog.OCXC:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\EyeDog.OCX        = MSI_RegSvr_br549.OCXC:\WINDOWS\SYSTEM\regsvr32.exe /s C:\WINDOWS\SYSTEM\br549.OCX        P MSI_RegSvr_MSIAV.OCXC:\WINDOWS\SYSTEM\regsvr32.exe /s C:\PROGRA~1\COMMON~1\MICROS~1\MSInfo\msiav.ocx        S MSI_RegSvr_MSICDROM.OCXC:\WINDOWS\SYSTEM\regsvr32.exe /s C:\PROGRA~1\COMMO