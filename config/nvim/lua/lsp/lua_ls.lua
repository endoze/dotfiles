local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  local settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }

  helpers.setup_lsp("lua_ls", {
    settings = settings,
    autoformat = true,
  })
end

return M
