-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
hl.window_rule({
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

hl.window_rule({
  match      = { class = "^(steam_app_)(.*)$" },
  fullscreen = true,
  workspace  = "4 silent",
})

hl.window_rule({ match = { class = "^(steam)$" }, workspace = "3 silent" })

-- Sushi (GNOME file previewer) - float and center with nice styling
hl.window_rule({
  match   = { class = "^(org.gnome.NautilusPreviewer)$" },
  float   = true,
  center  = true,
  size    = { 1200, 800 },
  opacity = "0.95",
})

hl.window_rule({
  match     = { class = "^(discord)$" },
  float     = true,
  center    = true,
  size      = { 1450, 850 },
  workspace = "special:discord silent",
})

-- cliamp (ghostty music player) - float, centered, on its own special workspace.
-- No `silent` here: the first keypress should launch *and* reveal it.
hl.window_rule({
  match     = { class = "^(com\\.endoze\\.cliamp)$" },
  float     = true,
  center    = true,
  size      = { 1100, 700 },
  workspace = "special:cliamp",
})

-- Waydroid (Android) - float, centered, on its own special workspace.
-- Like cliamp, no `silent`: launching it should also reveal it.
--
-- persist.waydroid.width/height are deliberately unset in waydroid.cfg, so the
-- Android guest renders at whatever size this rule gives the window. Change
-- `size` alone and the guest follows; there is no second number to keep in sync.
hl.window_rule({
  match     = { class = "^(Waydroid)$" },
  float     = true,
  center    = true,
  size      = { 1280, 800 },
  workspace = "special:waydroid",
})

-- qs-wallpaper-picker (Quickshell) - borderless, floating, centered
hl.window_rule({
  match       = { title = "^(wallpaper-picker)$" },
  float       = true,
  center      = true,
  border_size = 0,
  rounding    = 0,
  no_blur     = true,
  no_shadow   = true,
})

-- Tweaks to work with blur -----------------------------------
hl.layer_rule({ match = { namespace = "eww-bar" }, blur = true, ignore_alpha = 0.5 })
