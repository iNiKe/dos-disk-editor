Date:  Mon, 16 Nov 87 09:39:01 EST
From: nelson @ clutx.clarkson.edu
Subject:  Absolute disk read/write from Turbo Pascal v6.68

Yes, you CAN use INT 13 to read/write disks instead of INT 25 and INT 26.
Unfortunately, if you do, then your program will not work with installed
device drivers, like a ramdisk.  I found this out the hard way when the
disk recovery program that I wrote couldn't recover my ramdisk.  Ouch!

{ module rwsector.inc -- module to read and write absolute sectors }
{ Copyright 1986, Russell Nelson.  Freely copyable for all uses so long
  as this copyright message and following authorship notice are retained.

Author:

  Russell Nelson
  11 Grant St.
  Potsdam, N.Y. 13676
  GEnie:    BH01                    Compu$erve: 70441,205
  BITNET:   NELSON@CLUTX            Internet: nelson@clutx.clarkson.edu

Usage:

  If, for any reason, you want to read/write an absolute sector, this code
  will do it for you.  Note that the count must be a variable, not an
  expression.  The count is set to the number of sectors not read/written.

Exports:
function read_sector(unit, sectno : integer; var count : integer; var buffer)
  : integer;
function write_sector(unit, sectno : integer; var count : integer; var buffer)
  : integer;

Example:

var
  sector : array[0..511];
  error : integer;
  count : integer;
begin
  count := 1;
  error := read_sector(0, 0, count, sector);
  end.

}

{ return -1 if no errors, or error number if error. }
function read_sector(unit, sectno : integer; var count : integer; var buffer)
  : integer;
begin
  inline(
    $1E/                      {         push  ds                  }
    $C5/ $5E/ $04/            {         lds   bx,dword ptr 4[bp]  }
    $8B/ $56/ $0C/            {         mov   dx,12[bp]           }
    $8B/ $46/ $0E/            {         mov   ax,14[bp]           }
    $C4/ $7E/ $08/            {         les   di,8[bp]            }
    $26/ $8B/ $0D/            {         mov   cx,es:[di]          }
    $55/                      {         push  bp                  }
    $CD/ $25/                 {         int   25h                 }
    $5D/                      {         pop   bp                  }
    $5D/                      {         pop   bp                  }
    $72/ $02/                 {         jc    rsect_1             }
    $B0/ $FF/                 {         mov   al,-1               }
    $98/                      {rsect_1: cbw                       }
    $89/ $46/ $10/            {         mov   16[bp],ax           }
    $C4/ $7E/ $08/            {         les   di,8[bp]            }
    $26/ $89/ $0D/            {         mov   es:[di],cx          }
    $1F                       {         pop   ds                  }
    );
  end;


{ return -1 if no errors, or error number if error. }
function write_sector(unit, sectno : integer; var count : integer; var buffer)
  : integer;
begin
  inline(
    $1E/                      {         push  ds                  }
    $C5/ $5E/ $04/            {         lds   bx,dword ptr 4[bp]  }
    $8B/ $56/ $0C/            {         mov   dx,12[bp]           }
    $8B/ $46/ $0E/            {         mov   ax,14[bp]           }
    $C4/ $7E/ $08/            {         les   di,8[bp]            }
    $26/ $8B/ $0D/            {         mov   cx,es:[di]          }
    $55/                      {         push  bp                  }
    $CD/ $26/                 {         int   26h                 }
    $5D/                      {         pop   bp                  }
    $5D/                      {         pop   bp                  }
    $72/ $02/                 {         jc    wsect_1             }
    $B0/ $FF/                 {         mov   al,-1               }
    $98/                      {wsect_1: cbw                       }
    $89/ $46/ $10/            {         mov   16[bp],ax           }
    $C4/ $7E/ $08/            {         les   di,8[bp]            }
    $26/ $89/ $0D/            {         mov   es:[di],cx          }
    $1F                       {         pop   ds                  }
    );
  end;
