-- jjsigns configuration: defaults plus the diff-type -> highlight-group map.

local M = {
  signs = {
    add = { text = "┃" },
    change = { text = "┃" },
    delete = { text = "󰍵" },
    topdelete = { text = "▔" },
    changedelete = { text = "󱕖" },
  },
  base = "@-",
  debounce = 100,
  priority = 6,
  hl_group = {
    add = "JJSignsAdd",
    change = "JJSignsChange",
    delete = "JJSignsDelete",
    topdelete = "JJSignsDelete",
    changedelete = "JJSignsChange",
  },

  -- Initial on/off state. When false, no buffers are attached until toggled on.
  enabled = true,

  -- Also tint the line-number column / whole line with the sign's hl group.
  numhl = false,
  linehl = false,

  -- Re-fetch the base for all attached buffers when the terminal regains focus.
  watch_focus = true,

  -- Define the JJSigns* highlight groups automatically. Set false to manage
  -- them yourself.
  auto_highlight = true,

  -- Optional global maps. Set to a lhs string to enable; left false by default.
  keymaps = {
    toggle = false,
    refresh = false,
  },
}

--- Merge user opts into the live config table, in place.
function M.merge(opts)
  local merged = vim.tbl_deep_extend("force", M, opts or {})

  for k, v in pairs(merged) do
    M[k] = v
  end
end

return M
