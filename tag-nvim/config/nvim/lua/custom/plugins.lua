return {
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  {
    "nvim-telescope/telescope.nvim",
    opts = require("custom.configs.telescope"),
  },
  { "hrsh7th/nvim-cmp", opts = require("custom.configs.nvim-cmp") },
  { "nvim-tree/nvim-tree.lua", opts = require("custom.configs.nvim-tree") },
  { "williamboman/mason.nvim", opts = require("custom.configs.mason") },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/null-ls.nvim",
      config = function()
        require("custom.configs.null-ls").setup()
      end,
    },
    config = function()
      require("plugins.configs.lspconfig")
      require("custom.configs.lspconfig")
    end,
  },
  { "tpope/vim-fugitive", lazy = true },
  { "kchmck/vim-coffee-script", lazy = true },
  { "simrat39/rust-tools.nvim", lazy = true },
  { "NvChad/ui", opts = require("custom.configs.nvchad-ui") },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = require("custom.configs.treesitter"),
  },
  { "chiedo/vim-case-convert", lazy = true },
  {
    "saecki/crates.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = { "BufRead Cargo.toml" },
    config = function()
      require("crates").setup({
        popup = {
          autofocus = false,
        },
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
      })
    end,
  },
}
