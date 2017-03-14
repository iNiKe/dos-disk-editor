{.$F+,I-,O+,X+,D+,L+}
{$F+,I-,O+,X+}
unit LFN;

interface

uses Dos, Strings;

type
  lAPIType = (lDOS, lWIN95, lOS2);

  lSearchRec = record
    SR: SearchRec;
    FileHandle: Word;
    FullName: String;
    FindFirstMode: lAPIType;
    { Other fields will be added later }
  end;

  TNameZ = Array[0..259] of Char;

  lFile = record
    F: File;
    FullName: TNameZ;
    AssignFileMode: lAPIType;
    { Other fields will be added later }
  end;

  lText = record
    T: Text;
    FullName: TNameZ;
    AssignTextMode: lAPIType;
    { Other fields will be added later }
  end;

const
  lAPI: lAPIType = lDOS;

  ltMod = 0;
  ltAcc = 1;
  ltCre = 2;
  LFNTimes: Byte = ltMod;

function LFNDisabled(const Path: String): Boolean;

procedure lFindFirst(const Path: String; Attr: Word; var R: lSearchRec);
procedure lFindNext(var R: lSearchRec);
procedure lFindClose(var R: lSearchRec);

procedure lGetShortFileName(const Name: String; var ShortName: String);
procedure lGetLongFileName(const Name: String; var LongName: String);
procedure lGetFileNameForChangedAPI(FromAPI: lAPIType;
  const Name: String; var NewName: String);

procedure lTrueName(const Name: String; var S: String);

procedure lAssignFile(var F: lFile; const Name: String);
procedure lAssignText(var T: lText; const Name: String);
procedure lResetFile(var F: lFile; RecSize: Word);
procedure lResetReadOnly(var F: lFile; RecSize: Word);
procedure lRewriteFile(var F: lFile; RecSize: Word);
procedure lEraseFile(var F: lFile);
procedure lEraseText(var T: lText);
procedure lRenameFile(var F: lFile; const NewName: String);
procedure lRenameText(var T: lText; const NewName: String);

procedure lGetFAttr(var F: lFile; var Attr: Word);
procedure lSetFAttr(var F: lFile; Attr: Word);
procedure lGetTAttr(var T: lText; var Attr: Word);
procedure lSetTAttr(var T: lText; Attr: Word);

procedure lMkDir(const Path: String);
procedure lRmDir(const Path: String);
procedure lChDir(const Path: String);
procedure lGetDir(D: Byte; var Path: String);

function lFExpand(const Path: String): String;
procedure lFSplit(const Path: String; var Dir, Name, Ext: String);

function lWIN95APIAllowed: Boolean;

implementation

uses DrvList, Disks, Defaults;

function LFNDisabled(const Path: String): Boolean;
var
  Drive: Char;
  Regs: Registers;
