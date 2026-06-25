return {
  dir = vim.fn.stdpath("config") .. "/jjblame",
  name = "jjblame",
  keys = {
    { "<leader>gb", function() require("jjblame").toggle() end, desc = "JJ blame" },
  },
  config = function()
    require("jjblame").setup({})
  end,
}
