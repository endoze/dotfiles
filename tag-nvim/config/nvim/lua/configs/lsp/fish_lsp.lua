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

    setup_autoformat("FishLsp", bufnr)
  end

  require("lspconfig").fish_lsp.setup({
    capabilities = capabilities,
    on_attach = custom_on_attach,
  })
end

return M
