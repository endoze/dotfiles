return {
  dir = vim.fn.stdpath("config") .. "/jjsigns",
  name = "jjsigns",
  event = "User FilePost",
  config = function()
    require("jjsigns").setup({})
  end,
}
