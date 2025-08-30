local reverse_prioritize = function(entry1, entry2)
  if entry1.source.name == "copilot" and entry2.source.name ~= "copilot" then
    return false
  elseif entry2.copilot == "copilot" and entry1.source.name ~= "copilot" then
    return true
  end
end

local has_words_before = function()
  if vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt" then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0
    and vim.api
        .nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]
        :match("^%s*$")
      == nil
end

return {
  mapping = {
    ["<C-k>"] = require("cmp").mapping.select_prev_item(),
    ["<C-j>"] = require("cmp").mapping.select_next_item(),
    ["<CR>"] = function(fallback)
      fallback()
    end,
    ["<C-f>"] = require("cmp").mapping.confirm({ select = true }),
    ["<Tab>"] = vim.schedule_wrap(function(fallback)
      local cmp = require("cmp")

      if cmp.visible() and has_words_before() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end),
  },
  sources = {
    { name = "lazydev", group_index = 0 },
    { name = "nvim_lsp", priority = 100 },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "nvim_lua" },
    { name = "path" },
    { name = "crates" },
    -- { name = "copilot", priority = 1 },
  },
  sorting = {
    priority_weight = 2,

    comparators = {
      reverse_prioritize,
      require("cmp").config.compare.offset,
      -- cmp.config.compare.scopes, --this is commented in nvim-cmp too
      require("cmp").config.compare.exact,
      require("cmp").config.compare.score,
      require("cmp").config.compare.recently_used,
      require("cmp").config.compare.locality,
      require("cmp").config.compare.kind,
      require("cmp").config.compare.sort_text,
      require("cmp").config.compare.length,
      require("cmp").config.compare.order,
    },
  },
}
