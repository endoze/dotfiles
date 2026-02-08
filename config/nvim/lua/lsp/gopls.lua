local M = {}

function M.setup()
  local helpers = require("lsp.helpers")
  local ih = require("inlay-hints")

  helpers.setup_lsp("gopls", {
    autoformat = true,
    on_attach_extra = function(client, bufnr)
      ih.on_attach(client, bufnr)

      if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(false)
      end
    end,
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
