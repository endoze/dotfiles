return {
  extensions_list = {
    "fzf",
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
  defaults = {
    prompt_prefix = "   ",
    file_ignore_patterns = {
      "node_modules",
      "target",
      "vendor/cache",
      "tmp",
      "public",
      "bin/Debug",
      "obj/Debug",
      "dump.rdb",
      "**/*.png",
      "**/*.gif",
      "**/*.GIF",
      "**/*.jpg",
      "**/*.jpeg",
      "**/*.fla",
      "**/*.flv",
      "**/*.swf",
      "**/*.eot",
      "**/*.ttf",
      "**/*.wof",
      "**/*.zip",
      "**/*.gz",
      "**/*.psd",
      "**/*.eps",
      "**/*.pdf",
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
