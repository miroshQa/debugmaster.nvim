-- Additional layer on top of dap that provide missing functionality
-- This missing fucntionality is mainly:
-- 1. session change handling
-- 2. terminal per session handling
-- 3. breakpoints per session handling and store them

-- Adds new User events:
-- 1. DmBpChanged
-- 2. DmSessionChanged
-- 3. DmCurrentFrameChanged
-- 4. DmTermAttached, DmTermDetached

---NOTE: Do we want to fork nvim-dap and take only protocol handling
-- and configurations framework from there and extending session functionality with this?
--- People probably will gonna hate me for this XD

local dap = require("dap")
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
---@field line number
---@field hitCondition string
---@field logMessage string

local last_config = nil

dap.defaults.fallback.terminal_win_cmd = function()
  local term_buf = api.nvim_create_buf(false, false)
  SesssionsManager.attach_term(term_buf)
  return term_buf, nil
end


dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
  local config = session.config
  last_config = config
  sessions[session] = { config = config }
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
    print("Can't attach term. No active session")
    return false
  elseif SesssionsManager.get_terminal() then
    print("Can't attach term. Already attached")
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

function SesssionsManager.toggle_breakpoint(...)
  dap.toggle_breakpoint(...)
  api.nvim_exec_autocmds("User", { pattern = "DmBpChanged" })
end

---@return dm.Breakpoint[]
function SesssionsManager.list_breakpoints()
  local bps = require("dap.breakpoints").get()
  ---@type dm.Breakpoint[]
  local res = {}
  for buf, bp_list in pairs(bps) do
    for _, bp in ipairs(bp_list) do
      ---@type dm.Breakpoint
      local b = { buf = buf, line = bp.line, hitCondition = bp.hitCondition, logMessage = bp.logMessage }
      table.insert(res, b)
    end
  end
  return res
end

function SesssionsManager.set_active(s)
  api.nvim_exec_autocmds("User", { pattern = "DmSessionChanged" })
  dap.set_session(s)
end

return SesssionsManager
