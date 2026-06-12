-- jjblame: a small jj `file annotate` blame view that opens commits in splits
-- (never a new tab).
--
-- <leader>gb toggles a left, scroll-bound blame panel beside the file. Inside
-- the panel: <CR> opens the commit's diff in a vertical split, <C-x> in a
-- horizontal split, q closes the panel.
--
-- Consecutive lines sharing a change-id are condensed into a single labelled
-- run, wrapped by a bracket glyph and tinted by change-id.
--
-- This file is the public entry point; the work lives in the sibling modules:
--   jj      sys runner + repo resolution + annotate template
--   panel   build/teardown the scroll-bound blame panel
--   diff    open a commit's diff for a blame line in a split
--   colors  resolve the palette + per-change-id section highlight groups
--   config  defaults (glyphs, palette) + merge(opts)
--   util    user notifications

local api = vim.api

local M = {}

function M.close(src)
  require("jjblame.panel").close(src)
end

function M.toggle()
  local panel = require("jjblame.panel")
  local cur = api.nvim_get_current_buf()

  if vim.b[cur].jjblame_is_blame then
    panel.close(vim.b[cur].jjblame_source)

    return
  end

  if panel.is_open(cur) then
    panel.close(cur)
  else
    panel.open(cur)
  end
end

function M.setup(opts)
  require("jjblame.config").merge(opts)
end

return M
