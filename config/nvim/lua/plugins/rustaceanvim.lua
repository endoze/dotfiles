return {
  "mrcjkb/rustaceanvim",
  version = "^8",
  ft = { "rust" },
  config = function()
    local ih = require("inlay-hints")
    local helpers = require("lsp.helpers")

    vim.g.rustaceanvim = {
      tools = {
        on_initialized = function(_)
          ih.set_all()
        end,
        hover_actions = {
          replace_builtin_hover = false,
          auto_focus = false,
        },
      },
      server = {
        settings = function(project_root, default_settings)
          local merged = vim.deepcopy(default_settings)
          local local_file = project_root .. "/.rust-analyzer.json"

          if vim.fn.filereadable(local_file) == 1 then
            local content = table.concat(vim.fn.readfile(local_file), "\n")
            local ok, data = pcall(vim.fn.json_decode, content)

            if ok and type(data) == "table" then
              merged = vim.tbl_deep_extend("force", merged, data)
            end
          end

          return merged
        end,
        on_attach = helpers.create_on_attach({
          lsp_name = "Rust",
          autoformat = true,
          on_attach_extra = function(client, bufnr)
            ih.on_attach(client, bufnr)
          end,
        }),
      },
    }
  end,
}
