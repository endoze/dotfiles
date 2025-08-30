return function()
  local ih = require("inlay-hints")

  vim.g.rustaceanvim = {
    tools = {
      on_initialized = function(_)
        ih.set_all()
      end,
      hover_actions = {
        replace_builtin_hover = false,
      },
    },
    server = {
      on_attach = function(client, bufnr)
        local on_attach = require("utils").on_attach
        on_attach(client, bufnr)
        ih.on_attach(client, bufnr)

        require("utils").setup_autoformat("Rust", bufnr)
      end,
    },
  }
end
