return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    local b = null_ls.builtins

    local sources = {
      b.formatting.prettierd.with({
        filetypes = {
          "html",
          "css",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
      }),

      b.formatting.stylua,
      b.diagnostics.selene.with({
        cwd = function(_)
          return vim.fs.dirname(
            vim.fs.find(
              { "selene.toml" },
              { upward = true, path = vim.api.nvim_buf_get_name(0) }
            )[1]
          ) or vim.fn.expand("~/.config/selene/")
        end,
      }),

      require("none-ls.diagnostics.eslint"),

      b.formatting.swiftformat,

      b.formatting.terraform_fmt,

      b.formatting.gofmt,

      b.formatting.clang_format.with({
        filetypes = { "c", "cpp", "cuda", "proto" },
      }),

      b.formatting.ktlint,

      b.formatting.nixpkgs_fmt,

      b.formatting.yapf,
      b.diagnostics.mypy,

      b.formatting.phpcsfixer,
    }

    null_ls.setup({
      sources = sources,

      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = true

        if client.supports_method("textDocument/formatting") then
          vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.format()")
        end
      end,
    })
  end,
}
