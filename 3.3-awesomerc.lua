-- Awesome git config // elstupidosawesome at gmail dot com
 io.stderr:write("\n\rAwesome loaded at "..os.date("%B %d, %H:%M").."\r\n\n")

-- Load libraries
require("awful")
require("beautiful")
require("naughty")

-- {{{ Variable definitions
theme_path = awful.util.getdir('config')..'/themes/grey/theme.lua' 
beautiful.init(theme_path)
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"
use_titlebar = false

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating
}

-- Table of clients that should be set floating. The index may be either
-- the application class or instance. The instance is useful when running
-- a console app in a terminal like (Music on Console)
--    xterm -name mocp -e mocp
floatapps =
{
    -- by class
    ["MPlayer"] = true,
    ["gimp"] = true,
    -- by instance
    ["mocp"] = true
}

-- Applications to be moved to a pre-defined tag by class or instance.
-- Use the screen and tags indices.
apptags =
{
    ["Vimpression"  ] = { screen = 1, tag = 2 }, 
    ["Shiretoko"] = { screen = 1, tag = 2 },
}

-- }}}

-- {{{ Tags
-- Define tags table.
tags = {}
tag_properties = { { name = "main",   layout = layouts[1]                           },
                   { name = "www" ,   layout = layouts[1], nmaster = 1              },
                   { name = "dev" ,   layout = layouts[1], mwfact = 0.61, ncols = 2 },
                   { name = "ssh" ,   layout = layouts[1]                           },
                   { name = "misc",   layout = layouts[10], nmaster = 0             }
                 }
 
for s = 1, screen.count() do
    tags[s] = {}
    for i, v in ipairs(tag_properties) do
        tags[s][i] = tag(v.name)
        tags[s][i].screen = s
        awful.tag.setproperty(tags[s][i], "layout", v.layout)
        awful.tag.setproperty(tags[s][i], "mwfact", v.mwfact)
        awful.tag.setproperty(tags[s][i], "nmaster", v.nmaster)
        awful.tag.setproperty(tags[s][i], "ncols", v.ncols)
        awful.tag.setproperty(tags[s][i], "icon", v.icon)
    end
    tags[s][1].selected = true
end

-- }}}

-- {{{ Markup
function set_foreground(fgcolor, text)
    if text ~= nil then
        return '<span color="'..fgcolor..'">'..text..'</span>'
    end
end
 
function set_focus_foreground(text)
    if text ~= nil then
        return set_foreground(beautiful.fg_focus, text)
    end
end

function setFg(color, text)
    return '<span color="'..color..'">'..text..'</span>'
end

function set_bg(bgcolor, text)
    if text then return '<span background="'..bgcolor..'">'..text..'</span>' end
end
 
function set_fg(fgcolor, text)
    if text then return '<span color="'..fgcolor..'">'..text..'</span>' end
end
-- }}}

