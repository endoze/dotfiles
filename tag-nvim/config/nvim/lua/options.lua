require("nvchad.options")

vim.g.rust_recommended_style = false
vim.highlight.priorities.semantic_tokens = 1
vim.opt.backspace = "indent,eol,start"
vim.opt.cmdheight = 0
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.whichwrap = "b,s"

-- remove autocomplete from git commit messages
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    require("cmp").setup.buffer({ enabled = false })
  end,
})

-- prevent . from triggering treesitter indents in ruby files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ruby",
  callback = function()
    vim.opt_local.indentkeys:remove(".")
  end,
})

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
-- vim.api.nvim_set_keymap("n", "<shift>k", "", { noremap = true })
-- vim.api.nvim_set_keymap("v", "<shift>k", "", { noremap = true })

-- another way to get out of insert mode when escape isn't convenient
vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = true })

-- remove search highlights
vim.api.nvim_set_keymap("n", "<leader><space>", ":noh<cr>", { noremap = true })

-- edit main NvChad settings
vim.api.nvim_set_keymap(
  "n",
  "<leader>es",
  ":e $HOME/.config/nvim/lua/chadrc.lua<CR>",
  { noremap = true }
)

-- fold code via vim's understanding of scope
vim.keymap.set("n", "<leader>ft", function()
  if vim.fn.foldclosedend(".") ~= -1 then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("zO", true, true, true),
      "n",
      true
    )
  else
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("$zf%", true, true, true),
      "n",
      true
    )
  end
end, { expr = true, noremap = true, desc = "Toggle fold" })

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

vim.api.nvim_create_user_command("InstallMasonPackages", function()
  local ensure_installed = require("configs.ensure_installed")
  local mason_install_list = ensure_installed.mason_list

  local mason_cmd = require("mason.api.command")
  mason_cmd.MasonInstall(mason_install_list, {})
end, {})
