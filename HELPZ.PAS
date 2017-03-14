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
... and Justice 4 all. (c) MetallicA