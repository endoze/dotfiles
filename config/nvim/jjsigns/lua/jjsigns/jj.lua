-- Read-only jj command runner. --ignore-working-copy guarantees no snapshot,
-- so jjsigns never causes oplog churn.

local M = {}

--- Run a read-only jj command, invoking on_exit with the completed result.
function M.run(args, cwd, on_exit)
  local cmd = { "jj", "--no-pager", "--ignore-working-copy" }

  vim.list_extend(cmd, args)
  vim.system(cmd, { cwd = cwd, text = true }, on_exit)
end

return M
