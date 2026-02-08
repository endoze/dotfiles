return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "luvit-meta/library", words = { "vim%.uv" } },
      {
        path = "~/.local/share/lua_addons/love2d/library",
        words = { "love" },
      },
    },
  },
}
