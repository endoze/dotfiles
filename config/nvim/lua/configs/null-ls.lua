return function()
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

    -- Lua
    b.formatting.stylua,
    b.diagnostics.selene.with({
      cwd = function(_)
        return vim.fs.dirname(
          vim.fs.find(
            { "selene.toml" },
            { upward = true, path = vim.api.nvim_buf_get_name(0) }
          )[1]
        ) or vim.fn.expand("~/.config/selene/") -- fallback value
      end,
    }),

    require("none-ls.diagnostics.eslint"),

    -- Swift
    b.formatting.swiftformat,

    -- Terraform
    b.formatting.terraform_fmt,

    -- Go
    b.formatting.gofmt,

    -- C/C++/Objective-C
    b.formatting.clang_format.with({
      filetypes = { "c", "cpp", "cuda", "proto" },
    }),

    -- Kotlin
    b.formatting.ktlint,

    -- Nix
    b.formatting.nixpkgs_fmt,

    -- Python
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
end
