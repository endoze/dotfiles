local NvimDapRuby = {}

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

local function setup_ruby_adapter(dap)
  dap.adapters.rdbg = function(callback, config)
    local waiting = config.waiting or 500

    local parsedAddress = parseAddress(config.debugPort)

    vim.defer_fn(function()
      callback(parsedAddress)
    end, waiting)
  end
end

function NvimDapRuby.setup()
  local dap = require("dap")
  setup_ruby_adapter(dap)
end

return NvimDapRuby
