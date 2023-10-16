return {
  { "lukas-reineke/indent-blankline.nvim", enabled = true },
  {
    "nvim-telescope/telescope.nvim",
    opts = require("custom.configs.telescope"),
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    },
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
          autofocus = true,
        },
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
      })
      local function show_documentation()
        require("crates").show_popup()
      end

      vim.keymap.set("n", "K", show_documentation, { silent = true })
      require("crates").show()
    end,
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      require("custom.configs.nvim-dap")
    end,
  },
  "rcarriga/nvim-dap-ui",
  "folke/neodev.nvim",
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("neodev").setup()
      require("plugins.configs.lspconfig")
      require("custom.configs.lspconfig")
    end,
  },
}
