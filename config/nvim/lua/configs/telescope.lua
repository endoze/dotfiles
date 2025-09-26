return {
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
  defaults = {
    prompt_prefix = "   ",
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
