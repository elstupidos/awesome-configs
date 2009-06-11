local rc, err = loadfile(os.getenv("HOME").."/.config/awesome/awesomerc.lua");
if rc then
  rc, err = pcall(rc);
  if rc then
    return;
  end
end
 
dofile("/etc/xdg/awesome/rc.lua");
 
for s = 1,screen.count() do
  mypromptbox[s].text = awful.util.escape(err:match("[^\n]*"));
end
 
local f = io.open(os.getenv("HOME").."/.awesome.err", "w+")
f:write("Awesome crashed during startup on ", os.date("%d%/%m/%Y %T:\n\n"))
f:write(err, "\n");
f:close();
 
