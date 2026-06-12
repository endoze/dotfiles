-- jjsigns highlight groups. fg-only so signs don't paint a background block.

local api = vim.api

local config = require("jjsigns.config")

local M = {}

--- Resolve the JJSigns* highlight groups, preferring Neovim's standard diff fg
--- groups, then diff-mode groups, then a hardcoded fallback.
function M.apply()
  if not config.auto_highlight then
    return
  end

  local map = {
    JJSignsAdd = { "Added", "DiffAdd", "#587c0c" },
    JJSignsChange = { "Changed", "DiffChange", "#0c7d9d" },
    JJSignsDelete = { "Removed", "DiffDelete", "#94151b" },
  }

  for name, spec in pairs(map) do
    local done = false

    for i = 1, 2 do
      if vim.fn.hlexists(spec[i]) == 1 then
        local h = api.nvim_get_hl(0, { name = spec[i], link = false })

        if h and h.fg then
          api.nvim_set_hl(0, name, { fg = h.fg })

          done = true
          break
        end
      end
    end

    if not done then
      api.nvim_set_hl(0, name, { fg = spec[3] })
    end
  end
end

return M
