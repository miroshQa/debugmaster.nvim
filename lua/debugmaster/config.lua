---@class dm.KeySpec
---@field key string
---@field action fun(): string?
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
  hlgroup = "RED",
  mappings = {
    {
      key = "i",
      action = function() require("dap").step_into() end,
      desc = "Step into",
    },
    {
      key = "o",
      action = function() require("dap").step_out() end,
      desc = "Step out",
    },
    {
      key = "n",
      action = function() require("dap").step_over() end,
      desc = "Go to the next line (step_over)",
    },
    {
      key = "N",
      action = function() require("dap").step_back() end,
      desc = "Go to the previous line (step_back)",
    },
    {
      key = "c",
      nowait = true,
      action = function() require("dap").continue() end,
      desc = "Continue or start debug session",
    },
    {
      key = "C",
      nowait = true,
      action = function() require("dap").reverse_continue() end,
      desc = "Reverse continue",
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
  hlgroup = "ORANGE",
  mappings = {
    {
      key = "R",
      action = function()
        local dapi = require("debugmaster.state").dapi
        if dapi then
          dapi:focus_repl()
        end
      end,
      desc = "Open repl",
    },
    {
      key = "u",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:toggle()
        end
      end,
      desc = "Toggle ui",
    },
    {
      key = "U",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:toggle_layout()
        end
      end,
      desc = "Toggle float layout when only one pane is be displayed in floating window",
    },
    {
      key = "I",
      action = function()
        pcall(require('dap.ui.widgets').hover)
      end,
      desc = "Toggle ui",
    },
  }
}

---@type dm.MappingsGroup
local misc_group = {
  name = "MISCELANOUS",
  hlgroup = "GREEN",
  mappings = {
    {
      key = "H",
      action = function() require("debugmaster.debugmode").HelpPopup:open() end,
      desc = "Open help"
    },
    {
      key = "a", -- we want to avoid breaking motions, need to follow this principe and further
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    {
      key = "K",
      action = function() require("dap").terminate() end,
      desc = "Kill (terminate debug)"
    },
    {
      key = "<Esc>",
      action = function() require("debugmaster.debugmode").disable() end,
      desc = "Disable debug mode"
    },
    {
      key = "M",
      action = function() require("dap").focus_frame() end,
      desc = "Focus current frame"
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
  }
}

---@type dm.MappingsGroup
local nodesc_group = {
  mappings = {
    {
      key = "/",
      action = function()
        require("debugmaster.debugmode").disable()
        vim.fn.feedkeys("/", "n")
      end,
    },
    {
      key = "?",
      action = function()
        require("debugmaster.debugmode").disable()
        vim.fn.feedkeys("?", "n")
      end,
    },
  }
}


---@class dm.Config
local config = {
  -- Alternatives:
  -- 1. Enter
  -- Tab is bad because it equals to <C-i>
  debug_mode_key = "m",

  ---@type dm.MappingsGroup[]
  groups = {
    move_debugger_group,
    inspect_group,
    misc_group,
    nodesc_group,
  }
}

return config
