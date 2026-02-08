local M = {}

function M.setup()
  local base_capabilities = require("nvchad.configs.lspconfig").capabilities
  local helpers = require("lsp.helpers")

  local roslyn_dll_handle = io.popen(
    "readlink ~/.nix-profile/bin/Microsoft.CodeAnalysis.LanguageServer 2>/dev/null | xargs dirname 2>/dev/null"
  )
  local roslyn_bin_dir = roslyn_dll_handle:read("*a"):gsub("%s+$", "")
  roslyn_dll_handle:close()

  local roslyn_dll = roslyn_bin_dir
    .. "/../lib/roslyn-ls/Microsoft.CodeAnalysis.LanguageServer.dll"

  local lspconfig_roslyn = vim.lsp.config.roslyn_ls

  helpers.setup_lsp("roslyn_ls", {
    autoformat = true,
    cmd = {
      "dotnet",
      roslyn_dll,
      "--logLevel",
      "Information",
      "--extensionLogDirectory",
      vim.fn.stdpath("cache") .. "/roslyn_ls",
      "--stdio",
    },
    capabilities = base_capabilities,
    on_init = lspconfig_roslyn.on_init,
    on_attach_extra = function(client, bufnr)
      client.server_capabilities.documentFormattingProvider = true
      client.server_capabilities.documentRangeFormattingProvider = true

      if lspconfig_roslyn.on_attach then
        lspconfig_roslyn.on_attach(client, bufnr)
      end
    end,
    settings = {
      ["csharp|inlay_hints"] = {
        csharp_enable_inlay_hints_for_implicit_object_creation = true,
        csharp_enable_inlay_hints_for_implicit_variable_types = true,
        csharp_enable_inlay_hints_for_lambda_parameter_types = true,
        csharp_enable_inlay_hints_for_types = true,
        dotnet_enable_inlay_hints_for_indexer_parameters = true,
        dotnet_enable_inlay_hints_for_literal_parameters = true,
        dotnet_enable_inlay_hints_for_object_creation_parameters = true,
        dotnet_enable_inlay_hints_for_other_parameters = true,
        dotnet_enable_inlay_hints_for_parameters = true,
        dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
        dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
        dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
      },
      ["csharp|code_lens"] = {
        dotnet_enable_references_code_lens = true,
      },
    },
  })
end

return M
