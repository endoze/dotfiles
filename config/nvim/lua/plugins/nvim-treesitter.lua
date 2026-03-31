return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall" },
  build = ":TSUpdate",
  config = function()
    pcall(function()
      dofile(vim.g.base46_cache .. "syntax")
      dofile(vim.g.base46_cache .. "treesitter")
    end)

    require("nvim-treesitter").install({
      "c",
      "blade",
      "dockerfile",
      "go",
      "html",
      "javascript",
      "lua",
      "luadoc",
      "php",
      "printf",
      "ruby",
      "rust",
      "scss",
      "sql",
      "swift",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
    })
  end,
}
