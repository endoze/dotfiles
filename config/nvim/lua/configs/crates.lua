--- Set up crates.nvim plugin along with adding some keybinds
return function()
  require("crates").setup({
    popup = {
      autofocus = true,
    },
    null_ls = {
      enabled = true,
      name = "crates.nvim",
    },

    on_attach = function(bufnr)
      local function show_documentation()
        require("crates").show_popup()
      end

      vim.keymap.set(
        "n",
        "K",
        show_documentation,
        { silent = true, buffer = bufnr }
      )
    end,
  })

  require("crates").show()
end
