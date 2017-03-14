{$X+,G+,D-,L-,S-,R-}
unit Graphics;

interface

uses Crt, Timer, Service, Tests, IDE, VGA, {GrabPCX,} GIF;

const
  lsRead   = 0;
  lsWrite  = 1;
  lsVerify = 2;

{ PicExt   = '.PCX'; }
  PicExt   = '.GIF';

procedure DrawLinearSpeedGraph(Drv : PTestDrive; GraphType : Word; Shuttle : Boolean);
procedure DrawCacheGraph(Drv : PTestDrive);

implementation

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure DrawLinearSpeedGraph(Drv : PTestDrive; GraphType : Word; Shuttle : Boolean);
const
  Title : Array [0..2] of String[8] = ('Read', 'Write', 'Verify');
  FileName : Array [0..2] of String[8] = ('TrkRead', 'TrkWrite', 'TrkVerif');

type
   TTrackRec = Record
     Speed  : Word;
     Status : Integer;
   end;
var
  Y, OldY, i, j, k  : LongInt;
  Size, Time, TimerTicks, Speed, Speed2, TotalSpeed : LongInt;
  MinSpeed, MaxSpeed, AvgSpeed : Word;
  Key : Word;
  DetailedGraph : Boolean;

  DropDown, RemapsCount, BadTracks : Integer;
  Track : Array [-1..1023] of TTrackRec;

  F    : Text;
  Data : File;
  S    : String[40];

  YScale,
  XScale,
  XShift     : Integer;
  GraphColor : Integer;

