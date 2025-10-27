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

    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local themes = require("telescope.themes")

    local create_executable_picker = function(routine)
      local debug_dir = vim.fn.getcwd() .. "/target/debug"

      telescope.find_files(themes.get_dropdown({
        prompt_title = "Path to executable for debug",
        cwd = debug_dir,
        previewer = false,
        find_command = {
          "find",
          ".",
          "-maxdepth",
          "1",
          "-type",
          "f",
          "-perm",
          "-111",
        },
        entry_maker = function(entry)
          local filename_only = vim.fn.fnamemodify(entry, ":t")
          local fullpath = debug_dir .. "/" .. filename_only

          return {
            value = entry,
            display = filename_only,
            ordinal = filename_only,
            path = fullpath,
          }
        end,
        attach_mappings = function(prompt_bufnr, map)
          map({ "n", "i" }, "<CR>", function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            coroutine.resume(routine, selection.path)
          end)
          return true
        end,
      }))
    end

    dap.configurations.rust = {
      {
        name = "Launch",
        type = "codelldb",
        request = "launch",
        program = function()
          return coroutine.create(function(routine)
            return create_executable_picker(routine)
          end)
        end,
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
