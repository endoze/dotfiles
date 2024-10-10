local M = {}

M.setup = function()
  local null_ls = require("null-ls")
  local b = null_ls.builtins

  local sources = {
    b.formatting.prettierd.with({ filetypes = { "html", "css" } }),

    -- Lua
    b.formatting.stylua,
    b.diagnostics.selene,

    -- Swift
    b.formatting.swiftformat,

    -- Terraform
    b.formatting.terraform_fmt,

    -- Go
    b.formatting.gofmt,

    -- C/C++/Objective-C
    b.formatting.clang_format,

    -- Kotlin
    b.formatting.ktlint,
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

return M
