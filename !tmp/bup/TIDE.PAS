uses ide;
var id : pIdeDrive;
begin
  new(id,init(ChannelN[chPrimary],dSlave,mCHS));
  if id<>nil then
  begin
    writeln(id^.GetModel);
    dispose(id{,done});
  end;
end.