---@class dm.KeySpec
---@field key string
---@field action fun()
---@field desc string

---@class dm.Config
local config = {
  ---@type table<string, dm.KeySpec>
  mappings = {
    help = {
      key = "H",
      action = function() require("debugmaster.debugmode").HelpPopup:open() end,
      desc = "Open help"
    },
    toggle_breakpoint = {
      key = "B",
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    continue = {
      key = "r",
      action = function() require("dap").continue() end,
      desc = "Continue"
    },
    terminate = {
      key = "T",
      action = function() require("dap").terminate() end,
      desc = "Terminate"
    },
    run_to_cursor = {
      key = "R",
      action = function() require("dap").run_to_cursor() end,
      desc = "Run to cursor",
    },
    step_into = {
      key = "i",
      action = function() require("dap").step_into() end,
      desc = "Step into",
    },
    step_out = {
      key = "o",
      action = function() require("dap").step_out() end,
      desc = "Step out",
    },
    step_over = {
      key = "n",
      action = function() require("dap").step_over() end,
      desc = "Step over - next line"
    },
    step_back = {
      key = "N",
      action = function() require("dap").step_back() end,
      desc = "Step back - previous line"
    },
    disable = {
      key = "<esc>",
      action = function() require("debugmaster.debugmode").disable() end,
      desc = "Disable debug mode"
    },
    focus_frame = {
      key = "M",
      action = function() require("dap").focus_frame() end,
      desc = "Focus current frame"
    },
    goto_prev_breakpoint = {
      key = "[b",
      action = function() require("debugmaster.utils").gotoBreakpoint("prev") end,
      desc = "Go to previous breakpoint"
    },
    goto_next_breakpoint = {
      key = "]b",
      action = function() require("debugmaster.utils").gotoBreakpoint("next") end,
      desc = "Go to next breakpoint"
    },
    -- ["U"] = {
    --   key = "U",
    --   action = function() require("debugmaster.Dapi"). end,
    --   desc = "Toggle ui",
    -- }
  }
}

return config
