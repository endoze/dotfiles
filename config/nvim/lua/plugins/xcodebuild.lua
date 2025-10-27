return {
  "wojciech-kulik/xcodebuild.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
  },
  event = "VeryLazy",
  cond = function()
    local cwd = vim.fn.getcwd()
    local has_xcodeproj = vim.fn.glob(cwd .. "/*.xcodeproj") ~= ""
    local has_xcworkspace = vim.fn.glob(cwd .. "*.xcworkspace") ~= ""
    return has_xcodeproj or has_xcworkspace
  end,
  config = function()
    require("xcodebuild").setup({
      xcodebuild_offline = {
        enabled = true,
      },
    })

    vim.keymap.set(
      "n",
      "<leader>X",
      "<cmd>XcodebuildPicker<cr>",
      { desc = "Show Xcodebuild Actions" }
    )
    vim.keymap.set(
      "n",
      "<leader>xf",
      "<cmd>XcodebuildProjectManager<cr>",
      { desc = "Show Project Manager Actions" }
    )

    vim.keymap.set(
      "n",
      "<leader>xr",
      "<cmd>XcodebuildBuildRun<cr>",
      { desc = "Build & Run Project" }
    )
  end,
}
