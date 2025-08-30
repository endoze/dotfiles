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
  local augroup =
    vim.api.nvim_create_augroup("LspFormatting" .. lsp, { clear = false })
  vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ bufnr = bufnr })
    end,
  })
end

---Function to run when attaching a new LSP server to a buffer
--- @param client table The LSP client object
--- @param bufnr number The buffer number to which the server has attached
function M.on_attach(client, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  if client.server_capabilities["documentSymbolProvider"] then
    -- only attach nvim-navic once in case the current buffer
    -- has multiple LSP's installed
    if
      vim.b[bufnr].navic_client_id == nil
      and vim.b[bufnr].navic_client_name == nil
    then
      require("nvim-navic").attach(client, bufnr)
    end
  end

  map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
  map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
  map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
  map(
    "n",
    "<leader>sh",
    vim.lsp.buf.signature_help,
    opts("Show signature help")
  )
  map(
    "n",
    "<leader>wa",
    vim.lsp.buf.add_workspace_folder,
    opts("Add workspace folder")
  )
  map(
    "n",
    "<leader>wr",
    vim.lsp.buf.remove_workspace_folder,
    opts("Remove workspace folder")
  )

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts("List workspace folders"))

  map(
    "n",
    "<leader>D",
    vim.lsp.buf.type_definition,
    opts("Go to type definition")
  )
  map("n", "<leader>ra", require("nvchad.lsp.renamer"), opts("NvRenamer"))

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
  map("n", "gr", vim.lsp.buf.references, opts("Show references"))
end

return M