begin
  if (Length(Path) > 1) and (Path[1] = '\') and (Path[2] = '\') then
    LFNDisabled := (DriveListOptions and dlUserResources <> 0) and
      UserResourceLFNDisabled(Path)
  else if DriveListOptions and dlGetFromUser = 0 then
    LFNDisabled := False
  else
  begin
    if (Length(Path) > 1) and (Path[2] = ':') then
      Drive := Upcase(Path[1])
    else with Regs do
    begin
      AH := $19;
      Intr($21, Regs);
      Drive := Char(AL + $41);
    end;
    LFNDisabled := (Drive in ['A'..'Z']) and
      (UserDrives[Drive] and udEnabled <> 0) and
      (UserDrives[Drive] and udNoLFN <> 0);
  end;
end;

procedure NameToNameZ(const Name: String; var NameZ: TNameZ);
begin
  Move(Name[1], NameZ, Length(Name));
  NameZ[Length(Name)] := #0;
end;

procedure CheckColonAndSlash(const Name: String; var S: String);
var
  ColonPos: Integer;
begin
  ColonPos := Pos(':', S);
  if (ColonPos > 2) and (Name[2] = ':') then
  begin
    Delete(S, 1, ColonPos - 1);
    S := Name[1] + S;
  end;

  if Name[Length(Name)] <> '\' then
    while S[Length(S)] = '\' do Dec(S[0])
  else if (Name[Length(Name)] = '\') and
    (S[Length(S)] <> '\') and (Length(S) < 255) then
  begin
    Inc(S[0]);
    S[Length(S)] := '\';
  end;
end;

(*
 Offset  Size    Description
  00h    DWORD   file attributes
                 bits 0-6 standard DOS attributes
		 bit 8: temporary file
  04h    QWORD   file creation time
                 (number of 100ns intervals since 1/1/1601)
  0Ch    QWORD   last access time
  14h    QWORD   last modification time
  1Ch    DWORD   file size (high 32 bits)
  20h    DWORD   file size (low 32 bits)
  24h  8 BYTEs   reserved
  2Ch 260 BYTEs  ASCIZ full filename
 130h 14 BYTEs   ASCIZ short filename (for backward compatibility)
*)

type
  lFindDataRec = record
    LoAttr: Word;
    HiAttr: Word;
    LoCreationTime: Longint;
    HiCreationTime: Longint;
    LoLastAccessTime: Longint;
    HiLastAccessTime: Longint;
    LoLastModificationTime: Longint;
    HiLastModificationTime: Longint;
    HiSize: Longint;
    LoSize: Longint;
    Reserved: Array[0..7] of Byte;
    FullName: TNameZ;
    ShortName: Array[0..13] of Char;
  end;

procedure FindDataToSearchRec(var FindData: lFindDataRec; var R: lSearchRec);
begin
  R.SR.Attr := FindData.LoAttr;
  if LFNTimes = ltCre then R.SR.Time := FindData.LoCreationTime
  else if LFNTimes = ltAcc then R.SR.Time := FindData.LoLastAccessTime
  else R.SR.Time := FindData.LoLastModificationTime;
  R.SR.Size := FindData.LoSize;
  R.SR.Name := StrPas(FindData.ShortName);
  R.FullName := StrPas(FindData.FullName);
  if R.SR.Name = '' then
  begin
    R.SR.Name := R.FullName;
    R.FullName := '';
  end;
end;

(*
 INT 21h  AX=714E
 INT 21 - Windows95 - LONG FILENAME - FIND FIRST MATCHING FILE
         AX = 714Eh
         CL = allowable-attributes mask (bits 0 and 5 ignored)
         CH = required-attributes mask
         SI = date/time format
         DS:DX -> ASCIZ filespec (both "*" and "*.*" match any filename)
         ES:DI -> FindData record
 Return: CF clear if successful
             AX = filefind handle (needed to continue search)
             CX = Unicode conversion flags
         CF set on error
             AX = error code
                 7100h if function not supported
 Notes:  this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
         the application should close the filefind handle
         with AX=71A1h as soon as it has completed its search
*)

procedure lWIN95FindFirst(const Path: String; Attr: Word; var R: lSearchRec);
var
  Regs: Registers;
  FindData: lFindDataRec;
begin
  NameToNameZ(Path, FindData.FullName);

  with Regs do
  begin
    AX := $714E;
    CX := Attr;
    SI := 1;
    DS := Seg(FindData.FullName);
    DX := Ofs(FindData.FullName);
    ES := Seg(FindData);
    DI := Ofs(FindData);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then
    begin
      R.FileHandle := $FFFF;
      DosError := AX;
    end
    else
    begin
      R.FileHandle := AX;
      FindDataToSearchRec(FindData, R);
      DosError := 0;
    end;
  end;
end;

(*
 INT 21h  AX=714F
 INT 21 - Windows95 - LONG FILENAME - FIND NEXT MATCHING FILE
	 AX = 714Fh
	 BX = filefind handle (from AX=714Eh)
	 SI = date/time format
	 ES:DI -> buffer for FindData record
 Return: CF clear if successful
	     CX = Unicode conversion flags
	 CF set on error
	     AX = error code
		 7100h if function not supported
 Note:   this function is only available when IFSMgr is running,
	 not under bare MS-DOS 7
*)

procedure lWIN95FindNext(var R: lSearchRec);
var
  Regs: Registers;
  FindData: lFindDataRec;
begin
  with Regs do
  begin
    AX := $714F;
    BX := R.FileHandle;
    SI := 1;
    ES := Seg(FindData);
    DI := Ofs(FindData);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then DosError := AX
    else
    begin
      FindDataToSearchRec(FindData, R);
      DosError := 0;
    end;
  end;
end;

(*
 INT 21h  AX=71A1
 INT 21 - Windows95 - LONG FILENAME - "FindClose" -
          TERMINATE DIRECTORY SEARCH
         AX = 71A1h
         BX = filefind handle (from AX=714Eh)
 Return: CF clear if successful
         CF set on error
            AX = error code
                 7100h if function not supported
 Notes:  this function must be called after starting a search
         with AX=714Eh, to indicate that the search handle
         returned by that function will no longer be used
         this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
*)

procedure lWIN95FindClose(var R: lSearchRec);
var
  Regs: Registers;
begin
  if R.FileHandle <> $FFFF then with Regs do
  begin
    AX := $71A1;
    BX := R.FileHandle;
    Intr($21, Regs);
  end;
end;

procedure lFindFirst(const Path: String; Attr: Word; var R: lSearchRec);
begin
  R.FullName := '';

  case lAPI of
    lDOS:
      begin
	R.FindFirstMode := lDOS;
	FindFirst(Path, Attr, R.SR);
      end;
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Path) then
      begin
	R.FindFirstMode := lDOS;
	FindFirst(Path, Attr, R.SR)
      end
      else
      begin
	R.FindFirstMode := lWIN95;
	lWIN95FindFirst(Path, Attr, R);
      end;
    { Other APIs will be added later }
  end;
end;

procedure lFindNext(var R: lSearchRec);
begin
  R.FullName := '';

  case R.FindFirstMode of
    lDOS: FindNext(R.SR);
    lWIN95: lWIN95FindNext(R);
    { Other APIs will be added later }
  end;
end;

procedure lFindClose(var R: lSearchRec);
begin
  case R.FindFirstMode of
    lDOS: ;
    lWIN95: lWIN95FindClose(R);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7160 CL=01
 INT 21 - Windows95 - LONG FILENAME - GET SHORT (8.3) FILENAME FOR FILE
         AX = 7160h
         CL = 01h
         CH = SUBST expansion flag
             00h return a path containing true path
                 for a SUBSTed drive letter
             80h return a path containing the SUBSTed drive letter
         DS:SI -> ASCIZ long filename or path
         ES:DI -> 67-byte buffer for short filename
 Return: CF set on error
             AX = error code
		 02h invalid component in directory path
                     or drive letter only
                 03h malformed path or invalid drive letter
	     ES:DI buffer unchanged
         CF clear if successful
             ES:DI buffer filled with equivalent short filename
                   (full path, even if relative path given,
                    and all uppercase)
 Note:   this call returns the short name for any
         long-filename portions of the provided pathname or filename
*)

(*
 INT 21h  AX=7160 CL=02
 INT 21 - Windows95 - LONG FILENAME - GET CANONICAL LONG FILENAME OR PATH
         AX = 7160h
         CL = 02h
         CH = SUBST expansion flag
             00h return a path containing true path
                 for a SUBSTed drive letter
	     80h return a path containing the SUBSTed drive letter
         DS:SI -> ASCIZ short filename or path
         ES:DI -> 261-byte buffer for canonicalized long name
 Return: CF set on error
             AX = error code
                 02h invalid component in directory path
                     or drive letter only
                 03h malformed path or invalid drive letter
             ES:DI buffer unchanged
         CF clear if successful
             ES:DI buffer filled with qualified long name
                   (can contain lowercase letters)
*)

procedure lWIN95GetFileNameFunc(const Name: String;
  var S: String; AFunction: Byte);
var
  Regs: Registers;
  NameZ, GetNameZ: TNameZ;
begin
  NameToNameZ(Name, NameZ);

  with Regs do
  begin
    AX := $7160;
    CL := AFunction;
    CH := $80;
    DS := Seg(NameZ);
    SI := Ofs(NameZ);
    ES := Seg(GetNameZ);
    DI := Ofs(GetNameZ);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then S := Name
    else
    begin
      S := StrPas(GetNameZ);
      CheckColonAndSlash(Name, S);
    end;
  end;
end;

procedure lGetShortFileName(const Name: String; var ShortName: String);
begin
  case lAPI of
    lDOS: ShortName := Name;
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Name) then ShortName := Name
      else lWIN95GetFileNameFunc(Name, ShortName, 1);
    { Other APIs will be added later }
  end;
