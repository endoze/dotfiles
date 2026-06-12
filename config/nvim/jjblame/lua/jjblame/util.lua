-- jjblame user-facing notifications.

local M = {}

function M.notify(msg, level)
  vim.notify("jjblame: " .. msg, level or vim.log.levels.INFO)
end

return M
