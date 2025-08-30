require("nvchad.configs.lspconfig").defaults()

local on_attach = require("utils").on_attach
local capabilities = require("nvchad.configs.lspconfig").capabilities
local on_init = require("nvchad.configs.lspconfig").on_init

local servers = require("configs.lsplanguages")

for _, lsp in ipairs(servers) do
  local has_custom_config, custom_config = pcall(require, "configs.lsp." .. lsp)

  if has_custom_config then
    custom_config.setup(on_attach, capabilities)
  else
    require("configs.lsp.default").setup(lsp, on_attach, capabilities, on_init)
  end
end
