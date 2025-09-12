local M = {}

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    -- Autoformat disabled for intelephense
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
        },
      },
    },
  })
end

return M