-- {{{ Widgets
-- Spacers
spacer = " "
awesome_version = widget({ type = "textbox", name = "spacer_l", align = "left" })
awesome_version.text = spacer..set_focus_foreground(" | <b><small> " .. awesome.release .. " </small></b> | ")
spacer_r = widget({ type = "textbox", name = "spacer_r", align = "right" })
spacer_r.text = "  "

function escape(text)
    return awful.util.escape(text or 'nil')
end

-- Read process
function pread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.popen(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            print(err)
        end
    end
end
 
-- Read file
function fread(cmd)
    if cmd and cmd ~= '' then
        local f, err = io.open(cmd, 'r')
        if f then
            local s = f:read('*all')
            f:close()
            return s
        else
            print(err)
        end
    end
end

-- Loadavg Function
function loadavg(widget)
    local palette =
    {
        "#888888",
        "#999988",
        "#AAAA88",
        "#BBBB88",
        "#CCCC88",
        "#CCBB88",
        "#CCAA88",
        "#DD9988",
        "#EE8888",
        "#FF4444",
    }
    local txt = fread('/proc/loadavg')
    if type(txt) == 'string' then
        local one, five, ten = txt:match('^([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)%s+')
        if type(one) == 'string' then
            loadtext = string.format('%.2f %.2f %.2f', one, five, ten)
        end
        local current_avg = tonumber(one)
        if type(current_avg) == 'number' then
            local index = math.min(math.floor(current_avg * (#palette-1)) + 1, #palette)
            color = palette[index]
        end
    end
 
    widget.text = spacer..set_fg(color, loadtext)..set_fg('#4C4C4C', ' |')
end

-- Create Loadavg textbox widget
loadbox = widget({ type = 'textbox', align = 'right' })

-- Cpu/Temp Function
function cpu(widget)
    local temperature, howmany = 0, 0
    local sensors = io.popen('sensors')
    if sensors then
        for line in sensors:lines() do
            if line:match(':%s+%+([.%d]+)') then
                howmany = howmany + 1
                temperature = temperature + tonumber(line:match(':%s+%+([.%d]+)'))
            end
        end
        sensors:close()
    end
    temperature = temperature / howmany
 
    local freq, gov = {}, {}
    for i = 0, 1 do
        freq[i] = fread('/sys/devices/system/cpu/cpu'..i..'/cpufreq/scaling_cur_freq'):match('(.*)000')
        gov[i] = fread('/sys/devices/system/cpu/cpu'..i..'/cpufreq/scaling_governor'):gsub("\n", '')
    end
 
    widget.text = spacer..freq[1]..'MHz ('..gov[0]..') @ '..temperature..'C'..set_fg('#4C4C4C', ' |')
end

-- Create Cpu/Temp textbox widget
cpubox = widget({ type = 'textbox', align = 'right' })

-- Memory Function 
function memory(widget)
    local memfile = io.open('/proc/meminfo')
    if memfile then
        for line in memfile:lines() do
            if line:match("^MemTotal.*") then
                mem_total = math.floor(tonumber(line:match("(%d+)")) / 1024)
            elseif line:match("^MemFree.*") then
                mem_free = math.floor(tonumber(line:match("(%d+)")) / 1024)
            elseif line:match("^Buffers.*") then
                mem_buffers = math.floor(tonumber(line:match("(%d+)")) / 1024)
            elseif line:match("^Cached.*") then
                mem_cached = math.floor(tonumber(line:match("(%d+)")) / 1024)
            end
        end
    end
    local mem_in_use = mem_total - (mem_free + mem_buffers + mem_cached)
    local mem_usage_percentage = math.floor(mem_in_use / mem_total * 100)
 
    widget.text = spacer..mem_in_use..'mb'..set_fg('#4C4C4C', ' |')
end

-- Create Memory textbox widget
membox = widget({ type = 'textbox', align = 'right' })

-- Clock Function
function clock_info(dateformat, timeformat)
    local date = os.date(dateformat)
    local time = os.date(timeformat)
 
    clockwidget.text = spacer..date..spacer..set_focus_foreground(time)..spacer
end

-- Create Clock textbox widget
clockwidget = widget({ type = "textbox", align = "right" })

-- Volume Function
function volume(widget, mixer)
    local vol = ''
    local txt = pread('amixer get '..mixer)
    if txt:match('%[off%]') then
        vol = 'Mute'
    else
        vol = txt:match('%[(%d+%%)%]')
    end
 
    widget.text = '['..vol..'] '
end

-- Create Volume textbox widget + add mouse wheel buttons for volume control
volbox = widget({ type = 'textbox', align = 'right' })
volbox:buttons({
    button({ }, 1, function () awful.util.spawn("amixer -q sset Master toggle") end),
    button({ }, 4, function () awful.util.spawn("amixer -q sset Master 2dB+")   end),
    button({ }, 5, function () awful.util.spawn("amixer -q sset Master 2dB-")   end)
})

-- Create a systray
mysystray = widget({ type = "systray", align = "right" })

-- }}}

-- {{{ Menu
-- Program Variables
browser1 = "firefox"
browser2 = "vimpression"
dropbox  = "sudo /etc/rc.d/dropboxd start"
fileManager = "pcmanfm"
archmount = "archmount"
archunmount = "archunmount"
adminshutdown = "sudo shutdown -h now"
adminreboot = "sudo reboot"

-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/awesomerc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

powermenu = {
    { "reboot",   adminreboot      },
    { "shutdown", adminshutdown    }
}

adminmenu = {
    { "mnt arch",    archmount     },
    { "umnt arch",   archunmount   },
    { "power",       powermenu     }
}

netmenu = { 
    { "firefox", browser1 },
    { "vimpression", browser2 }
}

mymainmenu = awful.menu.new({ items = { { "awesome",   myawesomemenu },
                                        { "net apps",  netmenu       },
                                        { "admin",     adminmenu     },
                                        { "dropbox",   dropbox       },
                                        { "pcmanfm",   fileManager   },
                                        { "terminal",  terminal      }
                                      }
                            })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}
                                     
-- {{{ Wibox
-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, function (tag) tag.selected = not tag.selected end),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ align = "left" })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s, { align = "right" })
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.noempty, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", fg = beautiful.fg_normal, bg = beautiful.bg_normal, screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = { mytaglist[s], 
                           awesome_version,
                           mytasklist[s],
                           mypromptbox[s],
                           cpubox,
                           loadbox,
                           membox,
                           clockwidget,
                           volbox,
                           s == 1 and mysystray or nil, 
                           mylayoutbox[s] }
    mywibox[s].screen = s
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus( 1)       end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus(-1)       end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

-- Client awful tagging: this is useful to tag some clients and then do stuff like move to tag on them
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey }, "t", awful.client.togglemarked),
    awful.key({ modkey,}, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, i,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, i,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          tags[screen][i].selected = not tags[screen][i].selected
                      end
                  end),
        awful.key({ modkey, "Shift" }, i,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, i,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "F" .. i,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          for k, c in pairs(awful.client.getmarked()) do
                              awful.client.movetotag(tags[screen][i], c)
                          end
                      end
                   end))
end

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Hooks
-- Hook function to execute when focusing a client.
awful.hooks.focus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_focus
    end
end)

