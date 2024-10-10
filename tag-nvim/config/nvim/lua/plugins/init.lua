---@type PluginOpts
return {
  { "stevearc/conform.nvim", enabled = false },
  { "nvchad/nvim-colorizer.lua", event = "BufEnter", config = true },
  {
    "nvim-telescope/telescope.nvim",
    opts = require("configs.telescope"),
    dependencies = {
      { "nvim-telescope/telescope-ui-select.nvim" },
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
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
      "nvimtools/none-ls.nvim",
      config = function()
        require("configs.null-ls").setup()
      end,
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
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true },
  { "tpope/vim-fugitive", cmd = "Git" },
  { "kchmck/vim-coffee-script", event = "BufReadPre *.coffee" },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      return require("configs.treesitter")
    end,
  },
  {
    "saecki/crates.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = { "BufRead Cargo.toml" },
    config = require("configs.crates").config,
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
    opts = require("configs.nvim-cmp"),
  },
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
  {
    "someone-stole-my-name/yaml-companion.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("yaml_schema")
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
    config = function()
      require("barbecue").setup({
        lead_custom_section = require("configs.barbecue").lead_custom_section,
      })
    end,
  },
  {
    "leoluz/nvim-dap-go",
  },
  {
    "simrat39/inlay-hints.nvim",
    event = "LspAttach",
    config = function()
      require("inlay-hints").setup({
        renderer = "inlay-hints/render/eol",
        eol = {
          -- whether to align to the extreme right or not
          right_align = false,

          parameter = {
            separator = ", ",
            format = function(hints)
              local adjusted_hint = hints:gsub(":", "")

              return string.format(" <- (%s)", adjusted_hint)
            end,
          },

          type = {
            separator = ", ",
            format = function(hints)
              local adjusted_hint = hints:gsub(": ", "")

              if string.find(adjusted_hint, ",") then
                adjusted_hint = "(" .. adjusted_hint .. ")"
              end

              return string.format(" => %s", adjusted_hint)
            end,
          },
        },
      })
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Recommended
    lazy = false, -- This plugin is already lazy
    config = function()
      local ih = require("inlay-hints")

      vim.g.rustaceanvim = {
        tools = {
          on_initialized = function(_)
            ih.set_all()
          end,
        },
        server = {
          on_attach = function(client, bufnr)
            local on_attach = require("nvchad.configs.lspconfig").on_attach
            on_attach(client, bufnr)
            ih.on_attach(client, bufnr)

            require("utils").setup_autoformat("Rust", bufnr)
          end,
        },
      }
    end,
  },
}