end;

procedure lGetLongFileName(const Name: String; var LongName: String);
begin
  case lAPI of
    lDOS: LongName := Name;
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Name) then LongName := Name
      else lWIN95GetFileNameFunc(Name, LongName, 2);
    { Other APIs will be added later }
  end;
end;

procedure lGetFileNameForChangedAPI(FromAPI: lAPIType;
  const Name: String; var NewName: String);
var
  SaveAPI: lAPIType;
begin
  SaveAPI := lAPI;
  if lAPI = lDOS then lAPI := FromAPI;
  if FromAPI = lDOS then lGetLongFileName(Name, NewName)
  else lGetShortFileName(Name, NewName);
  lAPI := SaveAPI;
end;

(*
 INT 21h  AH=60
 INT 21 - DOS 3.0+ - "TRUENAME" - CANONICALIZE FILENAME OR PATH
         AH = 60h
         DS:SI -> ASCIZ filename or path
         ES:DI -> 128-byte buffer for canonicalized name
 Return: CF set on error
             AX = error code
		 02h invalid component in directory path
                     or drive letter only
                 03h malformed path or invalid drive letter
             ES:DI buffer unchanged
         CF clear if successful
             AH = 00h or 3Ah (DOS 6.1/6.2 for character device)
             AL = destroyed (00h or 2Fh or 5Ch or last character
                  of current directory on drive)
             buffer filled with qualified name of form
               D:\PATH\FILE.EXT or \\MACHINE\PATH\FILE.EXT
 Desc:   determine the canonical name of the specified
         filename or path, corresponding to the undocumented
         TRUENAME command in COMMAND.COM
 Notes:  the input path need not actually exist
         letters are uppercased, forward slashes converted
         to backslashes, asterisks converted to appropriate
         number of question marks, and file and directory
         names are truncated to 8.3 if necessary.
*)

