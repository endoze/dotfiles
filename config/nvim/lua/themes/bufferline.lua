local M = {}

function M.opts()
  local p = require("base46").get_theme_tb("base_30")
  return {
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      show_close_icon = false,
      show_buffer_close_icons = true,
      color_icons = true,
      offsets = {
        {
          filetype = "NvimTree",
          text = "",
          separator = false,
          padding = 1,
          highlight = "NvimTreeNormal",
        },
      },
    },
    highlights = (function()
      -- Sync bufferline's internal hls (used for per-icon and per-diagnostic
      -- bg derivation) with base46's palette. Without these, bufferline
      -- derives bgs from Normal.bg + tint(), which doesn't match the
      -- BufferLine* highlights that base46 sets — so inactive-tab icons and
      -- diagnostic counts render on the wrong bg.
      local hls = {
        background = { bg = p.black2 },
        buffer_visible = { bg = p.black2 },
        buffer_selected = { bg = p.black, bold = true },
        fill = { bg = p.black2 },
        diagnostic = { bg = p.black2 },
        diagnostic_visible = { bg = p.black2 },
        diagnostic_selected = { bg = p.black, bold = true },
      }
      -- Per-severity diagnostic bg overrides for all three tab states +
      -- the standalone count badge variant.
      for _, sev in ipairs({ "error", "warning", "info", "hint" }) do
        hls[sev] = { bg = p.black2 }
        hls[sev .. "_visible"] = { bg = p.black2 }
        hls[sev .. "_selected"] = { bg = p.black, bold = true }
        hls[sev .. "_diagnostic"] = { bg = p.black2 }
        hls[sev .. "_diagnostic_visible"] = { bg = p.black2 }
        hls[sev .. "_diagnostic_selected"] = { bg = p.black, bold = true }
      end
      return hls
    end)(),
  }
end

return M
