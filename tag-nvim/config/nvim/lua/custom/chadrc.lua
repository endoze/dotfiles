---@Class ChadrcConfig
local M = {}

M.ui = require("custom.configs.ui")

M.options = {
  user = function()
    -- set lowest priority for lsp syntax highlighting
    -- so treesitter is in charge instead
    vim.highlight.priorities.semantic_tokens = 1

    vim.cmd([[
      :hi NvimTreeExecFile    gui=bold           guifg=#ffa0a0
      :hi NvimTreeSymlink     gui=bold           guifg=#ffff60
      :hi NvimTreeSpecialFile gui=bold,underline guifg=#ff80ff
      :hi NvimTreeImageFile   gui=bold           guifg=#ff80ff
    ]])

    vim.filetype.add({
      extension = {
        ["env"] = "dotenv",
        ["podspec"] = "ruby",
      },
      filename = {
        ["Brewfile"] = "ruby",
        ["Podfile"] = "ruby",
      },
    })

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

    -- remove shift+k keybind as I hit it a lot without meaning to
    vim.api.nvim_set_keymap("n", "<shift>k", "", { noremap = true })
    vim.api.nvim_set_keymap("v", "<shift>k", "", { noremap = true })

    vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "pkl",
      callback = function()
        vim.opt.foldmethod = "manual"
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