procedure DOSTrueName(const Name: String; var S: String);
var
  Regs: Registers;
  NameZ, GetNameZ: TNameZ;
begin
  NameToNameZ(Name, NameZ);

  with Regs do
  begin
    AH := $60;
    DS := Seg(NameZ);
    SI := Ofs(NameZ);
    ES := Seg(GetNameZ);
    DI := Ofs(GetNameZ);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then S := Name
    else
    begin
      S := StrPas(GetNameZ);
      CheckColonAndSlash(Name, S);
    end;
  end;
end;

(*
 INT 21h  AX=7160 CL=00
 INT 21 - Windows95 - LONG FILENAME - "TRUENAME" - CANONICALIZE PATH
	 AX = 7160h
	 CL = 00h
	 CH = SUBST expansion flag
	     00h return a path containing true path
		 for a SUBSTed drive letter
	     80h return a path containing the SUBSTed drive letter
	 DS:SI -> ASCIZ filename or path (either long name or short name)
	 ES:DI -> 261-byte buffer for canonicalized name
 Return: CF set on error
	     AX = error code
		 02h invalid component in directory path
		     or drive letter only
		 03h malformed path or invalid drive letter
	     ES:DI buffer unchanged
	 CF clear if successful
	     ES:DI buffer filled with fully qualified name
	     AX destroyed
 Desc:   determine the canonical name of the specified
	 filename or path, corresponding to the undocumented
	 TRUENAME command in COMMAND.COM
 Note:   if a complete path is given, the result will be
	 a short-form complete path; otherwise, the given
	 relative path is appended to the short-form
	 current directory name, '.'/'..'/'...'/etc. are resolved,
	 and the final result uppercased without converting
	 any remaining long-form names to short-form
*)

procedure WIN95TrueName(const Name: String; var S: String);
var
  Regs: Registers;
  NameZ, GetNameZ: TNameZ;
begin
  NameToNameZ(Name, NameZ);

  with Regs do
  begin
    AX := $7160;
    CL := 0;
    CH := $00;
    DS := Seg(NameZ);
    SI := Ofs(NameZ);
    ES := Seg(GetNameZ);
    DI := Ofs(GetNameZ);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then S := Name
    else
    begin
      S := StrPas(GetNameZ);
      CheckColonAndSlash(Name, S);
    end;
  end;
