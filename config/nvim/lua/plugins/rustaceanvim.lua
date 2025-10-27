return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  lazy = false,
  config = function()
    local ih = require("inlay-hints")
    local helpers = require("lsp.helpers")

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
        on_attach = helpers.create_on_attach({
          lsp_name = "Rust",
          autoformat = true,
          on_attach_extra = function(client, bufnr)
            ih.on_attach(client, bufnr)
          end,
        }),
      },
    }
  end,
}
