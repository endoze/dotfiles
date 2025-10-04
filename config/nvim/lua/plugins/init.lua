---@type PluginOpts
return {
  { "stevearc/conform.nvim", enabled = false },
  {
    "windwp/nvim-autopairs",
    opts = {
      fast_wrap = {},
      disable_filetype = { "TelescopePrompt", "vim" },
      check_ts = true,
    },
    config = function(_, opts)
      local autopairs = require("nvim-autopairs")
      local ruby_rules = require("nvim-autopairs.rules.endwise-ruby")
      local lua_rules = require("nvim-autopairs.rules.endwise-lua")

      autopairs.setup(opts)
      autopairs.add_rules(ruby_rules)
      autopairs.add_rules(lua_rules)

      -- setup cmp for autopairs
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      return vim.tbl_deep_extend(
        "force",
        require("nvchad.configs.telescope"),
        require("configs.telescope")
      )
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
      telescope.load_extension("live_grep_args")
    end,
    dependencies = {
      { "nvim-telescope/telescope-ui-select.nvim" },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = function()
      return require("configs.nvim-tree")
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "nvimtools/none-ls.nvim",
        dependencies = {
          "nvimtools/none-ls-extras.nvim",
        },
        config = require("configs.null-ls"),
      },
    },
    config = function()
      require("nvchad.configs.lspconfig")
      require("configs.lspconfig")
    end,
  },
  {
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
  },
  { "Bilal2453/luvit-meta", lazy = true },
  {
    "FabijanZulj/blame.nvim",
    lazy = true,
    config = function(_, opts)
      local theme = require("nvconfig").base46.theme
      local theme_hex_table = require("base46.themes." .. theme).base_16
      opts.colors = vim.tbl_values(theme_hex_table)

      require("blame").setup(opts)
    end,
    opts = {
      date_format = "%Y.%m.%d",
      blame_options = { "-w" },
    },
    cmd = "BlameToggle",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      local conf = require("configs.treesitter")
      local nvconf = require("nvchad.configs.treesitter")

      return vim.tbl_deep_extend("force", nvconf, conf)
    end,
  },
  {
    "saecki/crates.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = { "BufRead Cargo.toml" },
    config = require("configs.crates"),
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      require("configs.nvim-dap")
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "nvim-neotest/nvim-nio",
    },
  },
  "theHamsta/nvim-dap-virtual-text",
  { "lukas-reineke/indent-blankline.nvim", enabled = true },
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      return vim.tbl_deep_extend(
        "force",
        require("nvchad.configs.cmp"),
        require("configs.nvim-cmp")
      )
    end,
  },
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
  {
    "cenk1cenk2/schema-companion.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    config = function()
      require("schema-companion").setup({
        log_level = vim.log.levels.INFO,
      })
    end,
  },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    event = "LspAttach",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons",
    },
    config = require("configs.barbecue"),
  },
  {
    "leoluz/nvim-dap-go",
  },
  {
    "endoze/inlay-hints.nvim",
    branch = "fix-deprecation-warnings-for-nvim-0.11",
    event = "LspAttach",
    config = require("configs.inlay-hints"),
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^6", -- Recommended
    lazy = false, -- This plugin is already lazy
    config = require("configs.rustaceanvim"),
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },
  "stevearc/dressing.nvim",
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      ---@diagnostic disable:missing-fields
      require("notify").setup({
        stages = "fade_in_slide_out",
        timeout = 3000,
        background_colour = "#000000",
        render = "wrapped-compact",
        max_width = 400,
      })

      vim.notify = require("notify")
    end,
  },
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = require("configs.trouble"),
  },
  {
    "apple/pkl-neovim",
    ft = "pkl",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        build = function(_)
          vim.cmd("TSUpdate")
        end,
      },
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
    },
    build = function()
      require("pkl-neovim").init()

      vim.cmd("TSInstall! pkl")
    end,
    config = function()
      require("luasnip.loaders.from_snipmate").lazy_load()
    end,
  },
  {
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
    config = require("configs.xcodebuild"),
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
}
