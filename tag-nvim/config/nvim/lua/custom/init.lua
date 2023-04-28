vim.g.mapleader = ","
vim.g.rust_recommended_style = false
vim.opt.whichwrap = "b,s"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.backspace = "indent,eol,start"
vim.opt.cmdheight = 0
vim.api.nvim_set_keymap("n", "<leader><space>", ":noh<cr>", { noremap = true })
vim.api.nvim_set_keymap(
  "n",
  "<leader>es",
  ":e $HOME/.config/nvim/lua/custom/chadrc.lua<CR>",
  { noremap = true }
)

local config = require("core.utils").load_config()

if type(config.options.user) == "function" then
  config.options.user()
end
