--- NvimDapRuby: Sets up ruby dap adaptor for rdbg
local NvimDapRuby = {}

--- Parses the address and returns type, host, and port information.
--- @param address string|nil The address is either a Unix domain socket, host:port, or nil/empty.
--- @return {type: string, host: string|nil, port: string|nil} table A table containing type, host, and port information.
local function parseAddress(address)
  if not address then
    return { type = "server", host = vim.env.RUBY_DEBUG_HOST }
  end

  local ip, port = address:match("([^:]+):(.+)")

  if ip and port then
    return { type = "server", host = ip, port = port }
  else
    return { type = "server", port = address }
  end
end

--- Configure dap.adapter specifically for rdbg debugging
--- @param dap any
local function setup_ruby_adapter(dap)
  dap.adapters.rdbg = function(callback, config)
    local waiting = config.waiting or 500

    local parsedAddress = parseAddress(config.debugPort)

    -- Wait for rdbg to start
    vim.defer_fn(function()
      callback(parsedAddress)
    end, waiting)
  end
end

--- Set up nvim-dap-ruby plugin
function NvimDapRuby.setup()
  local dap = require("dap")
  setup_ruby_adapter(dap)
end

return NvimDapRuby
