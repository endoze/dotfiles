local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("ruby_lsp", {
    autoformat = true,
    init_options = {
      formatter = "standard",
      linters = { "standard" },
      indexing = {
        excludedPatterns = {
          "bazel-*/**/*",
          "node_modules/**/*",
          ".ruby-lsp/**/*",
          ".git/**/*",
          ".jj/**/*",
          ".claude/**/*",
          "lrtc/log/**/*",
          "lrtc/storage/**/*",
          "lrtc/tmp/**/*",
          "lrtc/vendor/**/*",
          "lrtc/public/**/*",
          "tools/**/*",
          "bin/**/*",
        },
      },
    },
  })
end

return M
