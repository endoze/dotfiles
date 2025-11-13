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
    gh = {
      enabled = true,
    },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    picker = {
      enabled = true,
      sources = {
        gh_issue = {},
        gh_pr = {},
      },
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
  keys = {
    {
      "<C-t>",
      function()
        require("snacks").picker.files({
          find_command = { "rg", "--files" },
          hidden = false,
          follow = false,
        })
      end,
      desc = "Find files",
    },
    {
      "<leader>be",
      function()
        require("snacks").picker.buffers({
          layout = {
            preset = "select",
          },
        })
      end,
      desc = "Open buffers in picker",
    },
    {
      "<leader>a",
      function()
        require("snacks").picker.grep()
      end,
      desc = "Live grep",
    },
    {
      "<C-f>",
      function()
        require("snacks").picker.lines()
      end,
      desc = "Current buffer search",
    },
    {
      "<leader>fo",
      function()
        require("snacks").picker.recent({
          filter = { cwd = true },
        })
      end,
      desc = "Find recent files",
    },
    {
      "<leader>sn",
      function()
        require("snacks").picker.notifications()
      end,
      desc = "Show notifications",
    },
    {
      "<leader>sr",
      function()
        require("snacks").picker.resume()
      end,
      desc = "Resume last picker",
    },
    {
      "<leader>sm",
      function()
        require("snacks").picker.marks({
          filter = { cwd = true },
        })
      end,
      desc = "Show marks",
    },
    {
      "<leader>gi",
      function()
        require("snacks").picker.gh_issue()
      end,
      desc = "GitHub Issues (open)",
    },
    {
      "<leader>gI",
      function()
        require("snacks").picker.gh_issue({ state = "all" })
      end,
      desc = "GitHub Issues (all)",
    },
    {
      "<leader>gp",
      function()
        require("snacks").picker.gh_pr()
      end,
      desc = "GitHub Pull Requests (open)",
    },
    {
      "<leader>gP",
      function()
        require("snacks").picker.gh_pr({ state = "all" })
      end,
      desc = "GitHub Pull Requests (all)",
    },
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
      end,
    })
  end,
}
