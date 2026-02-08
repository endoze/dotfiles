return {
  "mfussenegger/nvim-dap",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = {
        "nvim-neotest/nvim-nio",
      },
    },
    "theHamsta/nvim-dap-virtual-text",
    "leoluz/nvim-dap-go",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    local dap_go = require("dap-go")
    local dap_ruby = require("plugins.nvim-dap.ruby-adapter")

    require("nvim-dap-virtual-text").setup({})
    dap_go.setup({})
    dap_ruby.setup()

    dap.configurations.rust = {
      {
        name = "Launch",
        type = "codelldb",
        request = "launch",
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        runInTerminal = false,
      },
    }

    dapui.setup({
      layouts = {
        {
          elements = {
            "scopes",
            "breakpoints",
            "stacks",
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            "repl",
          },
          size = 10,
          position = "bottom",
        },
      },
    })

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.disconnect["dapui_config"] = function()
      dapui.close()
    end

    vim.keymap.set("n", "<Leader>db", ":DapToggleBreakpoint<CR>")
    vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>")
    vim.keymap.set("n", "<Leader>do", ":DapStepOver<CR>")
    vim.keymap.set("n", "<Leader>dc", ":DapContinue<CR>")
    vim.keymap.set("n", "<Leader>di", ":DapStepInto<CR>")
  end,
}
