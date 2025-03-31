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
      key = "P",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.terminal)
      end,
      desc = "Open program output (terminal)",
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
      key = "B",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:set_active_with_open(state.breakpoints)
      end,
      desc = "Open breakpoints",
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
        widgets.cursor_float(widgets.frames)
      end,
      desc = "frames float"
    },
    {
      key = "dt",
      action = function()
        local widgets = require("dap.ui.widgets")
        widgets.cursor_float(widgets.threads)
      end,
      desc = "threads float"
    },
    {
      key = "di",
      action = function()
        pcall(require('dap.ui.widgets').hover)
      end,
      desc = "Inspect variable under cursor",
    },
    {
      key = "ds",
      action = function()
        local widgets = require("dap.ui.widgets")
        widgets.cursor_float(widgets.sessions)
      end,
      desc = "debug sessions",
    }
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
