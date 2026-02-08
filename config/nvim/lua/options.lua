local opt = vim.opt
local o = vim.o
local g = vim.g

o.cursorline = true
o.ignorecase = true
o.laststatus = 3
o.number = true
o.numberwidth = 2
o.ruler = false
o.showmode = false
o.signcolumn = "yes"
o.smartcase = true
o.smartindent = true
o.splitbelow = true
o.splitkeep = "screen"
o.splitright = true
o.timeoutlen = 400
o.undofile = true
o.updatetime = 250
o.cmdheight = 0

o.expandtab = true
o.shiftwidth = 2
o.softtabstop = 2
o.tabstop = 2

opt.backspace = "indent,eol,start"
opt.clipboard = "unnamedplus"
opt.cursorlineopt = "number"
opt.mouse = "a"
opt.fillchars = { eob = " " }
opt.shortmess:append("sI")
opt.whichwrap = "b,s"

g.health = { style = "float" }
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0
g.python_recommended_style = false
g.rust_recommended_style = false

vim.hl.priorities.semantic_tokens = 1

o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has("win32") ~= 0
local sep = is_windows and "\\" or "/"
local delim = is_windows and ";" or ":"
vim.env.PATH = table.concat({ vim.fn.stdpath("data"), "mason", "bin" }, sep)
  .. delim
  .. vim.env.PATH

vim.filetype.add({
  extension = {
    ["env"] = "dotenv",
    ["podspec"] = "ruby",
    ["http"] = "http",
    ["gotmpl"] = "gotmpl",
    ["ejson"] = "json",
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
