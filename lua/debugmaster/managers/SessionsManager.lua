-- Additional layer on top of dap.session() that provide missing functionality
-- like breapoints, terminals per session, session changed event

local dap = require("dap")
local api = vim.api

local SesssionsManager = {}

---@class dm.Session
---@field terminal number?
---@field breakpoints any[]?
---@field config dap.Configuration

---@type table<dap.Session, dm.Session>
local sessions = {}

local last_config = nil

dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
  local config = session.config
  last_config = config
  sessions[session] = { config = config }
end

function SesssionsManager.run_last_cached()
  local session = require("dap").session()
  if session then
    local config = assert(sessions[session], "Active session exist, but config doesn't. Strange...")
    return dap.run(config.config)
  elseif last_config then
    return dap.run(last_config)
  end
  print("No configuration available to re-run")
end

---@param s dap.Session
---@param buf any
function SesssionsManager.register_term(s, buf)
  local info = sessions[s] or {}
  info.terminal = buf
  sessions[s] = info
end

---@return dm.Session? | table
function SesssionsManager.get(s)
  return sessions[s] or {}
end

function SesssionsManager.set_breakpoints(s)
end

function SesssionsManager.get_breakpoints(s)
end

function SesssionsManager.set_active()
  api.nvim_exec_autocmds("User", { pattern = "DapSessionChanged" })
end

return SesssionsManager
