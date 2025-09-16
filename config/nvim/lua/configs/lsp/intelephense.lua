local M = {}

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)
  end

  require("lspconfig").intelephense.setup({
    on_attach = custom_on_attach,
    capabilities = capabilities,
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
