-- jjsigns per-buffer lifecycle: attach/detach, base fetching, and diffing the
-- live buffer against `@-` in-memory (vim.diff) so signs update as you type and
-- never shell out per keystroke.

local api = vim.api
local uv = vim.uv or vim.loop

local config = require("jjsigns.config")
local jj = require("jjsigns.jj")
local diff = require("jjsigns.diff")
local signs = require("jjsigns.signs")

local M = {}

-- bufnr -> { root, rel, base, attached, timer, counts }
local buffers = {}
local enabled = true

local function compute(bufnr)
  local st = buffers[bufnr]

  if not enabled or not st or not st.attached or st.base == nil then
    return
  end

  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local cur = table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local hunks = vim.diff(st.base, cur, { result_type = "indices" }) or {}
  st.counts = diff.hunks_to_counts(hunks)

  signs.place(bufnr, diff.hunks_to_signs(hunks))
end

function M.fetch_base(bufnr)
  local st = buffers[bufnr]

  if not st then
    return
  end

  jj.run({ "file", "show", "-r", config.base, "--", st.rel }, st.root, function(res)
    if not buffers[bufnr] then
      return
    end

    if res.code == 0 then
      local base = res.stdout or ""

      if base:sub(-1) == "\n" then
        base = base:sub(1, -2)
      end

      st.base = base
    elseif res.stderr and res.stderr:match("No such path") then
      st.base = "" -- new file in @: every line is an addition
    else
      st.base = nil -- couldn't resolve base; leave existing signs alone
    end

    vim.schedule(function()
      compute(bufnr)
    end)
  end)
end

local function schedule_compute(bufnr)
  local st = buffers[bufnr]

  if not st then
    return
  end

  if st.timer then
    st.timer:stop()
  else
    st.timer = uv.new_timer()
  end

  st.timer:start(config.debounce, 0, vim.schedule_wrap(function()
    compute(bufnr)
  end))
end

function M.detach(bufnr)
  local st = buffers[bufnr]

  if not st then
    return
  end

  if st.timer then
    st.timer:stop()
    st.timer:close()
  end

  pcall(api.nvim_del_augroup_by_name, "jjsigns_buf_" .. bufnr)

  if api.nvim_buf_is_valid(bufnr) then
    signs.clear(bufnr)
  end

  buffers[bufnr] = nil
end

function M.attach(bufnr)
  if buffers[bufnr] or not enabled then
    return
  end

  if not api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end

  local name = api.nvim_buf_get_name(bufnr)

  if name == "" then
    return
  end

  local dir = vim.fs.dirname(name)

  jj.run({ "root" }, dir, function(root_res)
    if root_res.code ~= 0 then
      return
    end

    local root = vim.trim(root_res.stdout or "")

    if root == "" then
      return
    end

    local rel = name

    if vim.startswith(name, root) then
      rel = name:sub(#root + 2)
    end

    jj.run({ "file", "list", "--", rel }, root, function(list_res)
      if list_res.code ~= 0 or vim.trim(list_res.stdout or "") == "" then
        return -- untracked
      end

      vim.schedule(function()
        if buffers[bufnr] or not api.nvim_buf_is_valid(bufnr) then
          return
        end

        buffers[bufnr] = { root = root, rel = rel, base = nil, attached = true }

        local group = api.nvim_create_augroup("jjsigns_buf_" .. bufnr, { clear = true })

        api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
          group = group,
          buffer = bufnr,
          callback = function()
            schedule_compute(bufnr)
          end,
        })
        api.nvim_create_autocmd("BufWritePost", {
          group = group,
          buffer = bufnr,
          callback = function()
            M.fetch_base(bufnr)
          end,
        })
        api.nvim_create_autocmd({ "BufUnload", "BufDelete" }, {
          group = group,
          buffer = bufnr,
          callback = function()
            M.detach(bufnr)
          end,
        })

        M.fetch_base(bufnr)
      end)
    end)
  end)
end

--- Diff counts for a buffer (for the statusline), or nil when not attached.
function M.status_dict(bufnr)
  local st = buffers[bufnr or api.nvim_get_current_buf()]

  return st and st.counts or nil
end

--- Re-fetch the base for every attached buffer.
function M.refresh()
  for bufnr in pairs(buffers) do
    M.fetch_base(bufnr)
  end
end

--- Set the initial enabled state (from config) before any buffers attach.
function M.set_initial(v)
  enabled = v ~= false
end

function M.enabled()
  return enabled
end

--- Enable signs and attach every loaded buffer.
function M.enable()
  enabled = true

  for _, b in ipairs(api.nvim_list_bufs()) do
    M.attach(b)
  end
end

--- Disable signs and detach every attached buffer.
function M.disable()
  enabled = false

  for bufnr in pairs(buffers) do
    M.detach(bufnr)
  end
end

return M
