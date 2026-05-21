-- User commands replacing those previously provided by nvim-lspconfig,
-- adapted for native vim.lsp.config / vim.lsp.enable.

local function client_name_complete(arg_lead)
  local seen, results = {}, {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    if not seen[client.name] and client.name:find(arg_lead, 1, true) == 1 then
      seen[client.name] = true
      table.insert(results, client.name)
    end
  end
  return results
end

vim.api.nvim_create_user_command("LspRestart", function(info)
  local names, seen = {}, {}

  local function add(name)
    if not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end

  if #info.fargs > 0 then
    for _, name in ipairs(info.fargs) do
      add(name)
    end
  else
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      add(client.name)
    end
  end

  -- Capture attached buffers per name, then stop the clients.
  local bufs_per_name = {}
  for _, name in ipairs(names) do
    bufs_per_name[name] = {}
    for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
      for buf in pairs(client.attached_buffers) do
        table.insert(bufs_per_name[name], buf)
      end
      client:stop()
    end
  end

  -- Wait (up to 5s) for clients to fully exit before starting fresh ones.
  -- rust-analyzer and other heavy servers can take a moment to shut down.
  local function all_stopped()
    for _, name in ipairs(names) do
      if #vim.lsp.get_clients({ name = name }) > 0 then
        return false
      end
    end
    return true
  end

  vim.defer_fn(function()
    vim.wait(5000, all_stopped, 50)

    -- Re-fire FileType on each previously-attached buffer; the autocmd
    -- registered by vim.lsp.enable will re-attach the appropriate client.
    local fired = {}
    for _, bufs in pairs(bufs_per_name) do
      for _, buf in ipairs(bufs) do
        if not fired[buf] and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          fired[buf] = true
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
        end
      end
    end
  end, 100)
end, {
  nargs = "*",
  desc = "Restart LSP clients (current buffer's by default)",
  complete = client_name_complete,
})

vim.api.nvim_create_user_command("LspInfo", function()
  vim.cmd("checkhealth vim.lsp")
end, { desc = "Show LSP info" })

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd("tabnew " .. vim.lsp.log.get_filename())
end, { desc = "Open LSP log file" })

vim.api.nvim_create_user_command("LspStart", function(info)
  for _, name in ipairs(info.fargs) do
    vim.lsp.enable(name, true)
  end
end, {
  nargs = "+",
  desc = "Enable LSP config(s)",
})

vim.api.nvim_create_user_command("LspStop", function(info)
  local targets = {}
  for _, name in ipairs(info.fargs) do
    targets[name] = true
  end

  local clients = #info.fargs == 0
    and vim.lsp.get_clients({ bufnr = 0 })
    or vim.lsp.get_clients()

  for _, client in ipairs(clients) do
    if #info.fargs == 0 or targets[client.name] then
      client:stop()
    end
  end
end, {
  nargs = "*",
  desc = "Stop LSP client(s) (current buffer's by default)",
  complete = client_name_complete,
})
