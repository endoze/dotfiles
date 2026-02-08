return {
  "FabijanZulj/blame.nvim",
  lazy = true,
  config = function(_, opts)
    local theme = require("nvconfig").base46.theme
    local theme_hex_table = require("base46.themes." .. theme).base_16
    opts.colors = vim.tbl_values(theme_hex_table)

    require("blame").setup(opts)
  end,
  opts = {
    date_format = "%Y.%m.%d",
    blame_options = { "-w" },
  },
  cmd = "BlameToggle",
}
