local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("ocamllsp", {
    autoformat = false, -- ocamlformat runs via conform.nvim
    cmd = { "ocamllsp" },
  })
end

return M
