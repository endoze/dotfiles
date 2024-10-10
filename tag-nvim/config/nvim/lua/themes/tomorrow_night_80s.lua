local M = {}

-- let s:foreground = "#cccccc"
-- let s:background = "#2d2d2d"
-- let s:selection = "#515151"
-- let s:line = "#393939"
-- let s:comment = "#999999"
-- let s:red = "#f2777a"
-- let s:orange = "#f99157"
-- let s:yellow = "#ffcc66"
-- let s:green = "#99cc99"
-- let s:aqua = "#009999"
-- let s:blue = "#99cccc"
-- let s:purple = "#cc99cc"
-- let s:window = "#4d5057"

M.base_16 = {
  base00 = "#2d2d2d", -- controls neovim background
  base01 = "#393939",
  base02 = "#515151",
  base03 = "#999999",
  base04 = "#b4b7b4",
  base05 = "#cccccc",
  base06 = "#e0e0e0",
  base07 = "#ffffff",
  base08 = "#f2777a",
  base09 = "#f99157",
  base0A = "#ffcc66",
  base0B = "#99cc99",
  base0C = "#009999",
  base0D = "#99cccc",
  base0E = "#cc99cc",
  base0F = "#a3685a",
}

M.base_30 = {
  white = "#cccccc",
  darker_black = "#393939", -- plugin background background color
  black = "#2d2d2d", -- current tab color
  black2 = "#4d5057", -- cursor highlight and tab background
  one_bg = "#999999",
  one_bg2 = "#b4b7b4",
  one_bg3 = "#cccccc",
  grey = "#999999",
  grey_fg = "#b4b7b4",
  grey_fg2 = "#cccccc",
  light_grey = "#e0e0e0",
  red = "#f2777a",
  baby_pink = "#cc99cc",
  pink = "#cc99cc",
  line = "#393939",
  green = "#99cc99",
  vibrant_green = "#99cc99",
  blue = "#99cccc",
  nord_blue = "#99cccc",
  yellow = "#ffcc66",
  sun = "#ffcc66",
  purple = "#cc99cc",
  dark_purple = "#cc99cc",
  teal = "#009999",
  orange = "#f99157",
  cyan = "#66cccc",
  statusline_bg = "#515151", -- vim status bar at bottom
  lightbg = "#cccccc",
  pmenu_bg = "#cc99cc",
  folder_bg = "#99cccc",
}

M.type = "dark"

M = require("base46").override_theme(M, "tomorrow_night_80s")

M.polish_hl = {
  St_NormalMode = {
    bg = M.base_30.line,
  },
  St_cwd = {
    bg = M.base_30.line,
  },
  St_InsertMode = {
    bg = M.base_30.line,
  },
  St_VisualMode = {
    bg = M.base_30.line,
  },
  St_Terminal = {
    bg = M.base_30.line,
  },
  St_NTerminal = {
    bg = M.base_30.line,
  },
  St_Replace = {
    bg = M.base_30.line,
  },
  St_Confirm = {
    bg = M.base_30.line,
  },
  St_Command = {
    bg = M.base_30.line,
  },
  St_Select = {
    bg = M.base_30.line,
  },
}

return M
