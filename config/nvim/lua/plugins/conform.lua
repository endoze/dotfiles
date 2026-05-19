return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      html = { "prettierd" },
      css = { "prettierd" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      ocaml = { "ocamlformat" },
      lua = { "stylua" },
      swift = { "swiftformat" },
      terraform = { "terraform_fmt" },
      go = { "gofmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      cuda = { "clang_format" },
      proto = { "clang_format" },
      kotlin = { "ktlint" },
      nix = { "nixpkgs_fmt" },
      python = { "yapf" },
      php = { "php_cs_fixer" },
      sql = { "sqruff" },
    },
    formatters = {
      sqruff = {
        prepend_args = {
          "--config",
          vim.fn.expand("~/.config/sqruff/config.cfg"),
        },
      },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
  },
}
