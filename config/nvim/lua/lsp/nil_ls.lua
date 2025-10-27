local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("nil_ls", {
    autoformat = false,
    on_attach_extra = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
      ["nil"] = {
        formatting = {
          command = nil,
        },
      },
    },
  })
end

return M
