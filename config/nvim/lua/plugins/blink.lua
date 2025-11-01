return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdLineEnter" },
  version = "1.*",
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "L3MON4D3/LuaSnip",
      dependencies = "rafamadriz/friendly-snippets",
      opts = { history = true, updateevents = "TextChanged,TextChangedI" },
      config = function(_, opts)
        require("luasnip").config.set_config(opts)
        require("nvchad.configs.luasnip")
      end,
    },
  },
  opts_extend = { "sources.default" },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
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
              preselect = false,
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
        documentation = {
          auto_show = false,
        },
        menu = require("nvchad.blink").menu,
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
