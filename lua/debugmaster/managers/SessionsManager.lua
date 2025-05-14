local dap = require("dap")

-- Also will be used for mantaining breakpoints per session

local SesssionsManager = {}


local session_configs = {}
local last_config = nil

dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
  local config = session.config
  last_config = config
  session_configs[session.id] = config
end

function SesssionsManager.run_last_cached()
  local session = require("dap").session()
  if session then
    local config = assert(session_configs[session.id], "Active session exist, but config doesn't. Strange...")
    return dap.run(config)
  elseif last_config then
    return dap.run(last_config)
  end
  print("No configuration available to re-run")
end

return SesssionsManager
