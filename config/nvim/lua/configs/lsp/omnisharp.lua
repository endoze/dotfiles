local M = {}

local setup_autoformat = require("utils").setup_autoformat

function M.setup(on_attach, capabilities)
  local custom_on_attach = function(client, bufnr)
    on_attach(client, bufnr)

    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true

    setup_autoformat("Omnisharp", bufnr)
  end

  ---@type vim.lsp.Config
  local config = {
    cmd = {
      vim.fn.executable("OmniSharp") == 1 and "OmniSharp" or "omnisharp",
      "-z", -- https://github.com/OmniSharp/omnisharp-vscode/pull/4300
      "--hostPID",
      tostring(vim.fn.getpid()),
      "DotNet:enablePackageRestore=false",
      "--encoding",
      "utf-8",
      "--languageserver",
    },
    filetypes = { "cs", "vb" },
    root_markers = {
      "*.sln",
      "*.csproj",
      "omnisharp.json",
      "function.json",
      ".git",
    },
    on_attach = custom_on_attach,
    capabilities = vim.tbl_deep_extend("force", capabilities or {}, {
      workspace = {
        workspaceFolders = false, -- https://github.com/OmniSharp/omnisharp-roslyn/issues/909
      },
    }),
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
  }

  vim.lsp.config("omnisharp", config)
  vim.lsp.enable("omnisharp")
end

return M
