---@type UIConfig
return {
  statusline = {
    theme = "vscode_colored",
    order = {
      "mode",
      "file",
      "git",
      "%=",
      "lsp_msg",
      "%=",
      "diagnostics",
      "lsp",
      "cursor",
      "cwd",
    },
    modules = {
      lsp = function()
        local stbufnr = require("nvchad.stl.utils").stbufnr

        if rawget(vim, "lsp") then
          for _, client in ipairs(vim.lsp.get_clients()) do
            if
              client.attached_buffers[stbufnr()]
              and client.name ~= "null-ls"
              and client.name ~= "copilot"
            then
              return "%#St_Lsp#"
                .. (
                  (vim.o.columns > 100 and "   LSP ~ " .. client.name .. " ")
                  or "   LSP "
                )
            end
          end
        end

        return ""
      end,
    },
  },
  -- lazyload it when there are 1+ buffers
  tabufline = {
    enabled = true,
    lazyload = true,
    overriden_modules = nil,
  },
  cmp = {
    style = "default",
  },
}