begin
  If Drv = Nil Then Exit;
  With Drv^ do
  begin
    Size := 512*LongInt(Heads)*LongInt(Sectors);
    MinSpeed := $FFFF; MaxSpeed := 0; AvgSpeed := 0; TotalSpeed := 0;
    SkipTest := False;

    Case GraphType of
      0 : begin
            Speed := GetTrackLinearReadSpeed(3, 1, False);
            GraphColor := LightGreen;
          end;
      1 : begin
            Speed := GetTrackLinearReadSpeed(3, 1, False);
            GraphColor := LightCyan;
          end;
      2 : begin
            Speed := GetTrackLinearVerifySpeed(3, 1, False);
            GraphColor := Yellow;
          end;
    end;
    YScale := 256*(Speed div 2048+1);

    DetailedGraph := ConfigData.Global and optDetailedGraph <> 0;

    TextAttr := LightCyan;
    DirectVideo := False;
    SetMode($12);
    {vert. line}
    SetCursorPos(70,30); Write('Track');
    If DetailedGraph Then XScale := 50
                     Else XScale := 100;
    for i := 0 to 11 do
    begin
      Line(45+i*50,29,45+i*50,479,LightGray);
      If i in [1..10] Then
      begin
        SetCursorPos(5+i*6,30); System.Write(i*XScale);
        If DetailedGraph Then
        begin
          SetCursorPos(5+i*6,29);
          System.Write((10+i)*XScale);
        end;
      end;
    end;
    {horiz. line}
    SetCursorPos(1,2); Write('MB/sec.');
    for i := 0 to 9 do
    begin
      Line(45,479-i*50,550+45,479-i*50,LightGray);
      SetCursorPos(1,30-i*3); System.Write((YScale/1024)*i :5:2);
    end;
    Line(45,479,45+(Tracks-1) div 2,479,White);

    If TypeOf(Drv^) = TypeOf(TIDEDrive) Then
    begin
      TextAttr := White;
      S := Drv^.GetModel;
      GoToXY(74-Length(S),3); WriteLn(S);
    end;
    TextAttr := LightGreen;
    If DetailedGraph
    Then
      begin
        GoToXY(30,1);
        WriteLn('ùþ Linear '+Title[GraphType]+' Speed þù');
      end
    Else
      begin
        GoToXY(25,1);
        WriteLn('ùþ Linear '+Title[GraphType]+' Speed (Draft) þù');
      end;
    TextAttr := Yellow;

    OldY := 0;
    XShift := 46;

    for I := 0 to Tracks-1 do
    begin
      If SkipTest Then Break;
      ResetStatus;

      Case GraphType of
        0 : Speed := GetTrackLinearReadSpeed(I, 1, Shuttle);
        1 : Speed := GetTrackLinearWriteSpeed(I, 1, Shuttle);
        2 : Speed := GetTrackLinearVerifySpeed(I, 1, Shuttle);
      end;

      Track[i].Speed := Word(Speed);
      Track[i].Status := LastError;

      Inc(TotalSpeed, Speed);

      AvgSpeed := TotalSpeed div (i+1);
      If Speed < MinSpeed Then MinSpeed := Speed;
      If Speed > MaxSpeed Then MaxSpeed := Speed;

      Case DetailedGraph of
        False : begin
                  If Odd(I) Then
                  begin
                    Speed2 := Round((Track[i-1].Speed+Track[i].Speed)/2);
                    Y := 479-Round(50*Speed2/YScale);
                    If OldY = 0 Then OldY := Y;
                    If LastError = 0 Then Line(XShift + I div 2 - 1, OldY, XShift + I div 2, Y, GraphColor)
                                     Else Line(XShift + I div 2 - 1, OldY, XShift + I div 2, Y, LightRed);
                    OldY := Y;
                  end;
                end;
        True  : begin
                  If I > 500 Then
                  begin
                    XShift := 46-500;
                    GraphColor := LightBlue;
                  end;

                  Y := 479-Round(50*Speed/YScale);
                  If OldY = 0 Then OldY := Y;
                  If LastError = 0 Then Line(XShift + I - 1, OldY, XShift + I, Y, GraphColor)
                                   Else Line(XShift + I - 1, OldY, XShift + I, Y, LightRed);
                  OldY := Y;
                end;
        end;

     GoToXY(59,4); System.Write('Max: ',MaxSpeed/1024:2:1,' MB/sec');
     GoToXY(59,5); System.Write('Min: ',MinSpeed/1024:2:1,' MB/sec');
     GoToXY(59,6); System.Write('Avg: ',AvgSpeed/1024:2:1,' MB/sec');
     SetCursorPos(71,29); System.Write(Round(I/(Tracks-1)*100):3,'%');
     If LastError = 0 Then PutPixel(45+I div 2, 479, GraphColor)
                      Else PutPixel(45+I div 2, 479, LightRed);
    end;

    If ConfigData.Global and optKeepTracksLog <> 0 Then
    begin
      Track[-1] := Track[0];
      Assign(F, FileName[GraphType]+'.log'); Rewrite(F);
      WriteLn(F, Separator(Title[GraphType]+' log')+#10#13);

      RemapsCount := 0; BadTracks := 0;
      If SkipTest Then Dec(i);
      for j := 0 to i do
      begin
        S := '';
         If Track[j].Status <> 0
        Then begin
                 S := ' - Error '+WordToHexStr(Track[j].Status)+': '+GetErrorMessage(Track[j].Status);
                 Inc(BadTracks);
              end
        Else begin
          DropDown := Track[j-1].Speed-Track[j].Speed;
          If DropDown >= Track[j].Speed div 10
            Then begin S := ' - Remapped track?'; Inc(RemapsCount) end
            Else If DropDown >= 1024
                    Then S := ' *';
        end;

        System.WriteLn(F, j:4, ' - ', IntToStr(Track[j].Speed):5, ' KB/sec. (',
                        -DropDown :5,' KB/sec., ',Round(-DropDown/Track[j-1].Speed*100):3,'%) ',S);
      end;
      WriteLn(F, #13#10+Separator(Title[GraphType]+' summary')+#13#10);
      WriteLn(F, '              Bad tracks: ', BadTracks);
      WriteLn(F, 'Possible remapped tracks: ', RemapsCount);
      Close(F);

      Assign(Data, FileName[GraphType]+'.dat'); Rewrite(Data, 1);
      BlockWrite(Data, Track[0], (i+1)*2);
      Close(Data);
    end;

    While KeyPressed do ReadKey;
    TextAttr := LightRed; GoToXY(14,2); WriteLn('<< Press F2 to save '+PicExt+' or other key to continue >>');
    Key := GetKey;
    If Key = keyF2 Then WriteGIF(FileName[GraphType]+PicExt);
  end;
  SetMode(3);
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
procedure DrawCacheGraph(Drv : PTestDrive);
var
  TimerTicks,
  CacheTime,
  Size,
  CacheSpeed,
  MaxCacheSpeed : LongInt;
  B, I, J, K    : Word;
  Y,OldY,
  BlockSize     : Word;
  LargeBuffer   : Boolean;
  Key           : Word;
  YScale        : Integer;
  S             : String[40];
begin
  If Drv = Nil Then Exit;
  With Drv^ do
  begin
    TextAttr := LightCyan;
    DirectVideo := False;
    SetMode($12);

    for i := 0 to 4 do ReadSectors(0,0,1,128,TestBuffer); {Fill disk buffer}
    TimerTicks := 0;
    for i := 0 to 63 do
    begin
      StartTimer;
      ReadSectors(0,0,1,126,TestBuffer);
      Inc(TimerTicks,ReadTimer);
    end;
    CacheTime := TimerTicks div 1193;
    Size := 512*64*126;
    CacheSpeed := Size div CacheTime;
    YScale := 256*(CacheSpeed div 2048+2);

    {vert. line}
    SetCursorPos(73,30); Write('Size');
    for i := 0 to 9 do
    begin
      Line(44+i*64,29,44+i*64,479,LightGray);
      If i in [1..8] Then begin SetCursorPos(3+i*8,30); System.Write(i*16,'k'); end;
    end;
    {horiz. line}
    SetCursorPos(1,2); Write('MB/sec.');
    for i := 0 to 9 do
    begin
      Line(44,479-i*50,44+576,479-i*50,LightGray);
      If i in [0..9] Then begin SetCursorPos(1,30-i*3); System.Write((YScale/1024)*i :5:2) end;
    end;

    If TypeOf(Drv^) = TypeOf(TIDEDrive) Then
    begin
      TextAttr := White;
      S := Trim(Drv^.GetModel);
      GoToXY(77-Length(S),3); WriteLn(S);
    end;
    TextAttr := Yellow;
    GoToXY(32, 1); WritelN('ùþ Cache Read Speed þù');
    Size := 512*LongInt(Heads)*LongInt(Sectors);
    SkipTest := False;
    SeekToTrack(0);

    MaxCacheSpeed := 0;
    OldY := 479;
    for j := 1 to 32 do            {Read blocks 8k,16k,24k,32k...64k}
    begin
      SkipTest := False;
      for i := 0 to 4 do ReadSectors(0,0,1,j*4,TestBuffer); {Fill disk buffer}
      TimerTicks := 0;
      for i := 0 to 127 do
      begin
        If SkipTest Then Break;
        StartTimer;
        ReadSectors(0,0,1,j*4,TestBuffer);
        Inc(TimerTicks,ReadTimer);
      end;
      If Status = 0 Then
      begin
        CacheTime := TimerTicks div 1193;
        Size := 512*128*LongInt(j*4);
        CacheSpeed := Size div CacheTime;
      end
      Else
      begin
        {CacheSpeed := 0;}
        GoToXY(34,5); System.Write(GetErrorMessage(Status));
      end;

      Y := 479-Round(50*CacheSpeed/YScale);
      Line(44+(j-1)*8,OldY,44+j*8,Y,LightGreen);
      OldY := Y;

      If CacheSpeed >= MaxCacheSpeed Then
      begin
        MaxCacheSpeed := CacheSpeed;
        BlockSize := j*2;
        GoToXY(50,4); System.Write('Max: ',MaxCacheSpeed/1024:2:1,' Mb/sec.('+IntToStr(BlockSize)+'K block)');
      end;

      If SkipTest Then Break;
    end;

    While KeyPressed do ReadKey;
    If {not CompleteTest} True Then
    begin
      TextAttr := LightRed; GoToXY(16,2); WriteLn('<< Press F2 to save '+PicExt+' or other key to exit >>');
      Key := GetKey;
      If Key = keyF2 Then WriteGIF('cache'+PicExt);
    end
    Else WriteGIF('cache'+PicExt);
  end;
  SetMode(3);
end;

begin
end.
