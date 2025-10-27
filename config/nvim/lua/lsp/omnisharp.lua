local M = {}

function M.setup()
  local base_capabilities = require("nvchad.configs.lspconfig").capabilities
  local helpers = require("lsp.helpers")

  helpers.setup_lsp("omnisharp", {
    autoformat = true,
    cmd = {
      vim.fn.executable("OmniSharp") == 1 and "OmniSharp" or "omnisharp",
      "-z",
      "--hostPID",
      tostring(vim.fn.getpid()),
      "DotNet:enablePackageRestore=false",
      "--encoding",
      "utf-8",
      "--languageserver",
    },
    filetypes = { "cs", "vb" },
    capabilities = vim.tbl_deep_extend("force", base_capabilities or {}, {
      workspace = {
        workspaceFolders = false,
      },
    }),
    on_attach_extra = function(client, _)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true
    end,
    init_options = {},
    settings = {
      FormattingOptions = {
        EnableEditorConfigSupport = true,
        OrganizeImports = true,
      },
      MsBuild = {
        LoadProjectsOnDemand = nil,
      },
      RoslynExtensionsOptions = {
        EnableAnalyzersSupport = true,
        EnableImportCompletion = true,
        AnalyzeOpenDocumentsOnly = nil,
        EnableDecompilationSupport = nil,
      },
      RenameOptions = {
        RenameInComments = nil,
        RenameOverloads = nil,
        RenameInStrings = nil,
      },
      Sdk = {
        IncludePrereleases = true,
      },
    },
  })
end

return M
