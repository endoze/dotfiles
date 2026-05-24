local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("sourcekit", {
    autoformat = true,
    cmd = { "sourcekit" },
    filetypes = {
      "swift",
    },
    on_attach_extra = function(client, _)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
    end,
  })
end

return M
