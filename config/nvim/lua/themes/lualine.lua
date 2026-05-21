local M = {}

-- Nerd Font icons encoded as raw UTF-8 byte sequences so source stays pure ASCII.
-- Many Private-Use-Area glyphs (U+E000-U+F8FF) survive poorly through tooling that
-- re-encodes files. Escapes guarantee byte fidelity at Lua parse time.
local icons = {
  vim_logo = "\238\159\133",         -- U+E7C5 (nf-dev-vim)
  file_default = "\243\176\136\154", -- U+F021A
  modified = "\239\129\128",         -- U+F040
  readonly = "\239\128\163",         -- U+F023
  branch = "\238\169\168",           -- U+EA68
  diff_added = "\239\129\149",       -- U+F055
  diff_modified = "\239\145\153",    -- U+F459
  diff_removed = "\239\133\134",     -- U+F146
  lsp = "\239\130\133",              -- U+F085
  diag_error = "\239\129\151",       -- U+F057
  diag_warn = "\239\129\177",        -- U+F071
  diag_hint = "\243\176\155\169",    -- U+F06E9
  diag_info = "\243\176\139\188",    -- U+F02FC
  cwd_folder = "\243\176\137\150",   -- U+F0256
}

local mode_color_names = {
  n = "blue",
  no = "blue",
  nov = "blue",
  noV = "blue",
  niI = "blue",
  niR = "blue",
  niV = "blue",
  v = "cyan",
  V = "cyan",
  [""] = "cyan",
  vs = "cyan",
  Vs = "cyan",
  i = "dark_purple",
  ic = "dark_purple",
  ix = "dark_purple",
  t = "green",
  nt = "green",
  R = "orange",
  Rc = "orange",
  Rx = "orange",
  Rv = "orange",
  s = "blue",
  S = "blue",
  c = "green",
  cv = "green",
  ce = "green",
  cr = "green",
  ["!"] = "green",
  r = "teal",
  rm = "teal",
  ["r?"] = "teal",
  x = "teal",
}

local mode_text = {
  n = "NORMAL",
  no = "NORMAL",
  nov = "NORMAL",
  noV = "NORMAL",
  niI = "NORMAL i",
  niR = "NORMAL r",
  niV = "NORMAL v",
  nt = "NTERMINAL",
  v = "VISUAL",
  V = "V-LINE",
  [""] = "V-BLOCK",
  vs = "V-CHAR (Ctrl O)",
  Vs = "V-LINE",
  i = "INSERT",
  ic = "INSERT",
  ix = "INSERT",
  t = "TERMINAL",
  R = "REPLACE",
  Rv = "V-REPLACE",
  s = "SELECT",
  S = "S-LINE",
  c = "COMMAND",
  r = "PROMPT",
  rm = "MORE",
  ["r?"] = "CONFIRM",
  x = "CONFIRM",
  ["!"] = "SHELL",
}

function M.opts()
  local p = require("base46").get_theme_tb("base_30")

  local mode = {
    function()
      local m = vim.api.nvim_get_mode().mode
      return " " .. icons.vim_logo .. " " .. (mode_text[m] or m:upper()) .. " "
    end,
    color = function()
      local m = vim.api.nvim_get_mode().mode
      local key = mode_color_names[m] or "blue"
      return { fg = p[key], bg = p.one_bg3, gui = "bold" }
    end,
    padding = 0,
  }

  local file = {
    function()
      local path = vim.api.nvim_buf_get_name(0)
      local name = (path == "" and "Empty") or path:match("([^/\\]+)[/\\]*$")
      local icon = icons.file_default
      if name ~= "Empty" then
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
          local ft_icon = devicons.get_icon(name)
          icon = ft_icon ~= nil and ft_icon or icon
        end
      end
      local mod = vim.bo.modified and (" " .. icons.modified) or ""
      local ro = (vim.bo.readonly or not vim.bo.modifiable) and not vim.bo.modified
          and (" " .. icons.readonly)
        or ""
      return icon .. " " .. name .. mod .. ro
    end,
    color = { fg = p.light_grey, bg = p.statusline_bg },
    padding = { left = 1, right = 1 },
  }

  local branch = {
    "branch",
    icon = icons.branch,
    color = { fg = p.light_grey, bg = p.statusline_bg },
  }

  local diff = {
    "diff",
    symbols = {
      added = " " .. icons.diff_added .. " ",
      modified = " " .. icons.diff_modified .. " ",
      removed = " " .. icons.diff_removed .. " ",
    },
    diff_color = {
      added = { fg = p.green, bg = p.statusline_bg },
      modified = { fg = p.yellow, bg = p.statusline_bg },
      removed = { fg = p.red, bg = p.statusline_bg },
    },
  }

  local lsp_msg = {
    function()
      if vim.o.columns < 120 then
        return ""
      end
      return vim.lsp.status()
    end,
    color = { fg = p.red, bg = p.statusline_bg },
  }

  local diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = {
      error = icons.diag_error .. " ",
      warn = icons.diag_warn .. " ",
      info = icons.diag_info .. " ",
      hint = icons.diag_hint .. " ",
    },
    diagnostics_color = {
      error = { fg = p.red, bg = p.statusline_bg },
      warn = { fg = p.yellow, bg = p.statusline_bg },
      info = { fg = p.blue, bg = p.statusline_bg },
      hint = { fg = p.purple, bg = p.statusline_bg },
    },
  }

  local lsp = {
    function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients == 0 then
        return ""
      end
      local names = {}
      for _, c in ipairs(clients) do
        table.insert(names, c.name)
      end
      if vim.o.columns > 100 then
        return " " .. icons.lsp .. " LSP ~ " .. table.concat(names, ",")
      end
      return " " .. icons.lsp .. " LSP"
    end,
    color = { fg = p.green, bg = p.statusline_bg },
  }

  local cursor = {
    function()
      return string.format("Ln %d, Col %d", vim.fn.line("."), vim.fn.col("."))
    end,
    color = { fg = p.light_grey, bg = p.statusline_bg },
    padding = { left = 1, right = 1 },
  }

  local progress = {
    "progress",
    color = { fg = p.light_grey, bg = p.statusline_bg },
    padding = { left = 0, right = 1 },
  }

  local cwd = {
    function()
      if vim.o.columns <= 85 then
        return ""
      end
      return icons.cwd_folder .. " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    end,
    color = { fg = p.red, bg = p.one_bg3 },
    padding = { left = 1, right = 1 },
  }

  local flat = {
    a = { fg = p.light_grey, bg = p.statusline_bg },
    b = { fg = p.light_grey, bg = p.statusline_bg },
    c = { fg = p.light_grey, bg = p.statusline_bg },
  }

  return {
    options = {
      theme = {
        normal = flat,
        insert = flat,
        visual = flat,
        replace = flat,
        command = flat,
        inactive = flat,
      },
      component_separators = "",
      section_separators = "",
      globalstatus = true,
      disabled_filetypes = { statusline = { "NvimTree", "dashboard" } },
    },
    sections = {
      lualine_a = { mode },
      lualine_b = { file },
      lualine_c = { branch, diff },
      lualine_x = { lsp_msg, diagnostics, lsp },
      lualine_y = { cursor, progress },
      lualine_z = { cwd },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { file },
      lualine_x = { cursor, progress },
      lualine_y = {},
      lualine_z = {},
    },
  }
end

return M
