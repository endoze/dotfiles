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

      require("none-ls.diagnostics.eslint").with({
        condition = function(utils)
          return utils.root_has_file({
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.json",
            ".eslintrc.yml",
            ".eslintrc.yaml",
          })
        end,
      }),

      b.formatting.swiftformat,

      b.formatting.terraform_fmt,

      b.formatting.gofmt,

      b.formatting.clang_format.with({
        filetypes = { "c", "cpp", "cuda", "proto" },
      }),

      b.formatting.ktlint,

      b.formatting.nixpkgs_fmt,

      b.formatting.yapf,
      -- b.diagnostics.mypy,

      b.formatting.phpcsfixer,
    }

    null_ls.setup({
      sources = sources,

      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          local augroup =
            vim.api.nvim_create_augroup("NullLsFormatting", { clear = false })
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr })
            end,
          })
        end
      end,
    })
  end,
}
