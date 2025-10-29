-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local options = {
  ui = {
    statusline = {
      theme = "vscode_colored",
      order = {
        "mode",
        "file",
        "git",
        "%=",
        "lsp_msg",
        "%=",
        "diagnostics",
        "lsp",
        "cursor",
        "cwd",
      },
      modules = {
        lsp = function()
          local stbufnr = require("nvchad.stl.utils").stbufnr

          if rawget(vim, "lsp") then
            for _, client in ipairs(vim.lsp.get_clients()) do
              if
                client.attached_buffers[stbufnr()]
                and client.name ~= "null-ls"
                and client.name ~= "copilot"
              then
                return "%#St_Lsp#"
                  .. (
                    (vim.o.columns > 100 and "   LSP ~ " .. client.name .. " ")
                    or "   LSP "
                  )
              end
            end
          end

          return ""
        end,
      },
    },
    tabufline = {
      enabled = true,
      lazyload = true,
      overriden_modules = nil,
    },
    cmp = {
      style = "default",
    },
  },

  base46 = {
    ---@type ThemeName | "solarized_light" | "tomorrow_night_80s"
    theme = "onedark",
    theme_toggle = { "onedark", "tokyonight" },

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
  nvdash = {
    load_on_startup = false, --  not vim.g.vscode,
    header = {
      " ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⠜⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⠿⠿⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⣿⣿ ",
      " ⣿⣿⡏⠁⠀⠀⠀⠀⠀⣀⣠⣤⣤⣶⣶⣶⣶⣶⣦⣤⡄⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣷⣄⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⡧⠇⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣾⣮⣭⣿⡻⣽⣒⠀⣤⣜⣭⠐⢐⣒⠢⢰⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⣏⣿⣿⣿⣿⣿⣿⡟⣾⣿⠂⢈⢿⣷⣞⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣷⣶⣾⡿⠿⣿⠗⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠻⠋⠉⠑⠀⠀⢘⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⣿⡿⠟⢹⣿⣿⡇⢀⣶⣶⠴⠶⠀⠀⢽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⣿⣿⣿⡿⠀⠀⢸⣿⣿⠀⠀⠣⠀⠀⠀⠀⠀⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⣿⣿⣿⡿⠟⠋⠀⠀⠀⠀⠹⣿⣧⣀⠀⠀⠀⠀⡀⣴⠁⢘⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿ ",
      " ⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⠗⠂⠄⠀⣴⡟⠀⠀⡃⠀⠉⠉⠟⡿⣿⣿⣿⣿ ",
      " ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⠾⠛⠂⢹⠀⠀⠀⢡⠀⠀⠀⠀⠀⠙⠛⠿⢿ ",
    },

    buttons = {
      {
        txt = "  Find File",
        keys = "<C-t>",
        cmd = ":lua require('telescope.builtin').find_files({ find_command = { 'rg', '--files' } })",
      },
      {
        txt = "󱔗  Recent Files",
        keys = ", f o",
        cmd = ":lua require('telescope.builtin').oldfiles({prompt_title='Recent Files', only_cwd=true})",
      },
      { txt = "󰈭  Find Word", keys = ", f a", cmd = "Telescope live_grep" },
      { txt = "  Bookmarks", keys = ", b m", cmd = "Telescope marks" },
      { txt = "  Themes", keys = ", t h", cmd = "Telescope themes" },
      {
        txt = "  Settings",
        keys = ", e s",
        cmd = ":e $HOME/.config/nvim/lua/chadrc.lua",
      },
      { txt = "  Mappings", keys = ", c h", cmd = "NvCheatsheet" },
    },
  },
}

return options
