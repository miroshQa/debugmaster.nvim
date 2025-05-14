local api = vim.api
local utils = require("debugmaster.utils")

---Debug Mode Manager
local DmManager = {}

--- [[DEFAULT KEYMAPS]]

---@class dm.KeySpec
---@field key string
---@field action fun()
---@field desc string?
---@field nowait boolean?
---@field group string?
---@field modes table | nil Table with modes like in vim.keymap.set. {"n"} by default


---@class dm.MappingsGroup
---@field name string? Group name. Not shown in HelpPopup if nil
---@field hlgroup string? Define name highlight color in HelpPopup
---@field mappings dm.KeySpec[]

---@type dm.MappingsGroup
local move_debugger = {
  name = "MOVE DEBUGGER",
  hlgroup = "ERROR",
  -- the main goal when developing keymaps for debug mode is to not override normal mode motions
  -- We want to our DEBUG mode be "constant". So we can freely move and can't edit text
  mappings = {
    {
      key = "o",
      action = function() require("dap").step_over() end,
      desc = "Step over. Works with count (Try to type '5o')",
    },
    {
      key = "m",
      action = function() require("dap").step_into() end,
      desc = "Step into (mine deeper)",
    },
    {
      key = "q",
      action = function() require("dap").step_out() end,
      desc = "Step out ([q]uit current stack frame)",
    },
    {
      key = "c",
      nowait = true,
      action = function()
        require("dap").continue()
      end,
      desc = "Continue or start debug session",
    },
    {
      key = "r",
      action = function() require("dap").run_to_cursor() end,
      desc = "Run to cursor",
    },
  }
}

