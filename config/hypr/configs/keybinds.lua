local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local terminal    = "ghostty --font-size=16"
local fileManager = "env GSK_RENDERER=ngl nautilus --no-desktop"
local menu        = "walker"
local browser     = "firefox"
local discord     = "discord"
local steam       = "env STEAM_FORCE_DESKTOPUI_SCALING=2.0 steam -compat-force-slr off"

local home       = os.getenv("HOME")
local hyprScript = home .. "/.config/hypr/scripts"
local ewwScript  = home .. "/.config/eww/scripts"

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("loginctl lock-session"))
-- Quickshell image-carousel wallpaper picker (replaced waypaper / walker -m wallpaper):
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("wallpaper-picker"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(steam))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(hyprScript .. "/clipboard.sh copy"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(hyprScript .. "/clipboard.sh paste"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(hyprScript .. "/clipboard.sh cut"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(
  [[ps aux | grep '.[D]iscord-wrapped' && hyprctl dispatch 'hl.dsp.workspace.toggle_special("discord")' || ]] .. discord))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind("CONTROL + ALT + V", hl.dsp.exec_cmd("walker -m clipboard"))

hl.bind(mainMod .. " + CONTROL + 3", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + CONTROL + 4", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + CONTROL + 5", hl.dsp.exec_cmd(hyprScript .. "/screenrecord.sh"))
hl.bind(mainMod .. " + CONTROL + 6", hl.dsp.exec_cmd(hyprScript .. "/screenrecord.sh slurp"))
hl.bind(mainMod .. " + CONTROL + 7", hl.dsp.exec_cmd(hyprScript .. "/wallpaper-video.sh"))

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd(hyprScript .. "/pip.sh"))
hl.bind(mainMod .. " + CONTROL + H", hl.dsp.exec_cmd(hyprScript .. "/hdr-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && eww reload"))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.swap({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9], move the active window with SHIFT.
-- Workspace 10 lives on the 0 key.
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + G",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(ewwScript .. "/volume-osd.sh raise"),        { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(ewwScript .. "/volume-osd.sh lower"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(ewwScript .. "/volume-osd.sh mute"),         { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"),         { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"),         { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
