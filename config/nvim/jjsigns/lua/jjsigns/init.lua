-- jjsigns: gitsigns-style diff signs for Jujutsu, snapshot-free.
--
-- The base content is read from `@-` with --ignore-working-copy (so jj never
-- snapshots the working copy => zero oplog churn) and diffed in-memory against
-- the live buffer with vim.diff. Signs therefore update as you type and never
-- shell out per keystroke.
--
-- This file is the public entry point; the work lives in the sibling modules:
--   config      defaults + highlight-group map
--   highlights  resolve the JJSigns* highlight groups
--   jj          read-only jj command runner
--   diff        pure hunk -> signs / counts conversions
--   signs       extmark placement
--   buffer      per-buffer attach/detach + diffing lifecycle

local api = vim.api

local config = require("jjsigns.config")
local highlights = require("jjsigns.highlights")
local buffer = require("jjsigns.buffer")

local M = {}

--- Diff counts {added, modified, removed} for a buffer (for the statusline),
--- or nil when the buffer isn't attached.
function M.status_dict(bufnr)
  return buffer.status_dict(bufnr)
end

--- Re-fetch the base for every attached buffer.
function M.refresh()
  buffer.refresh()
end

--- Toggle signs on/off across all buffers.
function M.toggle()
  if buffer.enabled() then
    buffer.disable()
  else
    buffer.enable()
  end
end

function M.setup(opts)
  config.merge(opts)

  buffer.set_initial(config.enabled)

  highlights.apply()

  local group = api.nvim_create_augroup("jjsigns", { clear = true })

  api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = group,
    callback = function(args)
      buffer.attach(args.buf)
    end,
  })

  if config.watch_focus then
    api.nvim_create_autocmd("FocusGained", {
      group = group,
      callback = function()
        buffer.refresh()
      end,
    })
  end

  api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = highlights.apply,
  })

  -- Plugin is lazy-loaded on User FilePost, so the first buffer already exists.
  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) then
      buffer.attach(b)
    end
  end

  api.nvim_create_user_command("JJSignsRefresh", M.refresh, { desc = "Refresh jj signs" })
  api.nvim_create_user_command("JJSignsToggle", M.toggle, { desc = "Toggle jj signs" })

  if config.keymaps.toggle then
    vim.keymap.set("n", config.keymaps.toggle, M.toggle, { desc = "Toggle jj signs" })
  end

  if config.keymaps.refresh then
    vim.keymap.set("n", config.keymaps.refresh, M.refresh, { desc = "Refresh jj signs" })
  end
end

return M
