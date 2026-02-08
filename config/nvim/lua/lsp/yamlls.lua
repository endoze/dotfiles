local M = {}

function M.setup()
  local base_capabilities = require("nvchad.configs.lspconfig").capabilities
  local base_on_init = require("nvchad.configs.lspconfig").on_init
  local helpers = require("lsp.helpers")

  local config = require("schema-companion").setup_client(
    require("schema-companion").adapters.yamlls.setup({
      sources = {
        require("schema-companion").sources.matchers.kubernetes.setup({
          version = "master",
        }),
        require("schema-companion").sources.lsp.setup(),
      },
    }),
    {
      capabilities = base_capabilities,
      on_attach = helpers.create_on_attach({
        lsp_name = "yamlls",
        autoformat = false,
      }),
      on_init = base_on_init,
    }
  )

  vim.lsp.config("yamlls", config)
  vim.lsp.enable("yamlls")
end

return M
