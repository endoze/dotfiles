return {
  mapping = {
    ["<C-k>"] = require("cmp").mapping.select_prev_item(),
    ["<C-j>"] = require("cmp").mapping.select_next_item(),
  },
}
