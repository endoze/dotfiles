return {
  "neovim/nvim-lspconfig",
  event = "User FilePost",
  dependencies = {
    "nvimtools/none-ls.nvim",
  },
  config = function()
    local helpers = require("lsp.helpers")

    dofile(vim.g.base46_cache .. "lsp")
    helpers.diagnostic_config()

    local languages = require("lsp.languages")

    for _, lsp in ipairs(languages) do
      local ok, config = pcall(require, "lsp." .. lsp)

      if ok then
        config.setup()
      else
        require("lsp.default").setup(lsp)
      end
    end
  end,
}
