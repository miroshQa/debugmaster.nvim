-- Additional layer on top of dap that provide missing functionality
-- This missing fucntionality is mainly:
-- 1. session change handling
-- 2. terminal per session handling
-- 3. breakpoints per session handling and store them

-- Adds new User events:
-- 1. DmBpChanged
-- 2. DmCurrentSessionChanged
-- 3. DmCurrentFrameChanged
-- 4. DmTermAttached, DmTermDetached
-- 5. DmSessionsChanged

local dap = require("dap")
local breakpoints = require("dap.breakpoints")
local api = vim.api

local SesssionsManager = {}

---@class dm.Session
---@field terminal number?
---@field breakpoints dm.Breakpoint[]
---@field config dap.Configuration

---@type table<dap.Session, dm.Session>
local sessions = {}

---@class dm.Breakpoint
---@field buf number
---@field condition string?
---@field line number
---@field hitCondition string
---@field logMessage string

local last_config = nil

local call_sessions_changed_event = function()
  api.nvim_exec_autocmds("User", { pattern = "DmSessionsChanged" })
end

dap.listeners.after.launch["random123"] = call_sessions_changed_event
dap.listeners.after.attach["random123"] = call_sessions_changed_event
dap.listeners.after.terminate["random123"] = call_sessions_changed_event
dap.listeners.after.disconnect["random123"] = call_sessions_changed_event

dap.defaults.fallback.terminal_win_cmd = function()
  local term_buf = api.nvim_create_buf(false, false)
  SesssionsManager.attach_term(term_buf)
  return term_buf, nil
end


dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
  local config = session.config
  last_config = config
  sessions[session] = sessions[session] or {}
  sessions[session].config = config
end

function SesssionsManager.launch()
end

---@param new dap.StackFrame
function SesssionsManager.set_current_frame(new)
  local s = assert(dap.session())
  s:_frame_set(new)
  api.nvim_exec_autocmds("User", { pattern = "DmCurrentFrameChanged" })
end

---comment
---@param frame dap.StackFrame
---@return boolean
function SesssionsManager.is_current_frame(frame)
  local s = dap.session()
  if s and s.current_frame then return s.current_frame.id == frame.id else return false end
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

function SesssionsManager.attach_term(buf)
  local s = dap.session()
  if not s then
    print("Can't attach terminal. No active session")
    return false
  elseif SesssionsManager.get_terminal() then
    print("Can't attach terminal. Already attached")
    return false
  end

  SesssionsManager.register_term(s, buf)
  api.nvim_exec_autocmds("User", { pattern = "DmTermAttached", data = { buf = buf } })

  api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
    callback = function(args)
      if args.buf == buf then
        api.nvim_exec_autocmds("User", { pattern = "DmTermDetached" })
      end
    end
  })
end

---@param s dap.Session? if nil then get for current
---@return number? terminal_buf
function SesssionsManager.get_terminal(s)
  s = s and s or dap.session()
  return (sessions[s] or {}).terminal
end

---@param condition string?
---@param hit_condition string?
---@param log_message string?
---@param replace_old boolean?
function SesssionsManager.toggle_breakpoint(condition, hit_condition, log_message, replace_old)
  dap.toggle_breakpoint(condition, hit_condition, log_message, replace_old)
  api.nvim_exec_autocmds("User", { pattern = "DmBpChanged" })
end

function SesssionsManager.clear_breakpoints()
  dap.clear_breakpoints()
  api.nvim_exec_autocmds("User", { pattern = "DmBpChanged" })
end

function SesssionsManager.frame_down()
  dap.down()
  api.nvim_exec_autocmds("User", { pattern = "DmCurrentFrameChanged" })
end

function SesssionsManager.frame_up()
  dap.up()
  api.nvim_exec_autocmds("User", { pattern = "DmCurrentFrameChanged" })
end

---@return dm.Breakpoint[]
function SesssionsManager.list_breakpoints()
  local bps = breakpoints.get()
  ---@type dm.Breakpoint[]
  local res = {}
  for buf, bp_list in pairs(bps) do
    for _, bp in ipairs(bp_list) do
      ---@type dm.Breakpoint
      local b = { buf = buf, condition = bp.condition, line = bp.line, hitCondition = bp.hitCondition, logMessage = bp
      .logMessage }
      table.insert(res, b)
    end
  end
  return res
end

---@param bps dm.Breakpoint[]
function SesssionsManager.remove_breakpoints(bps)
  for _, bp in ipairs(bps) do
    breakpoints.remove(bp.buf, bp.line)
    for _, session in pairs(dap.sessions()) do
      session:set_breakpoints(breakpoints.get(bp.buf))
    end
  end
  api.nvim_exec_autocmds("User", { pattern = "DmBpChanged" })
end

function SesssionsManager.set(opts, buf, line)
  breakpoints.set(opts, buf, line)
  api.nvim_exec_autocmds("User", { pattern = "DmBpChanged" })
end

function SesssionsManager.set_active(s)
  dap.set_session(s)
  api.nvim_exec_autocmds("User", { pattern = "DmCurrentSessionChanged" })
end

return SesssionsManager
