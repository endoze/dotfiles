local M = {}

function M.setup()
  local helpers = require("lsp.helpers")
  local ih = require("inlay-hints")

  helpers.setup_lsp("tsgo", {
    autoformat = false,
    on_attach_extra = function(client, bufnr)
      ih.on_attach(client, bufnr)

      if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(false)
      end
    end,
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
end

return M
