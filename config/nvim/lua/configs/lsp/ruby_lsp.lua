local M = {}

local setup_autoformat = require("utils").setup_autoformat

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    setup_autoformat("ruby_lsp", bufnr)
  end

  vim.lsp.config("ruby_lsp", {
    cmd = { "ruby-lsp" },
    on_attach = custom_on_attach,
    capabilities = capabilities,
    init_options = {
      formatter = "standard",
    },
  })

  vim.lsp.enable("ruby_lsp")
end

return M
