(********************************************************)
(*            Модуль с реализацией потока в XMS-памяти  *)
(*            1994 (c) Бурнашов А.В. 2:5030/254.36      *)
(********************************************************)

unit XMS;
interface
uses objects;
 { TXMSStream }
type

  PXMSStream = ^TXMSStream;
  TXMSStream = object(TStream)
    Handle    :word;
    XMSSize   :word;

    Size      :longint; {порядок и размер этих полей менять нельзя}
    Position  :longint; {см. Init в конце}
    Delta     :word;    {}
    constructor Init(ASize:word;ADelta:word);
    destructor  Done;virtual;
    function    GetPos: Longint; virtual;
    function    GetSize: Longint; virtual;
    procedure   Read(var Buf; Count: Word); virtual;
    procedure   Seek(Pos: Longint); virtual;
    procedure   Truncate; virtual;
    procedure   Write(var Buf; Count: Word); virtual;
  end;

function CMOSGetBaseSize : Word;
function CMOSGetExtendedSize : Word;
function CMOSGetTotalSize : Word;

function XMSGetFree : Word;
function EMSGetTotal : Word;
function EMSGetFree : Word;

implementation

type
    TXMSMoveStruct=
      record
       Length    : longint;  {кол-во пересылаемых байт }
       SouHandle : word;     {откуда (0-обычная память)}
       SouOffset : longint;  {                         }
       DstHandle : word;     {куда                     }
       DstOffset : longint;  {                         }
      end;

const

  XMM_Entry:pointer=nil;

{ TStream support routines }

const
  TStream_Error = vmtHeaderSize + $04;

{ Stream error handler                                  }
{ In    AX    = Error info                              }
{       DX    = Error code                              }
{       ES:DI = Stream object pointer                   }
{ Uses  AX,BX,CX,DX,SI                                  }

procedure DoStreamError; near; assembler;
asm
        PUSH    ES
        PUSH    DI
        PUSH    DX
        PUSH    AX
        PUSH    ES
        PUSH    DI
        MOV     DI,ES:[DI]
        CALL    DWORD PTR [DI].TStream_Error
        POP     DI
        POP     ES
end;

constructor TXMSStream.Init(ASize:word;ADelta:word);assembler;
asm
{Инициализируем объект - inherited Init}
        XOR     AX,AX
        PUSH    AX
        LES     DI,Self
        PUSH    ES
        PUSH    DI
        CALL    TStream.Init

        MOV     AX,XMM_Entry.Word[0]
        OR      AX,XMM_Entry.Word[2]
        JZ      @@Error
{вделяем блок памяти}
        LES     DI,Self
        MOV     AH,09h
        MOV     DX,ASize
        MOV     ES:[DI].TXMSStream.XMSSize,DX
        CALL    XMM_Entry
        OR      AX,AX
        MOV     AL,BL
        JNZ     @@4
{ошибка}
@@Error:MOV     DX,stInitError
        CALL    DoStreamError
        MOV     DX,-1
@@4:    MOV     ES:[DI].TXMSStream.Handle,DX
        XOR     AX,AX
        ADD     DI,offset TXMSStream.Size
        CLD
        STOSW
        STOSW
        STOSW
        STOSW
        MOV     AX,ADelta
        STOSW
end;

destructor TXMSStream.Done; assembler;
asm
        LES     DI,Self
        MOV     DX,ES:[DI].TXMSStream.Handle
        CMP     DX,-1
        JE      @@1
        MOV     AX,XMM_Entry.Word[0]
        OR      AX,XMM_Entry.Word[2]
        JZ      @@1
        MOV     AH,0Ah
        CALL    XMM_Entry
        OR      AX,AX
        MOV     AL,BL
        JNZ     @@1
        MOV     DX,stError
        CALL    DoStreamError

@@1:    XOR     AX,AX
        PUSH    AX
        PUSH    ES
        PUSH    DI
        CALL    TStream.Done
end;

function TXMSStream.GetPos: Longint; assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TXMSStream.Status,0
        JNE     @@1
        MOV     AX,ES:[DI].TXMSStream.Position.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Position.Word[2]
        JMP     @@2
