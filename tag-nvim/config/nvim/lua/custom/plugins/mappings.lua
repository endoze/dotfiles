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
        "<cmd> Telescope oldfiles only_cwd=true <CR>",
        " find oldfilesz",
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
