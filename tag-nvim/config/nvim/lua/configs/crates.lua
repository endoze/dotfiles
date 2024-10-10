local M = {}

--- Set up crates.nvim plugin along with adding some keybinds
M.config = function()
  require("crates").setup({
    popup = {
      autofocus = true,
    },
    null_ls = {
      enabled = true,
      name = "crates.nvim",
    },
  })
  local function show_documentation()
    require("crates").show_popup()
  end

  vim.keymap.set("n", "K", show_documentation, { silent = true })
  require("crates").show()
end

return M
