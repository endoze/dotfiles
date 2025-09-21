local M = {}

local setup_autoformat = require("utils").setup_autoformat

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true

    setup_autoformat("ElixirLs", bufnr)
  end

  vim.lsp.config("elixirls", {
    cmd = { "elixir-ls" },
    on_attach = custom_on_attach,
    capabilities = capabilities,
  })
end

return M
