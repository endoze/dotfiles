return function()
  local actions = require("telescope.actions")

  return {
    defaults = {
      prompt_prefix = "   ",
      file_ignore_patterns = { "node_modules", "target", "vendor/cache" },
      file_sorter = require("telescope.sorters").get_fzy_sorter,
      generic_sorter = require("telescope.sorters").get_fzy_sorter,
      mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
        },
        n = {
          ["d"] = actions.delete_buffer,
        },
      },
    },
  }
end
