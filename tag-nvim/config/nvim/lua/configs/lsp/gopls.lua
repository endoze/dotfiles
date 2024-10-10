local M = {}

local setup_autoformat = require("utils").setup_autoformat
local ih = require("inlay-hints")

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    ih.on_attach(client, bufnr)

    if client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(false)
    end

    setup_autoformat("Gopls", bufnr)
  end

  require("lspconfig").gopls.setup({
    capabilities = capabilities,
    on_attach = custom_on_attach,
    settings = {
      gopls = {
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  })
end

return M
