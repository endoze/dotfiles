local M = {}

function M.setup()
  local helpers = require("lsp.helpers")
  local ih = require("inlay-hints")

  -- TypeScript 7 GA ships the native compiler as `tsc` (there is no more
  -- `tsserver`), and the language server is hosted by tsc itself via
  -- `tsc --lsp --stdio`. This was previously registered under nvim-lspconfig's
  -- bundled "tsgo" server; we now own the config end-to-end, so the root_dir and
  -- inlay `settings` below are carried over from what that config provided.
  helpers.setup_lsp("tsc", {
    autoformat = false,
    cmd = { "tsc", "--lsp", "--stdio" },
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    -- tsc has native monorepo support (it locates the right tsconfig per
    -- package), so the LSP root is the repo root: the nearest package-manager
    -- lockfile, falling back to .git and then the cwd.
    root_dir = function(bufnr, on_dir)
      local root_markers = {
        "package-lock.json",
        "yarn.lock",
        "pnpm-lock.yaml",
        "bun.lock",
        "bun.lockb",
      }

      on_dir(vim.fs.root(bufnr, root_markers) or vim.fs.root(bufnr, ".git") or vim.fn.getcwd())
    end,
    on_attach_extra = function(client, bufnr)
      ih.on_attach(client, bufnr)

      if client.server_capabilities.inlayHintProvider then
        vim.lsp.inlay_hint.enable(false)
      end
    end,
    init_options = {
      jsx = true,
      preferences = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
        importModuleSpecifierPreference = "non-relative",
      },
    },
    settings = {
      typescript = {
        inlayHints = {
          parameterNames = {
            enabled = "literals",
            suppressWhenArgumentMatchesName = true,
          },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      },
    },
  })
end

return M
