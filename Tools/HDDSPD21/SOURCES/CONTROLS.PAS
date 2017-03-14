{$X+,G+,D-,L-,S-,R-}
unit Controls;

interface

uses Views, Drivers, Dialogs, Service;

type

  PListBox = ^TListBox;
  TListBox = Object(Dialogs.TListBox)
  end;

  PButton = ^TButton;
  TButton = Object(Dialogs.TButton)             {Button with marks}
    procedure   Draw; virtual;
    procedure   HandleEvent(var Event: TEvent); virtual;
  end;

  PCheckBoxes = ^TCheckBoxes;
  TCheckBoxes = Object(Dialogs.TCheckBoxes)
    procedure Draw; virtual;
  end;

  PRadioButtons = ^TRadioButtons;
  TRadioButtons = Object(Dialogs.TRadioButtons)
    procedure Draw; virtual;
  end;

implementation

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                             TButton's Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TButton.Draw;
begin
  inherited Draw;
  If (State and sfSelected <> 0) or AmDefault Then
  begin
    WriteStr(1,0,#16,3); WriteStr(Size.X-2,0,#17,3);
  end;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure   TButton.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (State and sfSelected <> 0) Then
  begin
    case Event.KeyCode of
      kbRight:
        begin
          Owner^.FocusNext(False);
          ClearEvent(Event);
        end;
      kbLeft:
        begin
          Owner^.FocusNext(True);
          ClearEvent(Event);
        end
     end;
   end;
  inherited HandleEvent(Event);
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                          TCheckBoxes's Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TCheckBoxes.Draw;
begin
  If (ConfigData.Global and optLoadFont <> 0) and (ScreenMode and smFont8x8 = 0)
    Then TCluster.DrawMultiBox(' 鹿� ','憧')
    Else inherited Draw;
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
                          TRadioButtons's Methods
 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
procedure TRadioButtons.Draw;
begin
  If (ConfigData.Global and optLoadFont <> 0) and (ScreenMode and smFont8x8 = 0)
    Then TCluster.DrawMultiBox(' 國� ','今')
    Else inherited Draw;
end;

begin
end.
