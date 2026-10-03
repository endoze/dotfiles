-- Hyprland configuration. API stubs: /run/current-system/sw/share/hypr/stubs.
-- Each require() below is its own Lua scope: an error in one file does not stop
-- the others from loading.

------------------
---- MONITORS ----
------------------

hl.monitor({
  output = "desc:Acer Technologies Acer X27 #ASOSpDuqCRrd",
  mode = "3840x2160@144",
  position = "0x0",
  scale = 1.33,
})

-- Fallback rule for anything else that gets plugged in.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

require("configs/env")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
  ecosystem = {
    enforce_permissions = false,
    no_update_news = true,
    no_donation_nag = true,
  },

  general = {
    gaps_in = 6,
    gaps_out = 12,

    border_size = 0,

    resize_on_border = false,

    allow_tearing = false,

    layout = "dwindle",
  },

  xwayland = {
    force_zero_scaling = true,
  },

  cursor = {
    no_hardware_cursors = true,
  },

  debug = {
    disable_logs = true,
    enable_stdout_logs = true,
  },

  decoration = {
    rounding = 12,

    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = {
      enabled = true,
      range = 30,
      render_power = 4,
      color = "rgba(00000099)",
      offset = { 0, 8 },
    },

    blur = {
      enabled = true,
      size = 8,
      passes = 3,

      vibrancy = 0.3,
      vibrancy_darkness = 0.3,
      noise = 0.015,
      brightness = 0.95,
      contrast = 1.0,

      -- GTK popup menus (eww tray menus) get the same frost as the layers.
      popups = true,
      popups_ignorealpha = 0.5,
    },
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 2,
  },
})

require("configs/startup")
require("configs/keybinds")
require("configs/window")
require("configs/inputs")
require("configs/animations")

