-- Minimal shim consumed by base46. base46/init.lua loads `require("nvconfig").base46`
-- at module-load time, and a handful of integrations also reach into other
-- top-level keys. We exclude the integrations we never load (their cache files
-- are unused), which lets us drop most of the surrounding config.

return {
  base46 = {
    theme = "onedark",
    theme_toggle = { "onedark", "tokyonight" },
    integrations = { "bufferline" },
    excluded = {
      "blankline",
      "cmp",
      "nvcheatsheet",
      "statusline",
      "tbline",
      "telescope",
    },

    hl_add = {
      ["@string.special.symbol"] = { fg = "green" },
    },

    hl_override = {
      DiagnosticInfo = { fg = "#8cf8f7" },
    },

    changed_themes = {
      solarized_dark = {
        base_16 = {
          base0B = "#2aa198",
          base0C = "#6c71c4",
          base0E = "#859900",
        },
      },
    },
  },

  -- blink integration does `cmp_ui.style` as a table index; the table must
  -- exist or it errors. nil style skips the atom overrides (which we don't use).
  ui = { cmp = {} },
}
