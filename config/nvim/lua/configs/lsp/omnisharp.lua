local M = {}

local setup_autoformat = require("utils").setup_autoformat

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true

    setup_autoformat("Omnisharp", bufnr)
  end

  require("lspconfig").omnisharp.setup({
    cmd = { "omnisharp" },
    on_attach = custom_on_attach,
    capabilities = capabilities,
    settings = {
      RoslynExtensionsOptions = {
        EnableAnalyzersSupport = true,
        EnableEditorConfigSupport = true,
      },
      FormattingOptions = {
        EnableEditorConfigSupport = true,
      },
    },
  })
end

return M
