return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
  build = ":TSUpdate",
  opts = function()
    local custom_config = {
      highlight = {
        enable = true,
        use_languagetree = true,
      },

      indent = { enable = true },

      ensure_installed = {
        "c",
        "blade",
        "dockerfile",
        "go",
        "html",
        "javascript",
        "lua",
        "php",
        "ruby",
        "rust",
        "scss",
        "sql",
        "swift",
        "typescript",
        "vim",
        "yaml",
      },

      auto_install = true,
    }

    local nvconf = require("nvchad.configs.treesitter")

    return vim.tbl_deep_extend("force", nvconf, custom_config)
  end,
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
