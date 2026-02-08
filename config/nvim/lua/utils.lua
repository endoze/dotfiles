local M = {}

local map = vim.keymap.set

---Applies a table of keymaps as keybinds in nvim
--- @param keymap_table table Table containing keymaps to apply
function M.apply_keymap_table(keymap_table)
  for _, modes in pairs(keymap_table) do
    for mode, mappings in pairs(modes) do
      for key, value in pairs(mappings) do
        local map_to, desc = unpack(value)
        local opts = { desc = desc }

        map(mode, key, map_to, opts)
      end
    end
  end
end

return M
