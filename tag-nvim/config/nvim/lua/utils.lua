local M = {}

local map = vim.keymap.set

---Applies a table of keymaps as keybinds in nvim
--- @param keymap_table table Table containing keymaps to apply
function M.apply_keymap_table(keymap_table)
  require("nvchad.mappings")

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

---Create an autocmd to run LSP provided formatter on BufWritePre
--- @param lsp string The name of the LSP
--- @param bufnr number The buffer to set up the autocmd on
function M.setup_autoformat(lsp, bufnr)
  local augroup = vim.api.nvim_create_augroup("LspFormatting" .. lsp, {})
  vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ bufnr = bufnr })
    end,
  })
end

return M
