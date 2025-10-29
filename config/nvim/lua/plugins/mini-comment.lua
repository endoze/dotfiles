return {
  "echasnovski/mini.comment",
  event = "VeryLazy",
  opts = {
    mappings = {
      comment = "",
      comment_line = "",
      comment_visual = "",
      textobject = "",
    },
  },
  config = function(_, opts)
    require("mini.comment").setup(opts)

    vim.keymap.set("n", "<leader>c ", function()
      require("mini.comment").toggle_lines(vim.fn.line("."), vim.fn.line("."))
    end, { desc = "Toggle comment" })

    vim.keymap.set("v", "<leader>c ", function()
      local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
      vim.api.nvim_feedkeys(esc, "nx", false)
      require("mini.comment").toggle_lines(vim.fn.line("'<"), vim.fn.line("'>"))
    end, { desc = "Toggle comment" })
  end,
}
