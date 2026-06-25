-- jjblame configuration: bracket glyphs, the change-id color palette, and the
-- neutral highlight groups for the author/date columns.

local M = {
  -- Box-drawing glyphs that wrap each run of consecutive lines sharing a
  -- change-id. `single` is used for a one-line run.
  glyphs = {
    top = "╭",
    mid = "│",
    bot = "╰",
    single = "╶",
  },

  -- Colors cycled across change-ids. Entries are base46 `base_30` key names
  -- (resolved live from the active theme) or literal "#rrggbb" values.
  palette = {
    "blue",
    "green",
    "purple",
    "cyan",
    "yellow",
    "orange",
    "teal",
    "red",
    "pink",
    "nord_blue",
  },

  -- Neutral fallbacks for the author/date columns when base46 isn't available.
  author_hl = "Identifier",
  date_hl = "Comment",

  -- Length the change-id is abbreviated to; also drives the id column width and
  -- the per-line highlight offsets.
  id_length = 8,

  -- strftime-style format for the author date column (jj timestamp().format()).
  date_format = "%Y-%m-%d",

  -- Side the blame panel opens on: "left" or "right".
  position = "left",

  -- Hard cap on the panel width (columns).
  max_width = 50,

  -- Scroll-bind the panel to the source window so they move together.
  scrollbind = true,

  -- Window-local options applied to the blame panel.
  win_options = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    wrap = false,
    cursorline = true,
    winfixwidth = true,
  },

  -- Buffer-local maps inside the blame panel (and the diff view). Set any entry
  -- to false to disable that mapping.
  keymaps = {
    close = "q",
    diff_vsplit = "<CR>",
    diff_hsplit = "<C-x>",
    diff_close = "q",
  },

  -- false: snapshot the working copy on annotate so blame lines up with the
  -- on-disk file. true: pass --ignore-working-copy to avoid the snapshot/oplog
  -- entry (blame may be stale if the file changed since the last snapshot).
  ignore_working_copy = false,
}

--- Merge user opts into the live config table, in place.
function M.merge(opts)
  opts = opts or {}

  local palette = opts.palette
  local merged = vim.tbl_deep_extend("force", M, opts)

  for k, v in pairs(merged) do
    M[k] = v
  end

  -- palette is a list: replace it wholesale rather than index-merging.
  if palette then
    M.palette = palette
  end
end

return M
