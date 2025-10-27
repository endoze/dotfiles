return {
  "nvim-telescope/telescope.nvim",
  opts = function()
    local custom_config = {
      extensions_list = {
        "fzf",
        "ui-select",
        "live_grep_args",
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files" },
        },
      },
      defaults = {
        path_display = { "truncate" },
        cache_picker = {
          num_pickers = 10,
        },
        prompt_prefix = "   ",
        file_ignore_patterns = {
          "%.eot",
          "%.eps",
          "%.fla",
          "%.flv",
          "%.GIF",
          "%.gif",
          "%.gz",
          "%.jpeg",
          "%.jpg",
          "%.pdf",
          "%.png",
          "%.psd",
          "%.swf",
          "%.tar",
          "%.tar.gz",
          "%.ttf",
          "%.wof",
          "%.zip",
          "%.zip",
          ".git",
          "bin/Debug",
          "coverage",
          "dump.rdb",
          "node_modules",
          "obj/Debug",
          "public",
          "target",
          "tmp",
          "vendor/*",
          "vendor/cache",
        },
        mappings = {
          i = {
            ["<C-j>"] = function(...)
              require("telescope.actions").move_selection_next(...)
            end,
            ["<C-k>"] = function(...)
              require("telescope.actions").move_selection_previous(...)
            end,
          },
          n = {
            ["d"] = function(...)
              require("telescope.actions").delete_buffer(...)
            end,
          },
        },
      },
    }

    return vim.tbl_deep_extend(
      "force",
      require("nvchad.configs.telescope"),
      custom_config
    )
  end,
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)

    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")
    telescope.load_extension("live_grep_args")
  end,
  dependencies = {
    { "nvim-telescope/telescope-ui-select.nvim" },
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
  },
}
