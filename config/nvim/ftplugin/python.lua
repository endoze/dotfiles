-- This turns off the horrendous builtin python defaults
vim.api.nvim_buf_set_var(0, "did_ftplugin", 1)
vim.api.nvim_buf_set_var(0, "undo_ftplugin", "")
