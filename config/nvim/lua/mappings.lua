local keymap_table = {
  general = {
    n = {
      [";"] = {
        ":",
        "Enter command mode",
      },
      ["<leader><space>"] = {
        ":noh<CR>",
        "Remove all highlights",
      },
      ["<F3>"] = {
        ":%s/\\s\\+$//e<cr>:noh<cr>",
        "Remove extraneous whitespace",
      },
      ["<leader>lf"] = {
        ":lua vim.diagnostic.open_float(nil, { focusable = false })<CR>",
        "Floating diagnostic",
      },
      ["<leader>fm"] = {
        ":lua vim.lsp.buf.format()<CR>",
        "General Format file",
      },
      ["<leader>th"] = {
        function()
          require("nvchad.themes").open({
            mappings = function(buf)
              vim.keymap.set(
                "i",
                "<C-k>",
                require("nvchad.themes.api").move_up,
                { buffer = buf }
              )
              vim.keymap.set(
                "i",
                "<C-j>",
                require("nvchad.themes.api").move_down,
                { buffer = buf }
              )
            end,
          })
        end,
      },
      ["<leader>gb"] = {
        ":BlameToggle<cr>",
        "Toggle Git Blame",
      },
      ["q:"] = {
        "",
        "",
      },
    },
    i = {
      ["jj"] = {
        "<ESC>",
        "Escape insert mode",
      },
    },
    v = {
      ["<"] = {
        "<gv",
        "Preserve highlight on left shift",
      },
      [">"] = {
        ">gv",
        "Preserve highlight on left shift",
      },
    },
  },
  nvimtree = {
    n = {
      ["<leader>n"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
    },
  },
}

return keymap_table
