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
      key = "i",
      action = function() require("dap").step_into() end,
      desc = "Step into",
    },
    {
      key = "I",
      action = function() require("dap").step_out() end,
      desc = "Step out (quit frame)",
    },
    {
      key = "o",
      action = function() require("dap").step_over() end,
      desc = "Step over (next line)",
    },
    {
      key = "O",
      action = function() require("dap").step_back() end,
      desc = "Step back (prev line)",
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
  hlgroup = "STRING",
  mappings = {
    {
      key = "S",
      action = function()
        local dapi = require("debugmaster.state").dapi
        if dapi then
          dapi:focus_scopes()
        end
      end,
      desc = "Open scopes (global, local, etc variables)",
      waybardesc = "[S]copes"
    },
    {
      key = "P",
      action = function()
        local dapi = require("debugmaster.state").dapi
        if dapi then
          dapi:focus_terminal()
        end
      end,
      desc = "Open program output (terminal)",
      waybardesc = "[P]rogram"
    },
    {
      key = "R",
      action = function()
        local dapi = require("debugmaster.state").dapi
        if dapi then
          dapi:focus_repl()
        end
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
        if state.dapi then
          state.dapi:toggle()
        end
      end,
      desc = "Toggle debugger interface",
    },
    {
      key = "U",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:toggle_layout()
        end
      end,
      desc = "Toggle float debugger interface mode",
    },
    {
      key = "J",
      action = function()
        pcall(require('dap.ui.widgets').hover)
      end,
      desc = "Inspect variable under cursor",
    },
    {
      key = ">",
      action = function()
        print("rotate right")
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:rotate(1)
        end
      end,
      desc = "Rotate layout",
    },
    {
      key = "<",
      action = function()
        print("Trying to rotate backward")
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:rotate(-1)
        end
      end,
      desc = "Rotate layout backward",
    }
  }
}

---@type dm.MappingsGroup
local misc_group = {
  name = "MISCELANOUS",
  hlgroup = "TYPE",
  mappings = {
    {
      key = "H",
      action = function() require("debugmaster.debugmode").HelpPopup:toggle() end,
      desc = "Open help",
      waybardesc = "[H]elp"
    },
    {
      key = "a", -- we want to avoid breaking motions, need to follow this principe and further
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
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

---@class dm.Config
local config = {
  -- Alternatives:
  -- 1. Enter
  -- 2. Old good simple <leader>d
  -- Tab is bad because it equals to <C-i>
  -- This key used to toggle debug mode. Escape doesn't change mode!!
  debug_mode_key = "<leader>d",

  ---@type dm.MappingsGroup[]
  groups = {
    move_debugger_group,
    inspect_group,
    misc_group,
    nodesc_group,
  }
}

return config