---@type dm.MappingsGroup
local sidepanel = {
  name = "SIDEPANEL",
  hlgroup = "STRING",
  mappings = {
    {
      key = "u",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle()
      end,
      desc = "Toggle ui",
    },
    {
      key = "U",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_layout()
      end,
      desc = "Toggle ui float mode",
    },
    {
      key = "S",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.scopes)
      end,
      desc = "Open scopes (global, local, etc variables)",
    },
    {
      key = "T",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.terminal)
      end,
      desc = "Open terminal",
    },
    {
      key = "R",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.repl)
      end,
      desc = "Open repl",
    },
    {
      key = "H",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.help)
      end,
      desc = "Open help",
    },
    {
      key = "}",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:rotate(1)
      end,
      desc = "Rotate sidenapel clockwise",
    },
    {
      key = "{",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:rotate(-1)
      end,
      desc = "Rotate sidenapel anticlockwise",
    },
    {
      key = "-",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:resize(-10)
      end,
      desc = "Decrease sidenapel size",
    },
    {
      key = "+",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:resize(10)
      end,
      desc = "Increase sidepanel size",
    }
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
        local widgets = require("dap.ui.widgets")
        pcall(widgets.cursor_float, widgets.frames)
        utils.register_to_close_on_leave(api.nvim_get_current_win())
      end,
      desc = "Frames widget"
    },
    {
      key = "dt",
      action = function()
        local widgets = require("dap.ui.widgets")
        pcall(widgets.cursor_float, widgets.threads)
        utils.register_to_close_on_leave(api.nvim_get_current_win())
      end,
      desc = "Threads widget"
    },
    {
      key = "ds",
      action = function()
        local widgets = require("dap.ui.widgets")
        local ok, sessions = pcall(widgets.cursor_float, widgets.sessions)
        if not ok then
          return
        end
        utils.register_to_close_on_leave(api.nvim_get_current_win())
        vim.keymap.set("n", "<CR>", vim.schedule_wrap(function()
          require('dap.ui').trigger_actions({ mode = 'first' })
          api.nvim_exec_autocmds("User", { pattern = "DapSessionChanged" })
          require("dap").focus_frame()
        end), { expr = true, buffer = sessions.buf })
      end,
      desc = "Debug sessions widget",
    },
    {
      key = "db",
      action = function()
        local state = require("debugmaster.state")
        utils.open_floating_window(state.breakpoints.buf, {
          min_width = 60,
          additional_height = 3,
        })
        utils.register_to_close_on_leave(api.nvim_get_current_win())
        vim.bo[state.breakpoints.buf].filetype = "dap-float"
      end,
      desc = "Breakpoints widget"
    },
    {
      key = "I",
      modes = { "n", "v" },
      action = function()
        pcall(require('dap.ui.widgets').hover)
        utils.register_to_close_on_leave(api.nvim_get_current_win())
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
    {
      key = "t",
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    {
      key = "da",
      action = function()
        require("dap").clear_breakpoints()
        print("All breakpoints removed")
      end,
      desc = "Delete all breakpoints",
    },
    {
      key = "dc",
      action = function()
        local condition = vim.fn.input({ prompt = "Enter breakpoing condition: " })
        if condition ~= "" then
          require("dap").toggle_breakpoint(condition)
        end
      end,
      desc = "Add conditional breakpoint",
    },
    {
      key = "[b",
      action = function() require("debugmaster.utils").gotoBreakpoint("prev") end,
      desc = "Go to previous breakpoint"
    },
    {
      key = "]b",
      action = function() require("debugmaster.utils").gotoBreakpoint("next") end,
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
      action = function()
        require("debugmaster.managers.SessionsManager").run_last_cached()
      end
    },
    {
      key = "dn",
      action = function()
        vim.cmd("DapNew")
      end,
      desc = "Debug start new sessions",
    },
    {
      key = "dq",
      action = function()
        require("dap").terminate()
        local state = require("debugmaster.state")
        state.sidepanel:close()
      end,
      desc = "Quit debug"
    },
    {
      key = "[s",
      action = function() require("dap").down() end,
      desc = "Go to previous stack frame"
    },
    {
      key = "]s",
      action = function() require("dap").up() end,
      desc = "Go to next stack frame"
    },
    {
      key = "dj",
      action = function() require("dap").focus_frame() end,
      desc = "Jump to the current stack frame"
    },
    {
      key = "x",
      action = function()
        local state = require("debugmaster.state")
        local text = vim.fn.getreg('"')
        require("dap").repl.execute("\n" .. text)
        state.sidepanel:set_active_with_open(state.repl)
        api.nvim_buf_call(state.repl.buf, function()
          vim.cmd("normal G")
        end)
      end,
      desc = "Execute last yanked or deleted text in the repl",
    },
    {
      key = "dm",
      action = function()
        local state = require("debugmaster.state")
        local terminal = state.terminal
        local buf = api.nvim_get_current_buf()
        local is_term = api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal'
        if not is_term then
          return print("Current buffer isn't terminal. Can't move to the Terminal section")
        end
        local ok = terminal:attach_terminal_to_current_session(buf)
        if ok then
          for _, win in ipairs(utils.get_windows_for_buffer(buf)) do
            api.nvim_win_close(win, true)
          end
          state.sidepanel:open()
          state.sidepanel:set_active(terminal)
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
--- [[DEFAULT KEYMAPS END]]


local active = false
local originals_saving_required = true

---@class dm.OrignalKeymap
---@field callback function?
---@field rhs string?
---@field desc string?
---@field silent boolean?
---@type table<string, table<string, dm.OrignalKeymap>> [mode: {key: OriginalKeymap}, ...]
local originals = {}

local function save_original_keymaps()
  local all = { n = api.nvim_get_keymap("n"), v = api.nvim_get_keymap("v") }
  local lhs_to_map = {}

  for mode, mappings in pairs(all) do
    lhs_to_map[mode] = {}
    for _, mapping in ipairs(mappings) do
      lhs_to_map[mode][mapping.lhs] = mapping
    end
  end

  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      for _, mode in ipairs(mapping.modes or { "n" }) do
        local key = mapping.key
        if not originals[mode] then
          originals[mode] = {}
        end
        local orig = lhs_to_map[mode][key] or {}
        originals[mode][key] = {
          callback = orig.callback,
          rhs = orig.rhs,
          desc = orig.desc,
          silent = orig.silent,
        }
      end
    end
  end
end

function DmManager.enable()
  if active then
    return
  end
  if originals_saving_required then
    originals = {}
    save_original_keymaps()
    originals_saving_required = false
  end
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local action = mapping.action
      for _, mode in ipairs(mapping.modes or { "n" }) do
        vim.keymap.set(mode, mapping.key, action, { nowait = mapping.nowait })
      end
    end
  end
  api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = true } })
  active = true
end

function DmManager.disable()
  if not active then
    return
  end
  active = false
  for _, group in ipairs(groups) do
    for _, mapping in ipairs(group.mappings) do
      local key = mapping.key
      for _, mode in ipairs(mapping.modes or { "n" }) do
        local orig = originals[mode][key]
        local rhs = orig.callback or orig.rhs or key
        vim.keymap.set(mode, key, rhs, {
          desc = orig.desc,
          silent = orig.silent,
        })
      end
    end
  end
  api.nvim_exec_autocmds("User", { pattern = "DebugModeChanged", data = { enabled = false } })
end

function DmManager.toggle()
  (active and DmManager.disable or DmManager.enable)()
end

function DmManager.is_active()
  return active
end

function DmManager.get_groups()
  -- if user required groups he can change keymaps,
  -- hence we should updat originals on next debug mode activate
  originals_saving_required = true
  return groups
end

return DmManager
