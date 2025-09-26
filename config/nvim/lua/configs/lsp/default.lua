local M = {}

local setup_autoformat = require("utils").setup_autoformat

function M.setup(lsp, on_attach, capabilities, on_init)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    setup_autoformat(lsp, bufnr)
  end

  vim.lsp.config(lsp, {
    on_attach = custom_on_attach,
    capabilities = capabilities,
    on_init = on_init,
  })

  vim.lsp.enable(lsp)
end

return M
