local api = vim.api
local view = require("debugmaster.lib.view")
local dap = require("dap")
local utils = require("debugmaster.lib.utils")
local submodes = require("debugmaster.lib.submodes")
local SessionsManager = require("debugmaster.managers.SessionsManager")
local UiManager = require("debugmaster.managers.UiManager")

---Debug Mode Manager
local DmManager = {}

---@class dm.MappingSpec
---@field key string
---@field desc string
---@field action fun()
---@field modes string[]? {"n"} - by default

---@class dm.MappingsGroup
---@field name string Group name
---@field hlgroup string Define name highlight color in help widget
---@field mappings dm.MappingSpec[]


---@type dm.MappingsGroup
local move_debugger = {
  name = "MOVE DEBUGGER",
  hlgroup = "ERROR",
  mappings = {
    { key = "o", action = dap.step_over,     desc = "Step over. Works with count (Try to type '5o')" },
    { key = "m", action = dap.step_into,     desc = "Step into (mine deeper)" },
    { key = "q", action = dap.step_out,      desc = "Step out ([q]uit current stack frame)" },
    { key = "c", action = dap.continue,      desc = "Continue or start debug session" },
    { key = "r", action = dap.run_to_cursor, desc = "Run to cursor" },
  }
}

---@type dm.MappingsGroup
local sidepanel = {
  name = "SIDEPANEL",
  hlgroup = "STRING",
  mappings = {
    { key = "u", action = function() UiManager.sidepanel:toggle() end,                                  desc = "Toggle ui", },
    { key = "U", action = function() UiManager.sidepanel:toggle_layout() end,                           desc = "Toggle ui float mode" },
    { key = "S", action = function() UiManager.sidepanel:set_active_with_open(UiManager.dashboard) end, desc = "Open state", },
    { key = "T", action = function() UiManager.sidepanel:set_active_with_open(UiManager.terminal) end,  desc = "Open terminal", },
    { key = "R", action = function() UiManager.sidepanel:set_active_with_open(UiManager.repl) end,      desc = "Open repl", },
    { key = "H", action = function() UiManager.sidepanel:set_active_with_open(UiManager.help) end,      desc = "Open help" },
    { key = "}", action = function() UiManager.sidepanel:rotate(1) end,                                 desc = "Rotate sidenapel clockwise" },
    { key = "{", action = function() UiManager.sidepanel:rotate(-1) end,                                desc = "Rotate sidenapel anticlockwise" },
    { key = "-", action = function() UiManager.sidepanel:resize(-10) end,                               desc = "Decrease sidenapel size" },
    { key = "+", action = function() UiManager.sidepanel:resize(10) end,                                desc = "Increase sidepanel size" }
  }
}

---@type dm.MappingsGroup
local float_widgets = {
  name = "FLOAT WIDGETS",
  hlgroup = "STATEMENT",
  mappings = {
    {
      key = "df",
      action = function()
        UiManager.threads.view:refresh()
        view.popup.new { buf = UiManager.threads.view.buf }
      end,
      desc = "Frames and threads widget"
    },
    {
      key = "ds",
      action = function()
        UiManager.sessions.view:refresh()
        view.popup.new { buf = UiManager.sessions.view.buf }
      end,
      desc = "Debug sessions widget",
    },
    {
      key = "db",
      action = function()
        UiManager.breakpoints.view:refresh()
        view.popup.new { buf = UiManager.breakpoints.view.buf }
      end,
      desc = "Breakpoints widget",
    },
    {
      key = "I",
      modes = { "n", "v" },
      action = function()
        pcall(require('dap.ui.widgets').hover)
        view.close_on_q(view.close_on_leave(api.nvim_get_current_win()))
      end,
      desc = "Inspect variable or visually selected expression",
    },
  }
}

---@type dm.MappingsGroup
local breakpoings_group = {
  name = "BREAKPOINTS",
  hlgroup = "Boolean",
  mappings = {
    { key = "t",  action = SessionsManager.toggle_breakpoint, desc = "Toggle breakpoint", },
    { key = "da", action = SessionsManager.clear_breakpoints, desc = "Delete all breakpoints", },
    {
      key = "dc",
      action = function()
        local condition = vim.fn.input({ prompt = "Enter breakpoing condition: " })
        if condition ~= "" then
          SessionsManager.toggle_breakpoint(condition)
        end
      end,
      desc = "Add conditional breakpoint",
    },
    {
      key = "[b",
      action = function() require("debugmaster.lib.utils").gotoBreakpoint("prev") end,
      desc = "Go to previous breakpoint"
    },
    {
      key = "]b",
      action = function() require("debugmaster.lib.utils").gotoBreakpoint("next") end,
      desc = "Go to next breakpoint"
    },
  },
}

---@type dm.MappingsGroup
local misc_group = {
  name = "MISCELANOUS",
  hlgroup = "TYPE",
  mappings = {
    {
      key = "dr",
      desc = "Restart the current session or rerun last if none",
      action = SessionsManager.run_last_cached,
    },
    { key = "dn", action = function() vim.cmd("DapNew") end, desc = "Debug start new sessions", },
    {
      key = "Q",
      action = function()
        dap.terminate()
        UiManager.sidepanel:close()
      end,
      desc = "Quit debug"
    },
    { key = "[s", action = SessionsManager.frame_down,       desc = "Go to previous stack frame" },
    { key = "]s", action = SessionsManager.frame_up,         desc = "Go to next stack frame" },
    { key = "dj", action = dap.focus_frame,                  desc = "Jump to the current stack frame" },
    {
      key = "x",
      action = function()
        local text = vim.fn.getreg('"')
        dap.repl.execute("\n" .. text)
        UiManager.sidepanel:set_active_with_open(UiManager.repl)
        api.nvim_buf_call(UiManager.repl.buf, function()
          vim.cmd("normal G")
        end)
      end,
      desc = "Execute last yanked or deleted text in the repl",
    },
    {
      key = "dm",
      action = function()
        local terminal = UiManager.terminal
        local buf = api.nvim_get_current_buf()
        local is_term = api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal'
        if not is_term then
          return print("Current buffer isn't terminal. Can't move to the Terminal section")
        end
        local ok = SessionsManager.attach_term(buf)
        if ok then
          for _, win in ipairs(utils.get_windows_for_buffer(buf)) do
            api.nvim_win_close(win, true)
          end
          UiManager.sidepanel:open()
          UiManager.sidepanel:set_active(terminal)
        end
      end,
      desc = "Move current terminal to the 'Terminal' segment"
    },
  }
}

local groups = {
  move_debugger,
  breakpoings_group,
  sidepanel,
  float_widgets,
  misc_group,
}

local reload_required = true

local mappings = {}
for _, group in ipairs(groups) do
  for _, mapping in ipairs(group.mappings) do
    for _, mode in ipairs(mapping.modes or { "n" }) do
      ---@type dm.lib.Submodes.Mapping
      local new = {
        lhs = mapping.key,
        mode = mode,
        rhs = "",
        opts = {
          callback = mapping.action,
          desc = mapping.desc,
        }
      }
      table.insert(mappings, new)
    end
  end
end

DmManager.dmode = submodes.new {
  name = "Debug",
  mappings = mappings,
}

function DmManager.get_groups()
  -- if user required groups he can change keymaps,
  -- hence we should updat originals on next debug mode activate
  reload_required = true
  return groups
end

return DmManager
