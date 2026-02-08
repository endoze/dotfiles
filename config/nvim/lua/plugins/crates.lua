return {
  "saecki/crates.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  event = { "BufRead Cargo.toml" },
  config = function()
    require("crates").setup({
      popup = {
        autofocus = true,
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
  end,
}
