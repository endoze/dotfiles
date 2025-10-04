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
  telescope = {
    n = {
      ["<C-t>"] = {
        function()
          require("telescope.builtin").find_files({
            find_command = { "rg", "--files" },
          })
        end,
        " find files",
      },
      ["<leader>be"] = {
        function()
          require("telescope.builtin").buffers({ initial_mode = "normal" })
        end,
        "open buffers in telescope",
      },
      ["<leader>a"] = {
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        " live grep",
      },
      ["<C-f>"] = {
        function()
          require("telescope.builtin").current_buffer_fuzzy_find()
        end,
        " current buffer search",
      },
      ["<leader>fo"] = {
        function()
          require("telescope.builtin").oldfiles({
            prompt_title = "Recent Files",
            only_cwd = true,
          })
        end,
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
