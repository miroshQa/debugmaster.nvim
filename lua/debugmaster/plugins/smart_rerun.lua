local M = {}

local dap = require("dap")

local session_configs = {}

dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
  local config = session.config
  session_configs[session.id] = config
end


function M.run_last_cached()
  local session = require("dap").session()
  if not session then
    return print("No configuration available to re-run")
  end
  local config = assert(session_configs[session.id], "Active session exist, but config doesn't. Strange...")
  dap.run(config)
end

return M
