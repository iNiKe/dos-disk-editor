{*$X+,G+,D-,L-,S-,R-}
unit Quantum;

interface

type

  PQuantumConfiguration = ^TQuantumConfiguration;
  TQuantumConfiguration = Record
    ConfigurationKey : Array [0..31] of Char; {= 'QUANTUM CONFIGURATION'}
    DiskCache        : Byte;
    Reserved         : Array [1..3] of Byte;
    ErrorRecovery    : Byte;
    RetriesCount     : Byte;
    ECCSpan          : Byte;
    DriveParams      : Byte;
    Reserved2        : Array [40..511] of Byte;
  end;

  PRawDefectEntry = ^TRawDefectEntry;
  TRawDefectEntry = Record
    Cylinder  : Array [0..2] of Byte;
    Head      : Byte;
    Sector    : Array [0..3] of Byte;
  end;

  PRawDefectList = ^TRawDefectList;
  TRawDefectList = Array [0..8190] of TRawDefectEntry;

const
   QuantumKey : String[31] = 'QUANTUM CONFIGURATION          ';

implementation

begin
end.
