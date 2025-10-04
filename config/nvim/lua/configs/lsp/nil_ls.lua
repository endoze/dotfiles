local M = {}

function M.setup(on_attach, capabilities, on_init)
  local custom_on_attach = function(client, bufnr)
    -- Disable formatting capabilities
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false

    on_attach(client, bufnr)
  end

  vim.lsp.config("nil_ls", {
    on_attach = custom_on_attach,
    capabilities = capabilities,
    on_init = on_init,
    settings = {
      ["nil"] = {
        formatting = {
          command = nil,
        },
      },
    },
  })

  vim.lsp.enable("nil_ls")
end

return M
