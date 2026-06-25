-- jj-aware data for the lualine statusline.
--
-- All jj work is async + cached: the component functions (M.branch / M.diff_counts)
-- return cached values only and never spawn a process, so a statusline redraw never
-- waits on jj. jj runs in the background on FocusGained / save / new repo root.

local api = vim.api

local M = {}

local cache = {} -- repo root -> branch string
local inflight = {} -- repo root -> true while a refresh is running
local current_root -- repo root of the active buffer

local TEMPLATE = "if(bookmarks, bookmarks, change_id.short(8))"

local function root_of(buf)
  return vim.fs.root(buf or 0, { ".jj", ".git" })
end

local function refresh(root)
  if not root or inflight[root] then
    return
  end

  inflight[root] = true

  vim.system(
    { "jj", "--no-pager", "--ignore-working-copy", "log", "--no-graph", "-r", "@", "-T", TEMPLATE },
    { cwd = root, text = true },
    vim.schedule_wrap(function(res)
      inflight[root] = nil
      cache[root] = (res.code == 0) and vim.trim(res.stdout or "") or nil
      vim.cmd("redrawstatus")
    end)
  )
end

--- Cached branch string for the active buffer's repo (O(1), no subprocess).
function M.branch()
  local root = current_root

  if not root then
    return ""
  end

  if cache[root] == nil then
    refresh(root) -- lazy first fetch; render stays empty until it returns
  end

  return cache[root] or ""
end

--- Diff counts {added, modified, removed} from jjsigns (in-memory), or nil.
function M.diff_counts()
  local ok, jjsigns = pcall(require, "jjsigns")

  if not ok then
    return nil
  end

  return jjsigns.status_dict(api.nvim_get_current_buf())
end

function M.setup()
  local group = api.nvim_create_augroup("jj_statusline", { clear = true })

  -- Cheap (no subprocess): just track the active buffer's repo root, and do a
  -- one-time fetch the first time we see a new root.
  api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      current_root = root_of(0)

      if current_root and cache[current_root] == nil then
        refresh(current_root)
      end
    end,
  })

  -- @ may have moved (jj op run elsewhere) or content saved: re-fetch in place.
  api.nvim_create_autocmd({ "FocusGained", "BufWritePost", "DirChanged" }, {
    group = group,
    callback = function()
      current_root = current_root or root_of(0)

      refresh(current_root)
    end,
  })

  current_root = root_of(0)

  if current_root then
    refresh(current_root)
  end
end

return M
