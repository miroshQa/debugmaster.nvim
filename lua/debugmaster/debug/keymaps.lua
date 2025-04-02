local utils = require("debugmaster.utils")
local M = {}

---@class dm.KeySpec
---@field key string
---@field action fun()
---@field desc string?
---@field nowait boolean?
---@field group string?

---@class dm.MappingsGroup
---@field name string? Group name. Not shown in HelpPopup if nil
---@field hlgroup string? Define name highlight color in HelpPopup
---@field mappings dm.KeySpec[]

---@type dm.MappingsGroup
local move_debugger_group = {
  name = "MOVE DEBUGGER",
  hlgroup = "ERROR",
  -- the main goal when developing keymaps for debug mode is to not override normal mode motions
  -- We want to our DEBUG mode be "constant". So we can freely move and can't edit text
  mappings = {
    {
      key = "D",
      action = function() require("dap").step_into() end,
      desc = "Step into (go [D]eeper)",
    },
    {
      key = "L",
      action = function() require("dap").step_over() end,
      desc = "Step over (next [L]ine)",
    },
    {
      key = "q",
      action = function() require("dap").step_out() end,
      desc = "Step out ([q]uit current stack frame)",
    },
    {
      key = "c",
      nowait = true,
      action = function() require("dap").continue() end,
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
local ui_group = {
  name = "DEBUG UI INTERACTION",
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
      key = "df",
      action = function()
        local widgets = require("dap.ui.widgets")
        pcall(widgets.cursor_float, widgets.frames)
        utils.register_to_close_on_leave(vim.api.nvim_get_current_win())
      end,
      desc = "frames float"
    },
    {
      key = "dt",
      action = function()
        local widgets = require("dap.ui.widgets")
        pcall(widgets.cursor_float, widgets.threads)
        utils.register_to_close_on_leave(vim.api.nvim_get_current_win())
      end,
      desc = "threads float"
    },
    {
      key = "ds",
      action = function()
        local widgets = require("dap.ui.widgets")
        local ok, sessions = pcall(widgets.cursor_float, widgets.sessions)
        if not ok then
          return
        end
        utils.register_to_close_on_leave(vim.api.nvim_get_current_win())
        vim.keymap.set("n", "<CR>", vim.schedule_wrap(function()
          require('dap.ui').trigger_actions({ mode = 'first' })
          vim.api.nvim_exec_autocmds("User", { pattern = "DapSessionChanged" })
          require("dap").focus_frame()
        end), { expr = true, buffer = sessions.buf })
      end,
      desc = "debug sessions",
    },
    {
      key = "db",
      action = function()
        local state = require("debugmaster.state")
        utils.open_floating_window(state.breakpoints.buf)
        utils.register_to_close_on_leave(vim.api.nvim_get_current_win())
        vim.bo[state.breakpoints.buf].filetype = "dap-float"
      end,
      desc = "Float breakpoints"
    },
    {
      key = "di",
      action = function()
        pcall(require('dap.ui.widgets').hover)
        utils.register_to_close_on_leave(vim.api.nvim_get_current_win())
      end,
      desc = "Inspect variable under cursor",
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
      desc = "Rerun last session with cached config",
      action = function()
        require("debugmaster.plugins.smart_rerun").run_last_cached()
      end
    },
    {
      key = "dR",
      desc = "Rerun last session with new params",
      action = function()
        require("dap").run_last()
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
      key = "dp",
      action = function()
        vim.cmd("DapPause")
      end,
      desc = "Pause the current thread or pick a thread to pause",
    },
    {
      key = "Q",
      action = function()
        require("dap").terminate()
        local state = require("debugmaster.state")
        state.sidepanel:close()
      end,
      desc = "Quit debug (terminate debug)"
    },
    {
      key = "dF",
      action = function() require("dap").focus_frame() end,
      desc = "Focus current frame"
    },
    {
      key = "[f",
      action = function() require("dap").down() end,
      desc = "Go to previous frame"
    },
    {
      key = "]f",
      action = function() require("dap").up() end,
      desc = "Go to next frame"
    },
    {
      key = "dm",
      action = function()
        local state = require("debugmaster.state")
        local terminal = state.terminal
        local buf = vim.api.nvim_get_current_buf()
        local is_term = vim.api.nvim_get_option_value('buftype', { buf = buf }) == 'terminal'
        if not is_term then
          return print("Current buffer isn't terminal. Can't move to the Terminal section")
        end
        local ok = terminal:attach_terminal_to_current_session(buf)
        if ok then
          for _, win in ipairs(utils.get_windows_for_buffer(buf)) do
            vim.api.nvim_win_close(win, true)
          end
          state.sidepanel:open()
          state.sidepanel:set_active(terminal)
        end
      end,
      desc = "Move current terminal to the 'Terminal' segment"
    },
  }
}

---@type dm.MappingsGroup
local nodesc_group = {
  mappings = {
    -- Debug mode is constant, we don't want to accidentally edit buffer
    {
      key = "J",
      action = function() end
    },
    {
      key = "p",
      action = function() end
    },
  }
}

---@type dm.MappingsGroup[]
M.groups = {
  move_debugger_group,
  breakpoings_group,
  ui_group,
  misc_group,
  nodesc_group,
}

---Give the reference to the key entry so you can remap it to something else
---Throws an error if the key doesn't exist
---@return dm.KeySpec
function M.get(key)
  for _, group in ipairs(M.groups) do
    for _, mapping in ipairs(group.mappings) do
      if mapping.key == key then
        return mapping
      end
    end
  end
  error("Key doesn't exist")
end

return M
