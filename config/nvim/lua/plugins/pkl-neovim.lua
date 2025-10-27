return {
  "apple/pkl-neovim",
  ft = "pkl",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter",
      build = function(_)
        vim.cmd("TSUpdate")
      end,
    },
    { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
  },
  build = function()
    require("pkl-neovim").init()

    vim.cmd("TSInstall! pkl")
  end,
  config = function()
    require("luasnip.loaders.from_snipmate").lazy_load()
  end,
}
