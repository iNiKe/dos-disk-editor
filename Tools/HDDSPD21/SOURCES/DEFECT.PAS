{*$X+,G+,D-,L-,S-,R-}
unit Defect;

interface

uses Objects, Drivers, Quantum;

type

  PDefectEntry = ^TRawDefectEntry;
  TDefectEntry = Record
    Cylinder  : Word;
    Head      : Byte;
    Sector    : Byte;
  end;

  PDefectList = ^TDefectList;
  TDefectList = Object(TCollection)
    DefectsCount    : Word;
    MaxDefectsCount : Word;
    DefectEntryList : Array [1..8191] of TDefectEntry;

    constructor Init(ALimit, ADelta: Integer);
    procedure   FreeItem(Item: Pointer); virtual;
    procedure   AddDefect(var Entry); virtual;

    procedure   Save; virtual;
  end;

  PQuantumDefectList = ^TQuantumDefectList;
  TQuantumDefectList = Object(TDefectList)
    procedure   FreeItem(Item: Pointer); virtual;
    procedure   AddDefect(var Entry); virtual;
  end;

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
constructor TDefectList.Init(ALimit, ADelta: Integer);
begin
  inherited Init(ALimit, ADelta);
  DefectsCount := 0; MaxDefectsCount := 0;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TDefectList.FreeItem(Item: Pointer);
begin
  Abstract;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TDefectList.AddDefect(var Entry);
begin
  Abstract;
end;

procedure   TDefectList.Save;
var
  F : Text;
  i : Word;
begin
  Assign(F, 'defects.lst'); Rewrite(F);
  for i := 1 to DefectsCount do
    WriteLn(F, DefectEntryList[i].Cylinder, '/',
               DefectEntryList[i].Head, '/',DefectEntryList[i].Sector);
  Close(F);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TQuantumDefectList.FreeItem(Item: Pointer);
begin
  If Item <> Nil then DisposeStr(Item);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TQuantumDefectList.AddDefect(var Entry);
const
  FStr = '%4d  %7d    %2d   %4d';
var
  Cylinder  : LongInt;
  Sector    : LongInt;
  bCylinder : Array [0..3] of Byte absolute Cylinder;
  bSector   : Array [0..3] of Byte absolute Sector;

  FData     : Record
                No      : LongInt;
                C, H, S : LongInt;
              end;
  S         : String;
  QFB_TM_Entry : TRawDefectEntry absolute Entry;
begin
  bCylinder[3] := 0;
  bCylinder[2] := QFB_TM_Entry.Cylinder[0];
  bCylinder[1] := QFB_TM_Entry.Cylinder[1];
  bCylinder[0] := QFB_TM_Entry.Cylinder[2];
  bSector[3]   := QFB_TM_Entry.Sector[0];
  bSector[2]   := QFB_TM_Entry.Sector[1];
  bSector[1]   := QFB_TM_Entry.Sector[2];
  bSector[0]   := QFB_TM_Entry.Sector[3];

  FData.No := Count+1;
  FData.C := Cylinder; FData.H := QFB_TM_Entry.Head; FData.S := Sector;
  FormatStr(S, FStr, FData);
  If Sector = -1 then S := S+ '  **BAD**';
  Insert(NewStr(S));

  DefectEntryList[Count].Cylinder := Cylinder;
  DefectEntryList[Count].Head := QFB_TM_Entry.Head;;
  DefectEntryList[Count].Sector := Sector;
end;

begin
end.
