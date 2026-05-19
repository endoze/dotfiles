return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      lua = { "selene" },
      javascript = { "eslint" },
      javascriptreact = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
    }

    -- Walk upward from the current buffer to find a project-local
    -- selene.toml; fall back to the global one in ~/.config/selene/.
    -- nvim-lint evaluates function-valued args at lint time, so this
    -- resolves per-buffer. We must pass --config explicitly because nvim-
    -- lint pipes via stdin and gives selene no path context for its own
    -- config discovery.
    lint.linters.selene.args = {
      "--display-style",
      "json",
      "--config",
      function()
        local found = vim.fs.find({ "selene.toml" }, {
          upward = true,
          path = vim.api.nvim_buf_get_name(0),
        })[1]
        return found or vim.fn.expand("~/.config/selene/selene.toml")
      end,
      "-",
    }

    -- Prefer the project-local eslint from node_modules/.bin so we don't
    -- depend on a global install. Falls back to whatever "eslint" resolves
    -- to on $PATH.
    lint.linters.eslint.cmd = function()
      local found = vim.fs.find("node_modules/.bin/eslint", {
        upward = true,
        path = vim.api.nvim_buf_get_name(0),
        type = "file",
      })[1]
      return found or "eslint"
    end

    local eslint_root_files = {
      "eslint.config.js",
      "eslint.config.mjs",
      "eslint.config.cjs",
      ".eslintrc",
      ".eslintrc.js",
      ".eslintrc.json",
      ".eslintrc.yml",
      ".eslintrc.yaml",
    }

    local js_filetypes = {
      javascript = true,
      javascriptreact = true,
      typescript = true,
      typescriptreact = true,
    }

    local function has_eslint_config(bufnr)
      local path = vim.api.nvim_buf_get_name(bufnr)
      if path == "" then
        return false
      end
      local found = vim.fs.find(eslint_root_files, {
        upward = true,
        path = path,
      })[1]
      return found ~= nil
    end

    vim.api.nvim_create_autocmd(
      { "BufReadPost", "BufWritePost", "InsertLeave" },
      {
        group = vim.api.nvim_create_augroup("UserNvimLint", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if js_filetypes[ft] and not has_eslint_config(args.buf) then
            return
          end
          lint.try_lint()
        end,
      }
    )
  end,
}
