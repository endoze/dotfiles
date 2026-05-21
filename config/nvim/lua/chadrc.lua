-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local options = {
  ui = {
    statusline = { enabled = false },
    tabufline = { enabled = false },
    cmp = {
      style = "default",
    },
  },

  base46 = {
    ---@type ThemeName | "solarized_light" | "tomorrow_night_80s"
    theme = "onedark",
    theme_toggle = { "onedark", "tokyonight" },
    integrations = { "bufferline" },

    hl_add = {
      ["@string.special.symbol"] = {
        fg = "green",
      },
    },

    hl_override = {
      DiagnosticInfo = {
        fg = "#8cf8f7",
      },
    },
    ---@diagnostic disable
    changed_themes = {
      solarized_dark = {
        base_16 = {
          base0B = "#2aa198",
          base0C = "#6c71c4",
          base0E = "#859900",
        },
      },
    },
  },
}

return options