@@1:    MOV     AX,-1
        CWD
@@2:
end;

function TXMSStream.GetSize: Longint; assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TXMSStream.Status,0
        JNE     @@1
        MOV     AX,ES:[DI].TXMSStream.Size.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Size.Word[2]
        JMP     @@2
@@1:    MOV     AX,-1
        CWD
@@2:
end;

procedure TXMSStream.Read(var Buf; Count: Word); assembler;
 var MoveStruct:TXMSMoveStruct;
asm
{проверка инициализации}
        MOV     AX,XMM_Entry.Word[0]
        OR      AX,XMM_Entry.Word[2]
        JZ      @@Error
{проверка того, что мы читаем в пределах потока}
        LES     DI,Self
        XOR     BX,BX
        CMP     ES:[DI].TXMSStream.Status,BX
        JNE     @@Clear
        MOV     AX,ES:[DI].TXMSStream.Position.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Position.Word[2]

        ADD     AX,Count
        ADC     DX,BX
        CMP     DX,ES:[DI].TXMSStream.Size.Word[2]
        JA      @@Error
        JB      @@Read
        CMP     AX,ES:[DI].TXMSStream.Size.Word[0]
        JBE     @@Read
{ошибка-чтение за пределом потока}
@@Error:
        XOR     AX,AX
@@Error2:
        MOV     DX,stReadError
@@2:    CALL    DoStreamError
{очистка буфера}
@@Clear:
        LES     DI,Buf
        MOV     CX,Count
        XOR     AL,AL
        CLD
        REP     STOSB
        JMP     @@Exit
{читаем}
@@Read:
{fill MoveStruct}
        PUSH    DS
        LDS     SI,Self
        MOV     AX,SS
        MOV     ES,AX
        LEA     DI,MoveStruct
        CLD

        MOV     AX,Count
        MOV     CX,AX
{adjust Count in AX to Odd and save byte}
        TEST    AL,1
        JZ      @@4
        INC     AX
@@4:
        STOSW   {Length[0]}
        XOR     AX,AX
        STOSW   {Length[2]}

        MOV     AX,DS:[SI].TXMSStream.Handle
        STOSW      {SouHandle}

        MOV     AX,DS:[SI].TXMSStream.Position.Word[0]
        STOSW      {SouOffset[0]}
        MOV     AX,DS:[SI].TXMSStream.Position.Word[2]
        STOSW      {SouOffset[2]}

        XOR     AX,AX
        STOSW      {DstHandle}

        MOV     AX,Buf.Word[0]
        MOV     SI,AX
        STOSW      {DstOffset[0]}
        MOV     AX,Buf.Word[2]
        STOSW      {DstOffset[2]}

{save byte, CX=count}
        ADD     SI,CX
        JNC     @@5
        ADD     AX,1000h
@@5:
        MOV     DS,AX
        MOV     CH,DS:[SI]
        POP     ES
        PUSH    ES
        PUSH    CX
        PUSH    DS
        PUSH    SI

        MOV     AX,SS
        MOV     DS,AX
        LEA     SI,MoveStruct
        MOV     AH,0Bh
        CALL    ES:XMM_Entry

        POP     SI
        POP     DS
        POP     CX
        MOV     DS:[SI],CH
        POP     DS

        LES     DI,Self
        OR      AX,AX
        MOV     AL,BL
        JE      @@Error2

        MOV     AX,Count
        ADD     ES:[DI].TXMSStream.Position.Word[0],AX
        ADC     ES:[DI].TXMSStream.Position.Word[2],0
@@Exit:
end;

procedure TXMSStream.Seek(Pos: Longint); assembler;
asm
        LES     DI,Self
        CMP     ES:[DI].TXMSStream.Status,0
        JNE     @@Exit

        MOV     AX,Pos.Word[0]
        MOV     DX,Pos.Word[2]
        OR      DX,DX
        JNS     @@1
        XOR     AX,AX
        CWD
@@1:    MOV     ES:[DI].TXMSStream.Position.Word[0],AX
        MOV     ES:[DI].TXMSStream.Position.Word[2],DX