-- Hook function to execute when unfocusing a client.
awful.hooks.unfocus.register(function (c)
    if not awful.client.ismarked(c) then
        c.border_color = beautiful.border_normal
    end
end)

-- Hook function to execute when marking a client
awful.hooks.marked.register(function (c)
    c.border_color = beautiful.border_marked
end)

-- Hook function to execute when unmarking a client.
awful.hooks.unmarked.register(function (c)
    c.border_color = beautiful.border_focus
end)

-- Hook function to execute when the mouse enters a client.
awful.hooks.mouse_enter.register(function (c)
    -- Sloppy focus, but disabled for magnifier layout
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- Hook function to execute when a new client appears.
awful.hooks.manage.register(function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for filtered windows (i.e. no dock, etc).
    if not startup and awful.client.focus.filter(c) then
        c.screen = mouse.screen
    end

    if use_titlebar then
        -- Add a titlebar
        awful.titlebar.add(c, { modkey = modkey })
    end
    -- Add mouse bindings
    c:buttons(awful.util.table.join(
        awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
        awful.button({ modkey }, 1, awful.mouse.client.move),
        awful.button({ modkey }, 3, awful.mouse.client.resize)
    ))
    -- New client may not receive focus
    -- if they're not focusable, so set border anyway.
    c.border_width = beautiful.border_width
    c.border_color = beautiful.border_normal

    -- Check if the application should be floating.
    local cls = c.class
    local inst = c.instance
    if floatapps[cls] ~= nil then
        awful.client.floating.set(c, floatapps[cls])
    elseif floatapps[inst] ~= nil then
        awful.client.floating.set(c, floatapps[inst])
    end

    -- Check application->screen/tag mappings.
    local target
    if apptags[cls] then
        target = apptags[cls]
    elseif apptags[inst] then
        target = apptags[inst]
    end
    if target then
        c.screen = target.screen
        awful.client.movetotag(tags[target.screen][target.tag], c)
    end

    -- Do this after tag mapping, so you don't see it on the wrong tag for a split second.
    client.focus = c

    -- Set key bindings
    c:keys(clientkeys)

    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
     awful.client.setslave(c)
    
    -- New floating windows don't cover the statusbar and don't overlap until it's unavoidable
     awful.placement.no_offscreen(c)

    -- Honor size hints: if you want to drop the gaps between windows, set this to false.
     c.size_hints_honor = false
end)

-- Hook function to execute when switching tag selection.
awful.hooks.tags.register(function (screen, tag, view)
    -- Give focus to the latest client in history if no window has focus
    -- or if the current window is a desktop or a dock one.
    if not client.focus or not client.focus:isvisible() then
        local c = awful.client.focus.history.get(screen, 0)
        if c then client.focus = c end
    end
end)

-- Run Widget functions once to display immediately
clock_info("%d.%b.%Y", "%H:%M")
memory(membox)
volume(volbox, 'Master')
cpu(cpubox)
loadavg(loadbox)

-- Update Widgets
-- 60 seconds
awful.hooks.timer.register(60, function ()
    clock_info("%d.%b.%Y", "%H:%M")
end)

-- 20 seconds
awful.hooks.timer.register(20, function ()
    memory(membox)
    volume(volbox, 'Master')
end)

-- 10 seconds
awful.hooks.timer.register(10, function ()
    cpu(cpubox)
    loadavg(loadbox)
end)
-- }}} 
