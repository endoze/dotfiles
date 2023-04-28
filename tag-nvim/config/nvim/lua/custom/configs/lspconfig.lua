local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require("lspconfig")
local servers = require("custom.configs.lsplanguages").languages

for _, lsp in ipairs(servers) do
  if lsp == "rust_analyzer" then
    local rust_opts = {
      server = {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "rustup", "run", "stable", "rust-analyzer" },

        settings = {
          ["rust-analyzer"] = {
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      },
    }

    require("rust-tools").setup(rust_opts)
  elseif lsp == "solargraph" then
    local custom_on_attach = function(client, bufnr)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
      local utils = require("core.utils")

      utils.load_mappings("lspconfig", { buffer = bufnr })

      local augroup = vim.api.nvim_create_augroup("LspFormattingSolargraph", {})
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })

      if client.server_capabilities.signatureHelpProvider then
        require("nvchad_ui.signature").setup(client)
      end

      if not utils.load_config().ui.lsp_semantic_tokens then
        client.server_capabilities.semanticTokensProvider = nil
      end
    end

    lspconfig[lsp].setup({
      cmd = { "bundle", "exec", "solargraph", "stdio" },
      on_attach = custom_on_attach,
      capabilities = capabilities,
    })
  elseif lsp == "omnisharp" then
    local custom_on_attach = function(client, bufnr)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
      local utils = require("core.utils")

      utils.load_mappings("lspconfig", { buffer = bufnr })

      local augroup = vim.api.nvim_create_augroup("LspFormattingOmnisharp", {})
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })

      if client.server_capabilities.signatureHelpProvider then
        require("nvchad_ui.signature").setup(client)
      end

      if not utils.load_config().ui.lsp_semantic_tokens then
        client.server_capabilities.semanticTokensProvider = nil
      end
    end

    lspconfig[lsp].setup({
      cmd = { "omnisharp" },
      on_attach = custom_on_attach,
      capabilities = capabilities,
    })
  else
    lspconfig[lsp].setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end
end
