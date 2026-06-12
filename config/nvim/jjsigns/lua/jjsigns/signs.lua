-- jjsigns extmark placement in the sign column.

local api = vim.api

local config = require("jjsigns.config")

local M = {}

M.ns = api.nvim_create_namespace("jjsigns")

--- Remove all jjsigns extmarks from a buffer.
function M.clear(bufnr)
  api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

--- Replace a buffer's signs with the given list of {line, type} entries.
function M.place(bufnr, signs)
  api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

  for _, s in ipairs(signs) do
    local conf = config.signs[s.type]

    if conf then
      local hl = config.hl_group[s.type]
      local opts = {
        sign_text = conf.text,
        sign_hl_group = hl,
        priority = config.priority,
      }

      if config.numhl then
        opts.number_hl_group = hl
      end

      if config.linehl then
        opts.line_hl_group = hl
      end

      pcall(api.nvim_buf_set_extmark, bufnr, M.ns, s.line - 1, 0, opts)
    end
  end
end

return M
