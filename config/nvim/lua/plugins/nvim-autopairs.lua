return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    local autopairs = require("nvim-autopairs")

    autopairs.setup({
      fast_wrap = {},
      disable_filetype = { "TelescopePrompt", "vim" },
      check_ts = true,
    })

    local ruby_rules = require("nvim-autopairs.rules.endwise-ruby")
    local lua_rules = require("nvim-autopairs.rules.endwise-lua")

    autopairs.add_rules(ruby_rules)
    autopairs.add_rules(lua_rules)
  end,
}
