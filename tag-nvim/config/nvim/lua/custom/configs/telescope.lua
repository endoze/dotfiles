return {
  defaults = {
    prompt_prefix = "   ",
    file_ignore_patterns = {
      "node_modules",
      "target",
      "vendor/cache",
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
    file_sorter = function()
      return require("telescope.sorters").get_fzy_sorter()
    end,
    generic_sorter = function()
      return require("telescope.sorters").get_fzy_sorter()
    end,
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
