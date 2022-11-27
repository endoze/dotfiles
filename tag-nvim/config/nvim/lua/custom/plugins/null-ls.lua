local null_ls = require("null-ls")
local b = null_ls.builtins

local sources = {
  b.formatting.prettierd.with({ filetypes = { "html", "markdown", "css" } }),
  b.formatting.deno_fmt,

  -- Lua
  b.formatting.stylua,
  b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),

  -- Shell
  b.formatting.shfmt,
  b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),

  -- Rust
  b.formatting.rustfmt,

  -- Swift
  b.formatting.swiftformat,
}

local M = {}

M.setup = function()
  null_ls.setup({
    debug = true,
    sources = sources,

    -- format on save
    on_attach = function(client)
      if client.supports_method("textDocument/formatting") then
        vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.format()")
      end
    end,
  })
end

return M
