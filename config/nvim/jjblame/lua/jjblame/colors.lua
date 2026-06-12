-- jjblame change-id coloring: resolve the configured palette against the active
-- base46 theme and hand out a stable highlight group per change-id.

local api = vim.api

local config = require("jjblame.config")

local M = {}

-- Fallback hexes (base46 "onedark") for when base46 isn't installed, so the
-- plugin still colors sensibly as a standalone.
local FALLBACK = {
  white = "#abb2bf",
  grey = "#42464e",
  blue = "#61afef",
  green = "#98c379",
  purple = "#de98fd",
  cyan = "#a3b8ef",
  yellow = "#e7c787",
  orange = "#fca2aa",
  teal = "#519ABA",
  red = "#e06c75",
  pink = "#ff75a0",
  nord_blue = "#81A1C1",
}

--- The active base46 base_30 palette, or an empty table when unavailable.
local function base30()
  local ok, base46 = pcall(require, "base46")

  if not ok then
    return {}
  end

  local ok2, tb = pcall(base46.get_theme_tb, "base_30")

  return ok2 and tb or {}
end

--- Resolve a palette entry ("#hex" literal or base_30 key) to a hex string.
local function resolve(entry, p)
  if type(entry) == "string" and entry:sub(1, 1) == "#" then
    return entry
  end

  return p[entry] or FALLBACK[entry]
end

--- Resolve the configured palette to a list of hex colors (drops any that
--- can't be resolved). Returns the list.
function M.resolve_palette()
  local p = base30()
  local hexes = {}

  for _, entry in ipairs(config.palette) do
    local hex = resolve(entry, p)

    if hex then
      hexes[#hexes + 1] = hex
    end
  end

  return hexes
end

--- Deterministic djb2-style hash of a change-id, mapped to [1, n].
function M.index_for(change_id, n)
  local hash = 5381

  for i = 1, #change_id do
    hash = (hash * 33 + change_id:byte(i)) % 4294967296
  end

  return (hash % n) + 1
end

--- Ensure the JJBlameSection<idx> highlight exists with the given fg, and
--- return its group name.
function M.section_group(idx, hex)
  local name = "JJBlameSection" .. idx

  api.nvim_set_hl(0, name, { fg = hex })

  return name
end

--- Define the neutral author/date highlight groups and return their names.
function M.neutral_groups()
  local p = base30()

  if p.white then
    api.nvim_set_hl(0, "JJBlameAuthor", { fg = p.white })
  else
    api.nvim_set_hl(0, "JJBlameAuthor", { link = config.author_hl })
  end

  if p.grey_fg or p.grey then
    api.nvim_set_hl(0, "JJBlameDate", { fg = p.grey_fg or p.grey })
  else
    api.nvim_set_hl(0, "JJBlameDate", { link = config.date_hl })
  end

  return "JJBlameAuthor", "JJBlameDate"
end

return M
