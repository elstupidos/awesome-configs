-- Load Libraries
require("awful")
require("awful.autofocus")
require("awful.rules")
require("beautiful")
require("naughty")
require("obvious.volume_alsa")

-- {{{ Variable definitions
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
theme_path = awful.util.getdir('config')..'/themes/grey/theme.lua' 
beautiful.init(theme_path)
modkey = "Mod4"

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
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({"main", "www", "dev", 4, 5, 6, 7, "ssh", "misc" }, s, layouts[1])
end
-- }}}

-- {{{ Functions | Widgets | Timers 
spacer = " "

-- Markup 
function set_fg(fgcolor, text)
    if text then return '<span color="'..fgcolor..'">'..text..'</span>' end
end

-- Textbox widget
textboxes = {}
function textbox(content)
    for k, v in ipairs(textboxes) do
        if v.text == content then
            return v
        end
    end
    local w = widget({ type = "textbox" })
    w.text = content
    table.insert(textboxes, w)
    return w
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

-- Create textbox widgets to be added to wibox
membox   = widget({ type = 'textbox' })
loadbox  = widget({ type = 'textbox' })
cpubox   = widget({ type = 'textbox' })

-- Run functions once to display in textbox widgets
memory(membox)
loadavg(loadbox)
cpu(cpubox)

-- Update Widgets every 20 secs / 10 secs
function hook_20s ()
    memory(membox)
end
hook_20s()

function hook_10s ()
    loadavg(loadbox)
    cpu(cpubox)
end
hook_10s()

-- Timers
timers = {
  { t = 10,    f = hook_10s   },
  { t = 20,    f = hook_20s   },
}

for _, tmr in ipairs(timers) do
  timers.timer = timer({ timeout = tmr.t })
  timers.timer:add_signal("timeout", tmr.f)
  timers.timer:start()
end

-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/awesomerc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
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
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mytaglist[s],
            textbox(spacer..set_fg('#ffffff', " | manhattan |  "..spacer)),
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        s == 1 and mysystray or nil, textbox(" "),
        obvious.volume_alsa():set_layout(awful.widget.layout.horizontal.rightleft), 
        textbox("  "), mytextclock,
        membox, loadbox, s == 1 and cpubox,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
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
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
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
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
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
                          awful.tag.viewtoggle(tags[screen][i])
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
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { instance = "Shiretoko" },
      properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- If we are not managing this application at startup,
    -- move it to the screen where the mouse is.
    -- We only do it for filtered windows (i.e. no dock, etc).
    if not startup and awful.client.focus.filter(c) then
        c.screen = mouse.screen
    end

    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
     awful.client.setslave(c)
 
    -- New floating windows don't cover the statusbar and don't overlap until it's unavoidable
     awful.placement.no_offscreen(c)
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
