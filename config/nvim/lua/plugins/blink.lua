return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdLineEnter" },
  version = "1.*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "L3MON4D3/LuaSnip",
      build = "make install_jsregexp",
      dependencies = "rafamadriz/friendly-snippets",
      opts = { history = true, updateevents = "TextChanged,TextChangedI" },
      config = function(_, opts)
        require("luasnip").config.set_config(opts)

        require("luasnip.loaders.from_vscode").lazy_load({
          exclude = vim.g.vscode_snippets_exclude or {},
        })
        require("luasnip.loaders.from_vscode").lazy_load({
          paths = vim.g.vscode_snippets_path or "",
        })

        -- Fix luasnip #258: clear stale node references when leaving insert
        -- without an active jump.
        vim.api.nvim_create_autocmd("InsertLeave", {
          callback = function()
            local luasnip = require("luasnip")
            if
              luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
              and not luasnip.session.jump_active
            then
              luasnip.unlink_current()
            end
          end,
        })
      end,
    },
  },
  opts_extend = { "sources.default" },
  ---@module 'blink.cmp'
  ---@return blink.cmp.Config
  opts = function()
    dofile(vim.g.base46_cache .. "blink")

    return {
      snippets = { preset = "luasnip" },
      appearance = { nerd_font_variant = "normal" },
      fuzzy = { implementation = "prefer_rust" },
      keymap = {
        preset = "default",
        ["<C-f>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
      },
      cmdline = {
        enabled = true,
        completion = {
          menu = { auto_show = true },
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = true,
            },
          },
        },
        keymap = {
          ["<C-f>"] = { "accept", "fallback" },
          ["<C-j>"] = { "select_next", "fallback" },
          ["<C-k>"] = { "select_prev", "fallback" },
        },
      },
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        documentation = {
          auto_show = false,
        },
        menu = {
          scrollbar = false,
          border = "single",
          draw = {
            padding = { 1, 1 },
            columns = {
              { "label" },
              { "kind_icon" },
              { "kind" },
            },
            components = {
              kind_icon = {
                text = function(ctx)
                  local icons = {
                    Namespace = "󰌗",
                    Text = "󰉿",
                    Method = "󰆧",
                    Function = "󰆧",
                    Constructor = "",
                    Field = "󰜢",
                    Variable = "󰀫",
                    Class = "󰠱",
                    Interface = "",
                    Module = "",
                    Property = "󰜢",
                    Unit = "󰑭",
                    Value = "󰎠",
                    Enum = "",
                    Keyword = "󰌋",
                    Snippet = "",
                    Color = "󱓻",
                    File = "󰈚",
                    Reference = "󰈇",
                    Folder = "󰉋",
                    EnumMember = "",
                    Constant = "󰏿",
                    Struct = "󰙅",
                    Event = "",
                    Operator = "󰆕",
                    TypeParameter = "󰊄",
                  }
                  return icons[ctx.kind] or "󰈚"
                end,
              },
              kind = {
                highlight = function(ctx)
                  return ctx.kind
                end,
              },
            },
          },
        },
      },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
    }
  end,
}
