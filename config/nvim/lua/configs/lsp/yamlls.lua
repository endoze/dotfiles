local M = {}

function M.setup(on_attach, capabilities)
  require("lspconfig").yamlls.setup(require("schema-companion").setup_client({
    capabilities = capabilities,
    on_attach = on_attach,
  }))
end

return M
