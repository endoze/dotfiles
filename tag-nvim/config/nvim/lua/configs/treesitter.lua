local M = {}

M.highlight = {
  enable = true,
  use_languagetree = true,
}

M.indent = { enable = true }
M.auto_install = false
M.sync_install = true

if #vim.api.nvim_list_uis() > 0 then
  M.ensure_installed = require("configs.ensure_installed").treesitter_list
  M.sync_install = false
end

return M