end;

procedure lTrueName(const Name: String; var S: String);
begin
  case lAPI of
    lDOS: DOSTrueName(Name, S);
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Name) then DOSTrueName(Name, S)
      else WIN95TrueName(Name, S);
    { Other APIs will be added later }
  end;
end;

procedure lAssignFile(var F: lFile; const Name: String);
begin
  case lAPI of
    lDOS:
      begin
	F.AssignFileMode := lDOS;
	Assign(F.F, Name);
      end;
    { Other APIs will be added later }
    else if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
      LFNDisabled(Name) then
      begin
	F.AssignFileMode := lDOS;
	Assign(F.F, Name);
      end
      else
      begin
	F.AssignFileMode := lWIN95;
	FileRec(F.F).Handle := 0;
	FileRec(F.F).Mode := fmClosed;
	NameToNameZ(Name, F.FullName);
      end;
  end;
end;

{$L W95TFIO.OBJ}
{$L W95TCTL.OBJ}
procedure FileRead; far; external;
procedure FileWrDev; far; external;
procedure FileWrite; far; external;
procedure FileClose; far; external;
procedure FileOpen; far; external;

procedure lAssignText(var T: lText; const Name: String);
begin
  case lAPI of
    lDOS:
      begin
	T.AssignTextMode := lDOS;
	Assign(T.T, Name);
      end;
    { Other APIs will be added later }
    else if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
      LFNDisabled(Name) then
      begin
	T.AssignTextMode := lDOS;
	Assign(T.T, Name);
      end
      else
      begin
	T.AssignTextMode := lWIN95;
	Assign(T.T, '');
	TextRec(T.T).Private := 1;
	TextRec(T.T).OpenFunc := @FileOpen;
	NameToNameZ(Name, T.FullName);
      end;
  end;
end;

(*
 INT 21h  AX=716C
 INT 21 - Windows95 - LONG FILENAME - CREATE OR OPEN FILE
	 AX = 716Ch
	 BX = access mode and sharing flags
	 CX = attributes
	 DX = action
	 DS:SI -> ASCIZ filename
	 DI = alias hint
	      (number to append to short filename for disambiguation)
 Return: CF clear if successful
	     AX = file handle
	     CX = action taken
		 0001h file opened
		 0002h file created
		 0003h file replaced
	 CF set on error
	     AX = error code
		 7100h if function not supported
*)

const
  faOpen = 1;
  faTruncate = 2;
  faCreate = $10;
  faRewrite = faTruncate + faCreate;

procedure lWIN95OpenFile(var F: lFile; RecSize: Word; Action: Byte);
var
  Regs: Registers;
begin
  if FileRec(F.F).Mode <> fmClosed then Close(F.F);
  InOutRes := 0;

  if F.FullName[0] = #0 then
  begin
    FileRec(F.F).Mode := fmInOut;
    FileRec(F.F).RecSize := RecSize;
  end
  else with Regs do
  begin
    AX := $716C;
    BX := FileMode;
    CX := 0;
    DX := Action;
    DS := Seg(F.FullName);
    SI := Ofs(F.FullName);
    DI := 0;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else
    begin
      FileRec(F.F).Mode := fmInOut;
      FileRec(F.F).Handle := AX;
      FileRec(F.F).RecSize := RecSize;
    end;
  end;
end;

procedure lResetFile(var F: lFile; RecSize: Word);
begin
  case F.AssignFileMode of
    lDOS: Reset(F.F, RecSize);
    lWIN95: lWIN95OpenFile(F, RecSize, faOpen);
    { Other APIs will be added later }
  end;
end;

procedure lResetReadOnly(var F: lFile; RecSize: Word);
var
  SaveMode: Byte;
begin
  SaveMode := FileMode;
  FileMode := 64;
  lResetFile(F, RecSize);
  FileMode := SaveMode;
end;

