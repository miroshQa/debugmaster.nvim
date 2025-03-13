local utils = require("debugmaster.utils")
local M = {}

---@class dm.KeySpec
---@field key string
---@field action fun()
---@field desc string?
---@field nowait boolean?
---@field group string?
---@field waybardesc string?

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
      key = "K",
      action = function() require("dap").step_into() end,
      desc = "Step into",
    },
    {
      key = "L",
      action = function() require("dap").step_over() end,
      desc = "Step over (next line)",
    },
    {
      key = "q",
      action = function() require("dap").step_out() end,
      desc = "Step out (quit frame)",
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
local inspect_group = {
  name = "INSPECT DEBUG STATE",
  hlgroup = "STRING",
  mappings = {
    {
      key = "S",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_active_with_open(state.scopes)
      end,
      desc = "Open scopes (global, local, etc variables)",
      waybardesc = "[S]copes"
    },
    {
      key = "P",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_active_with_open(state.terminal)
      end,
      desc = "Open program output (terminal)",
      waybardesc = "[P]rogram"
    },
    {
      key = "R",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_active_with_open(state.repl)
      end,
      desc = "Open repl",
      waybardesc = "[R]epl"
    },
    {
      key = "L",
      action = function()
      end,
      desc = "Open dap logs (in case something went wrong with debugger)",
      waybardesc = "[L]og"
    },
    {
      key = "u",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle()
      end,
      desc = "Toggle debugger interface",
    },
    {
      key = "U",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_layout()
      end,
      desc = "Toggle float debugger interface mode",
    },
    {
      key = "I",
      action = function()
        pcall(require('dap.ui.widgets').hover)
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
      key = "a", -- we want to avoid breaking motions, need to follow this principe and further
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    {
      key = "A",
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
    }
  },
}

---@type dm.MappingsGroup
local misc_group = {
  name = "MISCELANOUS",
  hlgroup = "TYPE",
  mappings = {
    {
      key = "H",
      action = function()
        local state = require("debugmaster.state")
        state.sidepanel:toggle_active_with_open(state.help)
      end,
      desc = "Open help",
      waybardesc = "[H]elp"
    },
    {
      key = "Q",
      action = function() require("dap").terminate() end,
      desc = "Quit debug (terminate debug)"
    },
    {
      key = "M",
      action = function() require("dap").focus_frame() end,
      desc = "Focus current frame"
    },
  }
}

---@type dm.MappingsGroup
local nodesc_group = {
  mappings = {
    -- Debug mode is constant, we don't want to accidentally edit buffer
    {
      key = "p",
      action = function() end
    },
    {
      key = "d",
      action = function() end
    },
    {
      key = "D",
      action = function() end
    },
    {
      key = "x",
      action = function() end
    },
    {
      key = "X",
      action = function() end
    },
  }
}

---@type dm.MappingsGroup[]
M.groups = {
  move_debugger_group,
  breakpoings_group,
  inspect_group,
  misc_group,
  nodesc_group,
}

function M.remap()
  print("not implemented")
end

function M.remove()
  print("not implemented")
end

return M
