local autocmd = vim.api.nvim_create_autocmd

-- user event that loads after UIEnter + only if file buf is there
autocmd({ "UIEnter", "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("NvFilePost", { clear = true }),
  callback = function(args)
    local file = vim.api.nvim_buf_get_name(args.buf)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })

    if not vim.g.ui_entered and args.event == "UIEnter" then
      vim.g.ui_entered = true
    end

    if file ~= "" and buftype ~= "nofile" and vim.g.ui_entered then
      vim.api.nvim_exec_autocmds(
        "User",
        { pattern = "FilePost", modeline = false }
      )
      vim.api.nvim_del_augroup_by_name("NvFilePost")

      vim.schedule(function()
        vim.api.nvim_exec_autocmds("FileType", {})

        if vim.g.editorconfig then
          require("editorconfig").config(args.buf)
        end
      end)
    end
  end,
})

-- enable treesitter highlighting for any filetype with an installed parser
autocmd("FileType", {
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.syntax = ""
    end
  end,
})

-- auto-install treesitter parsers when opening a new filetype
autocmd("FileType", {
  callback = function()
    local ft = vim.bo.filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if lang and not pcall(vim.treesitter.language.inspect, lang) then
      local available = require("nvim-treesitter.config").get_available()
      if vim.list_contains(available, lang) then
        require("nvim-treesitter").install({ lang })
      end
    end
  end,
})

-- prevent . from triggering treesitter indents in ruby files
autocmd("FileType", {
  pattern = "ruby",
  callback = function()
    vim.opt_local.indentkeys:remove(".")
  end,
})
