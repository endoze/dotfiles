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
      ["<F2>"] = {
        ":lua vim.lsp.buf.rename()<CR>",
        "LSP Rename",
      },
      ["<F3>"] = {
        ":s/[^ ]\\zs \\+/ /g<cr>:noh<cr>",
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
  telescope = {
    n = {
      ["<C-t>"] = {
        "<cmd> Telescope find_files no_ignore=true <CR>",
        " find files",
      },
      ["<leader>be"] = {
        "<cmd> Telescope buffers initial_mode=normal <CR>",
        "open buffers in telescope",
      },
      ["<leader>a"] = { "<cmd> Telescope live_grep <CR>", " live grep" },
      ["<C-f>"] = {
        "<cmd> Telescope current_buffer_fuzzy_find <CR>",
        " current buffer search",
      },
      ["<leader>fo"] = {
        ":lua require('telescope.builtin').oldfiles({prompt_title='Recent Files', only_cwd=true})<CR>",
        " find recent files",
      },
    },
  },
  nvimtree = {
    n = {
      ["<leader>n"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
    },
  },
  comment = {
    n = {
      ["<leader>c "] = {
        function()
          require("Comment.api").toggle.linewise.current()
        end,

        "Toggle comment",
      },
    },
    v = {
      ["<leader>c "] = {
        "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
        "Toggle comment",
      },
    },
  },
}

return keymap_table
