-- jjblame blame panel: a left, scroll-bound `jj file annotate` view beside the
-- source file.

local api = vim.api

local jj = require("jjblame.jj")
local util = require("jjblame.util")
local diff = require("jjblame.diff")
local config = require("jjblame.config")
local colors = require("jjblame.colors")

local M = {}

-- source bufnr -> { win = blame_win, buf = blame_buf, src_win = win }
local state = {}

function M.close(src)
  local s = state[src]

  if s and api.nvim_win_is_valid(s.win) then
    api.nvim_win_close(s.win, true) -- bufhidden=wipe triggers cleanup
  end

  state[src] = nil
end

--- True when a blame panel is currently open for the given source buffer.
function M.is_open(src)
  local s = state[src]

  return s ~= nil and api.nvim_win_is_valid(s.win)
end

function M.open(src)
  local name = api.nvim_buf_get_name(src)

  if name == "" then
    util.notify("buffer has no file", vim.log.levels.WARN)

    return
  end

  local src_win = api.nvim_get_current_win()

  local root, rel = jj.resolve(name)

  if not root then
    util.notify("not in a jj repo", vim.log.levels.WARN)

    return
  end

  local cmd = { "jj", "--no-pager" }

  if config.ignore_working_copy then
    cmd[#cmd + 1] = "--ignore-working-copy"
  end

  vim.list_extend(cmd, { "file", "annotate", "-T", jj.template(), "--", rel })

  local ann = jj.sys(cmd, root)

  if ann.code ~= 0 then
    util.notify("annotate failed: " .. vim.trim(ann.stderr or ""), vim.log.levels.ERROR)

    return
  end

  local raw = vim.split(ann.stdout or "", "\n", { trimempty = true })

  if #raw == 0 then
    util.notify("no annotations", vim.log.levels.WARN)

    return
  end

  -- Parse <change_id>\t<author>\t<date> and align into columns.
  local rev_list, ids, names, dates = {}, {}, {}, {}
  local max_name, max_date = 0, 0

  for i, line in ipairs(raw) do
    local id, author, date = unpack(vim.split(line, "\t", { plain = true }))
    id, author, date = id or "", author or "", date or ""
    rev_list[i] = id
    ids[i], names[i], dates[i] = id, author, date
    max_name = math.max(max_name, #author)
    max_date = math.max(max_date, #date)
  end

  -- Group consecutive lines sharing a change-id into runs, wrap each run in a
  -- bracket glyph, and tint it by change-id. The id/author/date label is shown
  -- only on a run's first line; one display row per source line is preserved.
  local hexes = colors.resolve_palette()
  local n = #hexes

  local author_hl, date_hl = colors.neutral_groups()

  local display = {}
  local line_first = {} -- per line: is this the first line of its run?
  local line_group = {} -- per line: section highlight group name (or nil)
  local line_prefix = {} -- per line: byte offset where the label starts
  local cur_group, prev_idx

  for i = 1, #ids do
    local is_first = i == 1 or ids[i] ~= ids[i - 1]
    local is_last = i == #ids or ids[i] ~= ids[i + 1]

    local glyph

    if is_first and is_last then
      glyph = config.glyphs.single
    elseif is_first then
      glyph = config.glyphs.top
    elseif is_last then
      glyph = config.glyphs.bot
    else
      glyph = config.glyphs.mid
    end

    if is_first then
      if n > 0 then
        local idx = colors.index_for(ids[i], n)

        if idx == prev_idx then
          idx = (idx % n) + 1
        end

        prev_idx = idx
        cur_group = colors.section_group(idx, hexes[idx])
      else
        cur_group = nil
      end
    end

    line_first[i] = is_first
    line_group[i] = cur_group
    line_prefix[i] = #glyph + 1

    if is_first then
      local label = string.format("%-" .. config.id_length .. "s %-" .. max_name .. "s %s", ids[i], names[i], dates[i])
      display[i] = glyph .. " " .. label
    else
      display[i] = glyph
    end
  end

  local topline = vim.fn.line("w0", src_win)

  if config.position == "right" then
    vim.cmd("rightbelow vsplit")
  else
    vim.cmd("leftabove vsplit")
  end

  local blame_win = api.nvim_get_current_win()
  local blame_buf = api.nvim_create_buf(false, true)

  api.nvim_win_set_buf(blame_win, blame_buf)
  api.nvim_buf_set_lines(blame_buf, 0, -1, false, display)

  vim.bo[blame_buf].buftype = "nofile"
  vim.bo[blame_buf].bufhidden = "wipe"
  vim.bo[blame_buf].buflisted = false
  vim.bo[blame_buf].modifiable = false
  vim.bo[blame_buf].filetype = "jjblame"
  vim.b[blame_buf].jjblame_is_blame = true
  vim.b[blame_buf].jjblame_source = src
  vim.b[blame_buf].jjblame_file = rel
  vim.b[blame_buf].jjblame_root = root
  diff.set_revs(blame_buf, rev_list)

  -- Highlights: bracket glyph + change-id take the section color; author/date
  -- stay neutral. Columns are byte offsets (glyphs are multibyte).
  local ns = api.nvim_create_namespace("jjblame")

  for i = 1, #display do
    local group = line_group[i]
    local glyph_end = line_prefix[i] - 1 -- byte length of the glyph

    if group then
      pcall(api.nvim_buf_set_extmark, blame_buf, ns, i - 1, 0, { end_col = glyph_end, hl_group = group })
    end

    if line_first[i] then
      local p = line_prefix[i]
      local id_end = p + config.id_length
      local name_start = id_end + 1
      local name_end = name_start + max_name

      if group then
        pcall(api.nvim_buf_set_extmark, blame_buf, ns, i - 1, p, { end_col = id_end, hl_group = group })
      end

      pcall(api.nvim_buf_set_extmark, blame_buf, ns, i - 1, name_start, { end_col = name_end, hl_group = author_hl })
      pcall(api.nvim_buf_set_extmark, blame_buf, ns, i - 1, name_end + 1, { end_col = #display[i], hl_group = date_hl })
    end
  end

  api.nvim_win_set_width(blame_win, math.min(config.max_width, 2 + config.id_length + 1 + max_name + 1 + max_date + 1))

  for k, v in pairs(config.win_options) do
    vim.wo[blame_win][k] = v
  end

  api.nvim_win_set_cursor(blame_win, { math.min(topline, #display), 0 })
  vim.cmd("normal! zt")

  -- Scroll-bind the blame panel to the source window.
  if config.scrollbind then
    vim.wo[blame_win].scrollbind = true

    if api.nvim_win_is_valid(src_win) then
      vim.wo[src_win].scrollbind = true
    end

    vim.cmd("syncbind")
  end

  state[src] = { win = blame_win, buf = blame_buf, src_win = src_win }

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = blame_buf, nowait = true, desc = desc })
  end

  local km = config.keymaps

  if km.close then
    map(km.close, function() M.close(src) end, "Close blame")
  end

  if km.diff_vsplit then
    map(km.diff_vsplit, function() diff.open(blame_buf, "vertical") end, "Commit diff (vsplit)")
  end

  if km.diff_hsplit then
    map(km.diff_hsplit, function() diff.open(blame_buf, "horizontal") end, "Commit diff (hsplit)")
  end

  api.nvim_create_autocmd("BufWipeout", {
    buffer = blame_buf,
    once = true,
    callback = function()
      if config.scrollbind and api.nvim_win_is_valid(src_win) then
        vim.wo[src_win].scrollbind = false
      end

      diff.clear_revs(blame_buf)

      if state[src] and state[src].buf == blame_buf then
        state[src] = nil
      end
    end,
  })
end

return M
