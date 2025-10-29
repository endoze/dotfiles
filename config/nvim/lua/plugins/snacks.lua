return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    picker = {
      enabled = true,
      win = {
        input = {
          keys = {
            ["<C-j>"] = { "list_down", mode = { "n", "i" } },
            ["<C-k>"] = { "list_up", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["d"] = { "delete", mode = { "n" } },
          },
        },
      },
      formatters = {
        file = {
          filename_first = true,
        },
      },
    },
    quickfile = { enabled = true },
    scope = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        vim.notify = require("snacks").notifier.notify

        _G.dd = function(...)
          require("snacks").debug.inspect(...)
        end
        _G.bt = function()
          require("snacks").debug.backtrace()
        end

        vim.keymap.set("n", "<C-t>", function()
          require("snacks").picker.files({
            find_command = { "rg", "--files" },
            hidden = false,
            follow = false,
          })
        end, { desc = "Find files" })

        vim.keymap.set("n", "<leader>be", function()
          require("snacks").picker.buffers({
            layout = {
              preset = "select",
            },
          })
        end, { desc = "Open buffers in picker" })

        vim.keymap.set("n", "<leader>a", function()
          require("snacks").picker.grep()
        end, { desc = "Live grep" })

        vim.keymap.set("n", "<C-f>", function()
          require("snacks").picker.lines()
        end, { desc = "Current buffer search" })

        vim.keymap.set("n", "<leader>fo", function()
          require("snacks").picker.recent({
            filter = { cwd = true },
          })
        end, { desc = "Find recent files" })
      end,
    })
  end,
}
