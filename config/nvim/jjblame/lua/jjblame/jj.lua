-- jj command helpers for jjblame.

local config = require("jjblame.config")

local M = {}

-- Build the annotate template from config: <change_id>\t<author>\t<date>\n.
function M.template()
  return table.concat({
    ("commit.change_id().short(%d)"):format(config.id_length),
    '"\\t"',
    "commit.author().name()",
    '"\\t"',
    ('commit.author().timestamp().format("%s")'):format(config.date_format),
    '"\\n"',
  }, " ++ ")
end

--- Run a command synchronously and return its completed result.
function M.sys(cmd, cwd)
  return vim.system(cmd, { cwd = cwd, text = true }):wait()
end

--- Resolve the jj repo root and repo-relative path for a buffer's file.
function M.resolve(name)
  local dir = vim.fs.dirname(name)
  local r = M.sys({ "jj", "--no-pager", "--ignore-working-copy", "root" }, dir)

  if r.code ~= 0 then
    return nil
  end

  local root = vim.trim(r.stdout or "")

  if root == "" then
    return nil
  end

  local rel = name

  if vim.startswith(name, root) then
    rel = name:sub(#root + 2)
  end

  return root, rel
end

return M
