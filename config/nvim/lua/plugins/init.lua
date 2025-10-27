return {
  { "stevearc/conform.nvim", enabled = false },
  { "Bilal2453/luvit-meta", lazy = true },
  { "lukas-reineke/indent-blankline.nvim", enabled = true },
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },
  "stevearc/dressing.nvim",
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
}
