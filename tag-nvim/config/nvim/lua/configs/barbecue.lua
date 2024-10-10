local M = {}

--- Function to calculate leading space based on the
--- number gutter in a specified buffer and window.
---@param bufnr number The buffer number.
---@param winnr number The window number.
M.lead_custom_section = function(bufnr, winnr)
  --- Internal function to get the number gutter width.
  ---@param bufnr1 number The buffer number.
  ---@param winnr1 number The window number.
  ---@return number The width of the number gutter.
  local function get_number_gutter_width(bufnr1, winnr1)
    local win_info = vim.fn.getwininfo(winnr1)

    for _, info in ipairs(win_info) do
      if info.bufnr == bufnr1 then
        return info.textoff
      end
    end

    return 0
  end

  local gutter_width = get_number_gutter_width(bufnr, winnr)

  return string.rep(" ", gutter_width)
end

return M