@@Exit:
end;

procedure TXMSStream.Truncate; assembler;
asm
        XOR     AX,AX
        MOV     DX,XMM_Entry.Word[0]
        OR      DX,XMM_Entry.Word[2]
        JZ      @@Error

        LES     DI,Self
        CMP     ES:[DI].TXMSStream.Status,0
        JNE     @@Exit

        MOV     AX,ES:[DI].TXMSStream.Position.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Position.Word[2]
        MOV     ES:[DI].TXMSStream.Size.Word[0],AX
        MOV     ES:[DI].TXMSStream.Size.Word[2],DX

        MOV     CX,1024
        DIV     CX
        OR      DX,DX
        JZ      @@1
        INC     AX   {реальный размер потока, Kb}
@@1:
        MOV     CX,ES:[DI].TXMSStream.Delta
        ADD     CX,AX
        JC      @@Exit
        CMP     CX,ES:[DI].TXMSStream.XMSSize
        JNB     @@Exit
        MOV     DX,ES:[DI].TXMSStream.Handle
        MOV     BX,AX   {если Size+Delta<XMSSize то XMSSize:=Size}
        MOV     AH,0Fh
        CALL    XMM_Entry
        OR      AX,AX
        MOV     AL,BL
        JNZ     @@Exit
@@Error:MOV     DX,stError
        CALL    DoStreamError
@@Exit:
end;

procedure TXMSStream.Write(var Buf; Count: Word); assembler;
 var MoveStruct:TXMSMoveStruct;
asm
        MOV     AX,XMM_Entry.Word[0]
        OR      AX,XMM_Entry.Word[2]
        JZ      @@Error
        LES     DI,Self
        CMP     ES:[DI].TXMSStream.Status,0
        JNE     @@Exit
{загружаем текущую позицию}
        MOV     AX,ES:[DI].TXMSStream.Position.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Position.Word[2]
{выравниваем Count до четного числа}
        MOV     CX,Count
        TEST    CL,1
        JZ      @@7
        INC     CX
@@7:
        ADD     AX,CX
        ADC     DX,0

{проверка на превышение памяти, отведенной в XMS (DX:AX = Position+Count)}
{Определяем число Kb}
        ADD     AX,1024-1  {: AX:=DX:AX/1024 with round}
        ADC     DX,0
        MOV     AL,AH
        MOV     AH,DL
        MOV     DL,DH      {MOV  SI,1024}
        SHR     DL,1       {DIV  SI}
        RCR     AX,1       {OR   DX,DX}
        SHR     DL,1       {JZ   @@3}
        RCR     AX,1       {INC  AX}
        OR      DL,DL      {@@3:}
        JNZ     @@Error

        MOV     BX,ES:[DI].TXMSStream.XMSSize
        CMP     AX,BX
        JBE     @@Write
@@1:
{надо увеличивать выделенную в XMS память для потока,AX- нужный размер в Kb}
        ADD     BX,ES:[DI].TXMSStream.Delta
        JC      @@Error
        CMP     BX,AX
        JNB     @@2
        MOV     BX,AX
@@2:
        MOV     DX,ES:[DI].TXMSStream.Handle
        MOV     AH,0Fh
        PUSH    BX        {Новый размер выделенной памяти в XMS}
        PUSH    CX        {выровненный Count}
        CALL    XMM_Entry
        POP     CX
        POP     DX
        OR      AX,AX
        MOV     AL,BL
        JZ      @@Error2
        MOV     ES:[DI].TXMSStream.XMSSize,DX
        JMP     @@Write
{ошибка}
@@Error :
        XOR     AX,AX
