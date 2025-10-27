local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("intelephense", {
    autoformat = false,
    filetypes = { "php", "blade" },
    settings = {
      intelephense = {
        format = {
          enable = false,
        },
        files = {
          associations = { "*.php", "*.blade.php" },
          exclude = {
            "**/.git/**",
            "**/.DS_Store/**",
            "**/node_modules/**",
            "**/vendor/**",
          },
        },
      },
    },
  })
end

return M
