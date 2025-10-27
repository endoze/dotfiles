local function lead_custom_section(bufnr, winnr)
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

return {
  "utilyre/barbecue.nvim",
  name = "barbecue",
  event = "LspAttach",
  version = "*",
  dependencies = {
    "SmiteshP/nvim-navic",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("barbecue").setup({
      attach_navic = false,
      lead_custom_section = lead_custom_section,
    })
  end,
}
