local M = {}

function M.setup()
  local helpers = require("lsp.helpers")

  local diagnostics = {
    typeErrors = false,
    nagaVersion = "0.29",
    nagaParsingErrors = true,
    nagaValidationErrors = true,
  }

  helpers.setup_lsp("wgsl_analyzer", {
    autoformat = true,
    -- Read at `initialize` time. wgsl-analyzer only pulls `settings` via
    -- workspace/configuration in response to didChangeConfiguration, which
    -- Neovim's native client doesn't drive (wgsl-analyzer#77/#59), so the
    -- server never sees `settings` and falls back to defaults. init_options
    -- is read at startup and must be UNWRAPPED (no "wgsl-analyzer" key).
    init_options = { diagnostics = diagnostics },
    -- Kept for correctness: honored if a didChangeConfiguration pull ever fires.
    settings = {
      ["wgsl-analyzer"] = { diagnostics = diagnostics },
    },
  })
end

return M
