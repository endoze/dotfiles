local M = {}

-- SOLARIZED HEX     16/8 TERMCOL  XTERM/HEX   L*A*B      sRGB        HSB
-- --------- ------- ---- -------  ----------- ---------- ----------- -----------
-- base03    #002b36  8/4 brblack  234 #1c1c1c 15 -12 -12   0  43  54 193 100  21
-- base02    #073642  0/4 black    235 #262626 20 -12 -12   7  54  66 192  90  26
-- base01    #586e75 10/7 brgreen  240 #4e4e4e 45 -07 -07  88 110 117 194  25  46
-- base00    #657b83 11/7 bryellow 241 #585858 50 -07 -07 101 123 131 195  23  51
-- base0     #839496 12/6 brblue   244 #808080 60 -06 -03 131 148 150 186  13  59
-- base1     #93a1a1 14/4 brcyan   245 #8a8a8a 65 -05 -02 147 161 161 180   9  63
-- base2     #eee8d5  7/7 white    254 #d7d7af 92 -00  10 238 232 213  44  11  93
-- base3     #fdf6e3 15/7 brwhite  230 #ffffd7 97  00  10 253 246 227  44  10  99
-- yellow    #b58900  3/3 yellow   136 #af8700 60  10  65 181 137   0  45 100  71
-- orange    #cb4b16  9/3 brred    166 #d75f00 50  50  55 203  75  22  18  89  80
-- red       #dc322f  1/1 red      160 #d70000 50  65  45 220  50  47   1  79  86
-- magenta   #d33682  5/5 magenta  125 #af005f 50  65 -05 211  54 130 331  74  83
-- violet    #6c71c4 13/5 brmagenta 61 #5f5faf 50  15 -45 108 113 196 237  45  77
-- blue      #268bd2  4/4 blue      33 #0087ff 55 -10 -45  38 139 210 205  82  82
-- cyan      #2aa198  6/6 cyan      37 #00afaf 60 -35 -05  42 161 152 175  74  63
-- green     #859900  2/2 green     64 #5f8700 60 -20  65 133 153   0  68 100  60

M.base_16 = {
  -- base00 = "#002b36",
  -- base01 = "#073642",
  base01 = "#002b36",
  base00 = "#073642",
  base02 = "#586e75",
  base03 = "#657b83",
  base04 = "#839496",
  base05 = "#93a1a1",
  base06 = "#eee8d5",
  base07 = "#fdf6e3",
  base08 = "#dc322f",
  base09 = "#cb4b16",
  base0A = "#b58900",
  base0B = "#2aa198",
  base0C = "#6c71c4",
  base0D = "#268bd2",
  base0E = "#859900",
  base0F = "#d33682",
}

M.base_30 = {
  white = "#fdf6e3",
  darker_black = "#002b36",
  -- darker_black = "#073642",
  black = "#073642", --  nvim bg
  black2 = "#586e75",
  one_bg = "#657b83",
  one_bg2 = "#839496",
  one_bg3 = "#93a1a1",
  grey = "#586e75",
  grey_fg = "#657b83",
  grey_fg2 = "#839496",
  light_grey = "#93a1a1",
  red = "#dc322f",
  baby_pink = "#b58900",
  pink = "#dc322f",
  line = "#93a1a1", -- for lines like vertsplit
  green = "#859900",
  vibrant_green = "#b7cb32",
  blue = "#268bd2",
  nord_blue = "#268bd2",
  yellow = "#b58900",
  sun = "#b58900",
  purple = "#6c71c4",
  dark_purple = "#b58900",
  teal = "#AEDCB7",
  orange = "#cb4b16",
  cyan = "#2aa198",
  statusline_bg = "#002b36",
  -- statusline_bg = "#073642",
  lightbg = "#93a1a1",
  pmenu_bg = "#ebb9b9",
  folder_bg = "#268bd2",
}

vim.opt.bg = "dark"
M.type = "dark"

M = require("base46").override_theme(M, "solarized-dark")

return M
