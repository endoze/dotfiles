local M = {}

M.ui = require("custom.configs.ui")

M.options = {
  user = function()
    -- set lowest priority for lsp syntax highlighting
    -- so treesitter is in charge instead
    vim.highlight.priorities.semantic_tokens = 1

    -- lsp rename
    vim.api.nvim_set_keymap(
      "n",
      "<F2>",
      ":lua vim.lsp.buf.rename()<cr>",
      { noremap = true }
    )

    -- remove extraneous whitespace
    vim.api.nvim_set_keymap(
      "v",
      "<F3>",
      ":s/[^ ]\\zs \\+/ /g<cr>:noh<cr>",
      { noremap = true }
    )

    -- remove pesky vim command history command
    vim.api.nvim_set_keymap("n", "q:", "<Nop>", { noremap = true })

    -- convert hashrocket to ruby 1.9 hash syntax
    vim.api.nvim_set_keymap(
      "n",
      "<leader>d",
      ":%s/:\\([^ ]*\\)\\(\\s*\\)=>/\\1:/g<cr>",
      { noremap = true }
    )

    -- remove shift+k keybind as I hit it a lot without meaning to
    vim.api.nvim_set_keymap("n", "<shift>k", "", { noremap = true })
    vim.api.nvim_set_keymap("v", "<shift>k", "", { noremap = true })

    vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true })

    -- overwrite swift file format defaults from vim
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "swift",
      callback = function()
        vim.opt.tabstop = 2
        vim.opt.expandtab = true
        vim.opt.softtabstop = 2
        vim.opt.shiftwidth = 2
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "gitcommit",
      callback = function()
        require("cmp").setup.buffer({ enabled = false })
      end,
    })
  end,
}

M.plugins = "custom.plugins"
M.mappings = require("custom.configs.mappings")

return M
