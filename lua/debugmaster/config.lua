---@class dm.KeySpec
---@field action fun()
---@field desc string

---@class dm.Config
local config = {
  help_key = "H",
  ---@type table<string, dm.KeySpec>
  mappings = {
    ["B"] = {
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    ["r"] = {
      action = function() require("dap").continue() end,
      desc = "Continue"
    },
    ["T"] = {
      action = function() require("dap").terminate() end,
      desc = "Terminate"
    },
    ["R"] = {
      action = function() require("dap").run_to_cursor() end,
      desc = "Run to cursor",
    },
    ["<CR>"] = {
      action = function() require("dap").step_into() end,
      desc = "Step into",
    },
    ["<BS>"] = {
      action = function() require("dap").step_out() end,
      desc = "Step out",
    },
    ["n"] = {
      action = function() require("dap").step_over() end,
      desc = "Step over - next line"
    },
    ["<esc>"] = {
      action = function() require("debugmaster.debugmode").disable() end,
      desc = "Disable debug mode"
    },
    ["M"] = {
      action = function() require("dap").focus_frame() end,
      desc = "Focus current frame"
    },
    ["[b"] = {
      action = function() require("debugmaster.utils").gotoBreakpoint("prev") end,
      desc = "Focus current frame"
    },
    ["]b"] = {
      action = function() require("debugmaster.utils").gotoBreakpoint("next") end,
      desc = "Go to next breakpoing"
    },
  }
}



return config