@@Error2:
        MOV     DX,stWriteError
        CALL    DoStreamError
        JMP     @@Exit
{пишем}
@@Write:
        PUSH    DS
        LDS     SI,Self
        PUSH    SS
        POP     ES
        LEA     DI,MoveStruct
        CLD

        MOV     AX,CX
        STOSW   {Length[0]}
        XOR     AX,AX
        STOSW   {Length[2]}

        STOSW   {SouHandle}

        MOV     AX,Buf.Word[0]
        STOSW   {SouOffset[0]}
        MOV     AX,Buf.Word[2]
        STOSW   {SouOffset[2]}

        MOV     AX,DS:[SI].TXMSStream.Handle
        STOSW   {DstHandle}

        MOV     AX,DS:[SI].TXMSStream.Position.Word[0]
        STOSW   {DstOffset[0]}
        MOV     AX,DS:[SI].TXMSStream.Position.Word[2]
        STOSW   {DstOffset[2]}

        POP     ES
        PUSH    ES

        MOV     AX,SS
        MOV     DS,AX
        LEA     SI,MoveStruct
        MOV     AH,0Bh
         CALL    ES:XMM_Entry
        POP     DS
        LES     DI,Self
        OR      AX,AX
        MOV     AL,BL
        JE      @@Error2
{увеличиваем позицию}
        MOV     AX,Count
        ADD     ES:[DI].TXMSStream.Position.Word[0],AX
        ADC     ES:[DI].TXMSStream.Position.Word[2],0
{увеличиваем при необходимости размер потока}
        MOV     AX,ES:[DI].TXMSStream.Position.Word[0]
        MOV     DX,ES:[DI].TXMSStream.Position.Word[2]
        CMP     DX,ES:[DI].TXMSStream.Size.Word[2]
        JB      @@Exit
        JA      @@6
        CMP     AX,ES:[DI].TXMSStream.Size.Word[0]
        JBE     @@Exit
@@6:    MOV     ES:[DI].TXMSStream.Size.Word[0],AX
        MOV     ES:[DI].TXMSStream.Size.Word[2],DX

@@Exit:
end;

function XMSGetFree:word;assembler;
asm
        MOV     AX,XMM_Entry.Word[0]
        OR      AX,XMM_Entry.Word[2]
        JZ      @@Error
        MOV     AH,08h
        CALL    XMM_Entry
        OR      AX,AX
        JZ      @@Error
        MOV     AX,DX
        JMP     @@Exit
@@Error:
        XOR     AX,AX
@@Exit:
end;

function EMSGetTotal:word;assembler;
asm
         CALL   EMSGetFree
         MOV    AX,DX
end;

function EMSGetFree:word;assembler;
 const Sign:array[0..7]of char='EMMXXXX0';
asm
        MOV     AX,3567h
        INT     21h
        MOV     AX,ES
        OR      AX,BX
        JZ      @@Error
        MOV     DI,10
        MOV     SI,offset Sign
        MOV     CX,8
        CLD
        REPE    CMPSB
        JNE     @@Error
        MOV     AX,4200h
        INT     67H
        OR      AH,AH
        JNZ     @@Error
        SHL     DX,4
        SHL     BX,4
        MOV     AX,BX
        JMP     @@Exit
@@Error:XOR     AX,AX
        XOR     DX,DX
@@Exit:
end;

function CMOSGetTotalSize : Word;
begin
  CMOSGetTotalSize := CMOSGetBaseSize+CMOSGetExtendedSize;
end;

function CMOSGetExtendedSize : Word; assembler;
asm
  mov   al,18h
  out   70h,al
  jmp   @1
@1:
  in    al,71h
  mov   ah,al
  mov   al,17h
  out   70h,al
  jmp   @2
@2:
  in    al,71h
end;

function CMOSGetBaseSize : Word; assembler;
asm
  mov   al,16h
  out   70h,al
  jmp   @1
@1:
  in    al,71h
  mov   ah,al
  mov   al,15h
  out   70h,al
  jmp   @2
@2:
  in    al,71h
end;

begin  {ИНИЦИАЛИЗАЦИЯ МОДУЛЯ}
asm    {определяем наличие XMS }
        MOV     AX,4300h
        INT     2FH
        CMP     AL,80h
        JNE     @@NoXMS
       {определяем точку входа}
        MOV     AX,4310h
        INT     2Fh
        MOV     XMM_Entry.Word[0],BX
        MOV     XMM_Entry.Word[2],ES
@@NoXMS:
end;

End.


