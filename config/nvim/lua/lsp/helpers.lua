local M = {}

local map = vim.keymap.set

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

M.on_init = function(client, _)
  if vim.fn.has "nvim-0.11" ~= 1 then
    if client.supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    if client:supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
end

M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, opts "Go to definition")
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts "Add workspace folder")
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts "Remove workspace folder")

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts "List workspace folders")

  map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Go to type definition")
  map("n", "<leader>ra", require "nvchad.lsp.renamer", opts "NvRenamer")
end

M.diagnostic_config = function()
  local x = vim.diagnostic.severity

  vim.diagnostic.config {
    virtual_text = { prefix = "" },
    signs = { text = { [x.ERROR] = "󰅙", [x.WARN] = "", [x.INFO] = "󰋼", [x.HINT] = "󰌵" } },
    underline = true,
    float = { border = "single" },
  }
end

function M.create_on_attach(opts)
  opts = opts or {}
  local lsp_name = opts.lsp_name
  local enable_autoformat = opts.autoformat ~= false

  return function(client, bufnr)
    M.on_attach(client, bufnr)

    local function keymap_opts(desc)
      return { buffer = bufnr, desc = "LSP " .. desc }
    end

    if client.server_capabilities["documentSymbolProvider"] then
      if
        vim.b[bufnr].navic_client_id == nil
        and vim.b[bufnr].navic_client_name == nil
      then
        require("nvim-navic").attach(client, bufnr)
      end
    end

    map("n", "gD", vim.lsp.buf.declaration, keymap_opts("Go to declaration"))
    map("n", "gd", vim.lsp.buf.definition, keymap_opts("Go to definition"))
    map("n", "gi", vim.lsp.buf.implementation, keymap_opts("Go to implementation"))
    map("n", "<leader>sh", vim.lsp.buf.signature_help, keymap_opts("Show signature help"))
    map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, keymap_opts("Add workspace folder"))
    map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, keymap_opts("Remove workspace folder"))
    map("n", "<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, keymap_opts("List workspace folders"))
    map("n", "<leader>D", vim.lsp.buf.type_definition, keymap_opts("Go to type definition"))
    map("n", "<leader>ra", require("nvchad.lsp.renamer"), keymap_opts("NvRenamer"))
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, keymap_opts("Code action"))
    map("n", "gr", vim.lsp.buf.references, keymap_opts("Show references"))

    map("n", "<F2>", vim.lsp.buf.rename, keymap_opts("Rename"))
    map("n", "<leader>lf", function()
      vim.diagnostic.open_float(nil, { focusable = false })
    end, keymap_opts("Floating diagnostic"))
    map("n", "<leader>fm", vim.lsp.buf.format, keymap_opts("Format file"))

    if enable_autoformat and lsp_name then
      local augroup = vim.api.nvim_create_augroup("LspFormatting" .. lsp_name, { clear = false })
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end

    if opts.on_attach_extra then
      opts.on_attach_extra(client, bufnr)
    end
  end
end

function M.setup_lsp(name, opts)
  opts = opts or {}

  local config = {
    on_attach = M.create_on_attach({
      lsp_name = name,
      autoformat = opts.autoformat,
      on_attach_extra = opts.on_attach_extra,
    }),
    capabilities = opts.capabilities or M.capabilities,
    on_init = opts.on_init or M.on_init,
  }

  if opts.cmd then
    config.cmd = opts.cmd
  end

  if opts.settings then
    config.settings = opts.settings
  end

  if opts.init_options then
    config.init_options = opts.init_options
  end

  if opts.root_dir then
    config.root_dir = opts.root_dir
  end

  if opts.filetypes then
    config.filetypes = opts.filetypes
  end

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

return M
