local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("ruby_lsp", {
    autoformat = true,
    cmd = { "mise", "x", "--", "ruby-lsp" },
    init_options = {
      formatter = "standard",
      linters = { "standard" },
      rubyVersionManager = {
        identifier = "mise",
      },
    },
  })
end

return M
