return {
  "windwp/nvim-autopairs",
  opts = {
    fast_wrap = {},
    disable_filetype = { "TelescopePrompt", "vim" },
    check_ts = true,
  },
  config = function(_, opts)
    local autopairs = require("nvim-autopairs")
    local ruby_rules = require("nvim-autopairs.rules.endwise-ruby")
    local lua_rules = require("nvim-autopairs.rules.endwise-lua")

    autopairs.setup(opts)
    autopairs.add_rules(ruby_rules)
    autopairs.add_rules(lua_rules)
  end,
}
