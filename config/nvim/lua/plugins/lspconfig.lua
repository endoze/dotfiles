return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "nvimtools/none-ls.nvim",
  },
  config = function()
    require("nvchad.configs.lspconfig").defaults()

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
