return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall" },
  build = ":TSUpdate",
  config = function()
    pcall(function()
      dofile(vim.g.base46_cache .. "syntax")
      dofile(vim.g.base46_cache .. "treesitter")
    end)

    require("nvim-treesitter").install({
      "blade",
      "c",
      "diff",
      "dockerfile",
      "git_config",
      "git_rebase",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "go",
      "gotmpl",
      "helm",
      "html",
      "javascript",
      "lua",
      "luadoc",
      "nix",
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
