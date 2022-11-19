local M = {}

M.ui = require("custom.plugins.ui")

M.options = {
  user = function()
    -- your extra vim options here
    vim.api.nvim_set_keymap(
      "n",
      "<F2>",
      ":lua vim.lsp.buf.rename()<cr>",
      { noremap = true }
    )
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "swift",
      callback = function()
        vim.opt.tabstop = 2
        vim.opt.expandtab = true
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
      end,
    })
  end,
}

M.plugins = {
  ["lukas-reineke/indent-blankline.nvim"] = false,
  ["goolord/alpha-nvim"] = {
    after = "base46",
    disable = false,
    config = function()
      require("custom.plugins.alpha")
    end,
  },
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require("custom.plugins.null-ls").setup()
    end,
  },
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require("plugins.configs.lspconfig")
      require("custom.plugins.lspconfig")
    end,
  },
  ["tpope/vim-fugitive"] = {},
  ["simrat39/rust-tools.nvim"] = {},

  ["nvim-telescope/telescope.nvim"] = {
    override_options = require("custom.plugins.telescope"),
  },
  ["hrsh7th/nvim-cmp"] = {
    override_options = require("custom.plugins.nvim-cmp"),
  },
  ["kyazdani42/nvim-tree.lua"] = {
    override_options = require("custom.plugins.nvim-tree"),
  },
  ["NvChad/ui"] = {
    override_options = require("custom.plugins.nvchad-ui"),
  },
  ["williamboman/mason.nvim"] = {
    override_options = require("custom.plugins.mason"),
  },
}

M.mappings = require("custom.plugins.mappings")

return M
