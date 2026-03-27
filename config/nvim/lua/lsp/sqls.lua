local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("sqls", {
    autoformat = false,
  })
end

return M
