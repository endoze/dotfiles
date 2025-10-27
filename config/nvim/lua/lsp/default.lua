local M = {}

function M.setup(lsp_name)
  local helpers = require("lsp.helpers")

  helpers.setup_lsp(lsp_name, {
    autoformat = true,
  })
end

return M
