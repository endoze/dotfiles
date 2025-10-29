require("nvchad.options")

vim.g.rust_recommended_style = false
vim.g.python_recommended_style = false
vim.hl.priorities.semantic_tokens = 1
vim.opt.backspace = "indent,eol,start"
vim.opt.cmdheight = 0
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.whichwrap = "b,s"
vim.g.health = { style = "float" }

vim.env.PAGER = "less"
vim.env.MANPAGER = "less -X"

vim.keymap.set(
  "c",
  "<C-f>",
  "<C-y>",
  { desc = "Accept completion", remap = true }
)
vim.keymap.set(
  "c",
  "<C-j>",
  "<C-n>",
  { desc = "Next completion", remap = true }
)
vim.keymap.set(
  "c",
  "<C-k>",
  "<C-p>",
  { desc = "Previous completion", remap = true }
)

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
    ["http"] = "http",
    ["gotmpl"] = "gotmpl",
  },
  filename = {
    ["Brewfile"] = "ruby",
    ["Podfile"] = "ruby",
    ["Fastfile"] = "ruby",
    [".pryrc"] = "ruby",
    ["pryrc"] = "ruby",
    [".irbrc"] = "ruby",
    ["irbrc"] = "ruby",
  },
  pattern = {
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.ya?ml"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
    [".*/helm/.*%.ya?ml"] = "helm",
  },
})

-- edit main NvChad settings
vim.api.nvim_set_keymap(
  "n",
  "<leader>es",
  ":e $HOME/.config/nvim/lua/chadrc.lua<CR>",
  { noremap = true }
)

-- fold code via vim's understanding of scope
vim.keymap.set("n", "<leader>ft", function()
  ---@diagnostic disable-next-line
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

-- Stop content from being yanked when pasting over a visual selection
vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true })