procedure lRewriteFile(var F: lFile; RecSize: Word);
begin
  case F.AssignFileMode of
    lDOS: Rewrite(F.F, RecSize);
    lWIN95: lWIN95OpenFile(F, RecSize, faRewrite);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7141
 INT 21 - Windows95 - LONG FILENAME - DELETE FILE
	 AX = 7141h
	 DS:DX -> ASCIZ long name of file to delete
	 SI = wildcard and attributes flag
		 0000h wildcards are not allowed,
		   and search attributes are ignored
		 0001h wildcards are allowed,
		   and only files with matching
		   names and attributes are deleted
	 CL = search attributes
	 CH = must-match attributes
 Return: CF clear if successful
	 CF set on error
	     AX = error code
		 7100h if function not supported
*)

procedure lWIN95EraseFile(var F: lFile);
var
  Regs: Registers;
begin
  with Regs do
  begin
    AX := $7141;
    DS := Seg(F.FullName);
    DX := Ofs(F.FullName);
    SI := 0;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lEraseFile(var F: lFile);
begin
  case F.AssignFileMode of
    lDOS: Erase(F.F);
    lWIN95: lWIN95EraseFile(F);
    { Other APIs will be added later }
  end;
end;

procedure lWIN95EraseText(var T: lText);
var
  Regs: Registers;
begin
  with Regs do
  begin
    AX := $7141;
    DS := Seg(T.FullName);
    DX := Ofs(T.FullName);
    SI := 0;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lEraseText(var T: lText);
begin
  case T.AssignTextMode of
    lDOS: Erase(T.T);
    lWIN95: lWIN95EraseText(T);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7156
 INT 21 - Windows95 - LONG FILENAME - RENAME FILE
         AX = 7156h
         DS:DX -> ASCIZ old file or directory name (long names allowed)
         ES:DI -> ASCIZ new name (long names allowed)
 Return: CF clear if successful
         CF set on error
             AX = error code
                 7100h if function not supported
 Note:   the file may be renamed into a different directory,
         but not across disks
*)

procedure lWIN95RenameFile(var F: lFile; const NewName: String);
var
  Regs: Registers;
  NameZ: TNameZ;
begin
  NameToNameZ(NewName, NameZ);

  with Regs do
  begin
    AX := $7156;
    DS := Seg(F.FullName);
    DX := Ofs(F.FullName);
    ES := Seg(NameZ);
    DI := Ofs(NameZ);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lRenameFile(var F: lFile; const NewName: String);
begin
  case F.AssignFileMode of
    lDOS: Rename(F.F, NewName);
    lWIN95: lWIN95RenameFile(F, NewName);
    { Other APIs will be added later }
  end;
end;

procedure lWIN95RenameText(var T: lText; const NewName: String);
var
  Regs: Registers;
  NameZ: TNameZ;
begin
  NameToNameZ(NewName, NameZ);

  with Regs do
  begin
    AX := $7156;
    DS := Seg(T.FullName);
    DX := Ofs(T.FullName);
    ES := Seg(NameZ);
    DI := Ofs(NameZ);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lRenameText(var T: lText; const NewName: String);
begin
  case T.AssignTextMode of
    lDOS: Rename(T.T, NewName);
    lWIN95: lWIN95RenameText(T, NewName);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7143
 INT 21 - Windows95 - LONG FILENAME - EXTENDED GET/SET FILE ATTRIBUTES
         AX = 7143h
         DS:DX -> ASCIZ filename
         BL = action
             00h retrieve attributes
                 Return: CX = file attributes
             01h set attributes
                 CX = attributes
             02h get physical size of compressed file
                 Return: DX:AX = actual disk usage of file, in bytes
             03h set last write date/time
                 DI = new last-write date
                 CX = new last-write time
             04h get last write date/time
                 Return: CX = last write time
                         DI = last write date
             05h set last access date
                 DI = new last-access date
             06h get last access date
                 Return: DI = last access date
             07h set creation date/time
                 DI = new creation date
                 CX = new creation time
                 SI = hundredths
                   (10-millisecond units past time in CX, 0-199)
             08h get creation date/time
                 Return: CX = creation time
                         DI = creation date
                         SI = hundredths
                           (10-millisecond units past time in CX)
 Return: CF clear if successful
         CF set on error
             AX = error code
                 7100h if function not supported
*)

const
  faGetAttr = 0;
  faSetAttr = 1;

procedure lWIN95FileAttrFunc(var F: lFile; var Attr: Word; Action: Byte);
var
  Regs: Registers;
