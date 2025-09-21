local M = {}

function M.setup(on_attach, capabilities)
  local config = require("schema-companion").setup_client(
    require("schema-companion").adapters.yamlls.setup({
      sources = {
        require("schema-companion").sources.matchers.kubernetes.setup({ version = "master" }),
        require("schema-companion").sources.lsp.setup(),
      },
    }),
    {
      capabilities = capabilities,
      on_attach = on_attach,
    }
  )

  vim.lsp.config("yamlls", config)
end

return M
