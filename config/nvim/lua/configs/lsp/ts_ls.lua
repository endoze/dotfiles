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

    setup_autoformat("TsLs", bufnr)
  end

  vim.lsp.config("ts_ls", {
    on_attach = custom_on_attach,
    capabilities = capabilities,
    init_options = {
      jsx = true,
      preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
        importModuleSpecifierPreference = "non-relative",
      },
    },
  })

  vim.lsp.enable("ts_ls")
end

return M