begin
  with Regs do
  begin
    AX := $7143;
    BL := Action;
    if Action = faSetAttr then CX := Attr;
    DS := Seg(F.FullName);
    DX := Ofs(F.FullName);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then DosError := AX
    else
    begin
      if Action = faGetAttr then Attr := CX;
      DosError := 0;
    end;
  end;
end;

procedure lGetFAttr(var F: lFile; var Attr: Word);
begin
  case F.AssignFileMode of
    lDOS: GetFAttr(F.F, Attr);
    lWIN95: lWIN95FileAttrFunc(F, Attr, faGetAttr);
    { Other APIs will be added later }
  end;
end;

procedure lSetFAttr(var F: lFile; Attr: Word);
begin
  case F.AssignFileMode of
    lDOS: SetFAttr(F.F, Attr);
    lWIN95: lWIN95FileAttrFunc(F, Attr, faSetAttr);
    { Other APIs will be added later }
  end;
end;

procedure lWIN95TextAttrFunc(var T: lText; var Attr: Word; Action: Byte);
var
  Regs: Registers;
begin
  with Regs do
  begin
    AX := $7143;
    BL := Action;
    if Action = faSetAttr then CX := Attr;
    DS := Seg(T.FullName);
    DX := Ofs(T.FullName);
    Intr($21, Regs);
    if Flags and fCarry <> 0 then DosError := AX
    else
    begin
      if Action = faGetAttr then Attr := CX;
      DosError := 0;
    end;
  end;
end;

procedure lGetTAttr(var T: lText; var Attr: Word);
begin
  case T.AssignTextMode of
    lDOS: GetFAttr(T.T, Attr);
    lWIN95: lWIN95TextAttrFunc(T, Attr, faGetAttr);
    { Other APIs will be added later }
  end;
end;

procedure lSetTAttr(var T: lText; Attr: Word);
begin
  case T.AssignTextMode of
    lDOS: SetFAttr(T.T, Attr);
    lWIN95: lWIN95TextAttrFunc(T, Attr, faSetAttr);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7139
 INT 21 - Windows95 - LONG FILENAME - MAKE DIRECTORY
         AX = 7139h
         DS:DX -> ASCIZ long directory name (including path)
 Return: CF clear if successful
         CF set on error
             AX = error code
                 7100h if function not supported
*)

(*
 INT 21h  AX=713A
 INT 21 - Windows95 - LONG FILENAME - REMOVE DIRECTORY
         AX = 713Ah
         DS:DX -> ASCIZ long name of directory to remove
 Return: CF clear if successful
         CF set on error
             AX = error code
                 7100h if function not supported
*)

procedure lWIN95DirFunc(const Path: String; AFunction: Word);
var
  Regs: Registers;
  NameZ: TNameZ;
begin
  NameToNameZ(Path, NameZ);

  with Regs do
  begin
    AX := AFunction;
    DS := Seg(NameZ);
    DX := Ofs(NameZ);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lMkDir(const Path: String);
begin
  case lAPI of
    lDOS: MkDir(Path);
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Path) then MkDir(Path)
      else lWIN95DirFunc(Path, $7139);
    { Other APIs will be added later }
  end;
end;

procedure lRmDir(const Path: String);
begin
  case lAPI of
    lDOS: RmDir(Path);
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Path) then RmDir(Path)
      else lWIN95DirFunc(Path, $713A);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=713B
 INT 21 - Windows95 - LONG FILENAME - CHANGE DIRECTORY
	 AX = 713Bh
         DS:DX -> ASCIZ long name of directory to make current
 Return: CF clear if successful
	 CF set on error
             AX = error code
                 7100h if function not supported
*)

procedure lWIN95ChDir(const Path: String);
var
  C: Char;
  Regs: Registers;
  NameZ: TNameZ;
begin
  NameToNameZ(Path, NameZ);

  with Regs do
  begin
    C := Upcase(NameZ[0]);
    if (C in ['A'..'Z']) and (NameZ[1] = ':') then
    begin
      AH := $0E;
      DL := Byte(C) - $41;
      Intr($21, Regs);
    end;

    AX := $713B;
    DS := Seg(NameZ);
    DX := Ofs(NameZ);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then InOutRes := AX
    else InOutRes := 0;
  end;
end;

