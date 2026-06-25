-- jjblame commit view: open the full commit (`jj show`) for the blame line
-- under the cursor in a split (never a new tab).

local api = vim.api

local jj = require("jjblame.jj")
local util = require("jjblame.util")
local config = require("jjblame.config")

local M = {}

-- blame bufnr -> { [lnum] = change_id }
local revs = {}

--- Record the per-line change ids for a blame buffer.
function M.set_revs(blame_buf, rev_list)
  revs[blame_buf] = rev_list
end

--- Drop the per-line change ids for a blame buffer.
function M.clear_revs(blame_buf)
  revs[blame_buf] = nil
end

--- Open the full commit (`jj show`) for the blame line under the cursor.
function M.open(blame_buf, direction)
  local lnum = vim.fn.line(".")
  local rev = revs[blame_buf] and revs[blame_buf][lnum]

  if not rev or rev == "" then
    return
  end

  local file = vim.b[blame_buf].jjblame_file
  local root = vim.b[blame_buf].jjblame_root

  -- `jj show` renders the commit metadata + description + the full git diff.
  -- It can't be scoped to a single file, so this is the whole commit.
  local r = jj.sys({
    "jj", "--no-pager", "--ignore-working-copy",
    "show", "--git", "-r", rev,
  }, root)

  if r.code ~= 0 or not r.stdout or r.stdout == "" then
    util.notify("no diff for " .. rev, vim.log.levels.WARN)

    return
  end

  local lines = vim.split(r.stdout, "\n")

  if lines[#lines] == "" then
    table.remove(lines)
  end

  if direction == "horizontal" then
    vim.cmd("botright split | enew")
  else
    vim.cmd("botright vsplit | enew")
  end

  local buf = api.nvim_get_current_buf()

  vim.wo[0].scrollbind = false -- don't inherit the blame panel's scroll binding

  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false

  pcall(api.nvim_buf_set_name, buf, "jj-diff://" .. rev .. "/" .. vim.fn.fnamemodify(file, ":t"))

  if config.keymaps.diff_close then
    vim.keymap.set("n", config.keymaps.diff_close, "<cmd>close<cr>", { buffer = buf, nowait = true, desc = "Close diff" })
  end
end

return M
