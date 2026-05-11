local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("ocamllsp", {
    autoformat = false, -- let none-ls handle this via ocamlformat
    cmd = { "ocamllsp" },
  })
end

return M
