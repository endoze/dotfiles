local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("elixirls", {
    autoformat = true,
    cmd = { "elixir-ls" },
    on_attach_extra = function(client, _)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
    end,
  })
end

return M
