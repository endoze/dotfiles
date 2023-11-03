return {
  disabled = {
    n = {
      ["<leader>n"] = "",
      ["<leader>rn"] = "",
      ["<leader>/"] = "",
      ["<C-n>"] = "",
      ["<leader>ff"] = "",
      ["<leader>fb"] = "",
      ["<leader>fa"] = "",
      ["<leader>e"] = "",
    },
    v = {
      ["<leader>/"] = "",
    },
  },
  neoai = {
    n = {
      ["<leader>u"] = {
        ":NeoAIToggle<CR>",
        "Toggle NeoAI Floating Window",
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
      ["<leader>n"] = { "<cmd> NvimTreeToggle <CR>", "   toggle nvimtree" },
    },
  },
  comment = {
    n = {
      ["<leader>c "] = {
        function()
          require("Comment.api").toggle.linewise.current()
        end,

        "蘒  toggle comment",
      },
    },
    v = {
      ["<leader>c "] = {
        "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
        "蘒  toggle comment",
      },
    },
  },
}
