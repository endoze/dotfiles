local keymap_table = {
  window = {
    n = {
      ["<C-h>"] = {
        "<C-w>h",
        "Switch window left",
      },
      ["<C-l>"] = {
        "<C-w>l",
        "Switch window right",
      },
      ["<C-j>"] = {
        "<C-w>j",
        "Switch window down",
      },
      ["<C-k>"] = {
        "<C-w>k",
        "Switch window up",
      },
      ["<Esc>"] = {
        "<cmd>noh<CR>",
        "Clear highlights",
      },
      ["<C-c>"] = {
        "<cmd>%y+<CR>",
        "Copy whole file",
      },
    },
  },
  tabufline = {
    n = {
      ["<leader>b"] = {
        "<cmd>enew<CR>",
        "Buffer new",
      },
      ["<tab>"] = {
        function()
          require("nvchad.tabufline").next()
        end,
        "Buffer goto next",
      },
      ["<S-tab>"] = {
        function()
          require("nvchad.tabufline").prev()
        end,
        "Buffer goto prev",
      },
      ["<leader>x"] = {
        function()
          require("nvchad.tabufline").close_buffer()
        end,
        "Buffer close",
      },
    },
  },
  whichkey = {
    n = {
      ["<leader>wk"] = {
        "<cmd>WhichKey <CR>",
        "Whichkey all keymaps",
      },
    },
  },
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
      ["<leader>es"] = {
        ":e $HOME/.config/nvim/lua/chadrc.lua<CR>",
        "Edit NvChad settings",
      },
      ["<leader>ft"] = {
        "za",
        "Toggle fold",
      },
      -- ["<leader>ft"] = {
      --   function()
      --     if vim.fn.foldclosedend(".") ~= -1 then
      --       vim.api.nvim_feedkeys(
      --         vim.api.nvim_replace_termcodes("zO", true, true, true),
      --         "n",
      --         true
      --       )
      --     else
      --       vim.api.nvim_feedkeys(
      --         vim.api.nvim_replace_termcodes("$zf%", true, true, true),
      --         "n",
      --         true
      --       )
      --     end
      --   end,
      --   "Toggle fold",
      -- },
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
    x = {
      ["p"] = {
        '"_dP',
        "Paste without yanking",
      },
    },
    c = {
      ["<C-f>"] = {
        "<C-y>",
        "Accept completion",
      },
      ["<C-j>"] = {
        "<C-n>",
        "Next completion",
      },
      ["<C-k>"] = {
        "<C-p>",
        "Previous completion",
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
