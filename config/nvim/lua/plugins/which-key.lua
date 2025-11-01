return {
  "folke/which-key.nvim",
  keys = { "<leader>", "<c-w>", '"', "'", "`", "c", "v", "g" },
  cmd = "WhichKey",
  opts = function()
    dofile(vim.g.base46_cache .. "whichkey")
    return {}
  end,
}
