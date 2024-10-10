local M = {}

function M.setup(on_attach, capabilities)
  local cfg = require("yaml-companion").setup({
    lspconfig = {
      capabilities = capabilities,
      on_attach = on_attach,
    },
    schemas = {
      {
        name = "Kubernetes 1.22.5",
        uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.5-standalone-strict/all.json",
      },
    },
  })

  require("lspconfig").yamlls.setup(cfg)
end

return M
