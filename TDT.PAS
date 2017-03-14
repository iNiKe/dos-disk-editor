uses disktool;
var drv : byte;
   beghd : byte;
   begsc : word;
   boot_sector : array512;
begin
  ReadSectors(Drv,BegHD,BegSC, 1, boot_sector)
end.