procedure lChDir(const Path: String);
begin
  case lAPI of
    lDOS: ChDir(Path);
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Path) then ChDir(Path)
      else lWIN95ChDir(Path);
    { Other APIs will be added later }
  end;
end;

(*
 INT 21h  AX=7147
 INT 21 - Windows95 - LONG FILENAME - GET CURRENT DIRECTORY
         AX = 7147h
         DL = drive number (00h = current, 01h = A:, etc.)
         DS:SI -> buffer for ASCIZ directory name
 Return: CF clear if successful
         CF set on error
             AX = error code
                 7100h if function not supported
 Notes:  the returned pathname does not include
         the drive letter, colon, or leading backslash
*)

procedure lWIN95GetDir(D: Byte; var Path: String);
var
  C: Char;
  Regs: Registers;
  NameZ: TNameZ;
begin
  with Regs do
  begin
    C := Char(D + $40);

    AX := $7147;
    DL := D;
    DS := Seg(NameZ);
    SI := Ofs(NameZ);
    asm
      stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then NameZ[0] := #0;

    Path := Concat(C, ':\', StrPas(NameZ));
  end;
end;

procedure lGetDir(D: Byte; var Path: String);
var
  Regs: Registers;
begin
  case lAPI of
    lDOS: GetDir(D, Path);
    lWIN95:
      begin
	if D = 0 then with Regs do
	begin
	  AH := $19;
	  Intr($21, Regs);
	  D := AL + 1;
	end;
	if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	  LFNDisabled(Char(D + $40) + ':') then
	begin
	  GetDir(D, Path);
	  Exit;
	end;
	lWIN95GetDir(D, Path);
      end;
    { Other APIs will be added later }
  end;
end;

{ FExpand expands the file name in Path into a fully qualified  }
{ file name. The resulting name consists of a drive letter, a   }
{ colon, a root relative directory path, and a file name.       }
{ Embedded '.' and '..' directory references are removed.       }

{$L W95EXPN.OBJ}           { File name expansion routine }
function LFNFExpand(Path: String): String; external {EXPN};

function lFExpand(const Path: String): String;
begin
  case lAPI of
    lDOS: lFExpand := FExpand(Path);
    lWIN95:
      if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
	LFNDisabled(Path) then lFExpand := FExpand(Path)
      else lFExpand := LFNFExpand(Path);
    { Other APIs will be added later }
  end;
end;

procedure lFSplit(const Path: String; var Dir, Name, Ext: String);
var
  HasColon: Boolean;
  DotPos, SlashPos, B: Byte;
begin
  case lAPI of
    lDOS: FSplit(Path, Dir, Name, Ext);
    lWIN95:
      begin
	Dir := '';
	Name := '';
	Ext := '';
	DotPos := 0;
	SlashPos := 0;
	HasColon := (Length(Path) > 1) and (Path[2] in ['\', ':']);

	for B := Length(Path) downto 1 do
	begin
	  if (Path[B] = '.') and (DotPos = 0) then DotPos := B;
	  if (Path[B] = '\') and (SlashPos = 0) and
	     ((B > 2) or not HasColon) then SlashPos := B;
	  if (DotPos <> 0) and (SlashPos <> 0) then Break;
	end;

	if DotPos + SlashPos = 0 then
	  if HasColon then Dir := Path
	  else Name := Path
	else
	begin
	  if DotPos > SlashPos then Ext := Copy(Path, DotPos, 255)
	  else DotPos := 255;

	  if SlashPos <> 0 then Dir := Copy(Path, 1, SlashPos);

	  Name := Copy(Path, SlashPos + 1, DotPos - SlashPos - 1);
	end;
      end;
    { Other APIs will be added later }
  end;
end;

function lWIN95APIAllowed: Boolean;
var
  SaveAPI: lAPIType;
  SaveOpt: Byte;
  SR: lSearchRec;
begin
  SaveAPI := lAPI;
  SaveOpt := DriveListOptions;
  lAPI := lWIN95;
  DriveListOptions := 0;
  lFindFirst(ParamStr(0), AnyFile, SR);
  lFindClose(SR);
  lAPI := SaveAPI;
  DriveListOptions := SaveOpt;
  lWIN95APIAllowed := DosError = 0;
end;

end.
