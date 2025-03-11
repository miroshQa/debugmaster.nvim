---@class dm.KeySpec
---@field key string
---@field action fun(): string?
---@field desc string?
---@field nowait boolean?

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
      key = "a", -- we want to avoid breaking motions, need to follow this principe and further
      action = function() require("dap").toggle_breakpoint() end,
      desc = "Toggle breakpoint",
    },
    reverse_ui_clockwise = {
      key = "r",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:rotate()
        end
      end,
      desc = "reverse ui layout",
    },
    continue = {
      key = "c",
      nowait = true,
      action = function() require("dap").continue() end,
      desc = "Continue"
    },
    reverse_continue = {
      key = "C",
      nowait = true,
      action = function() require("dap").reverse_continue() end,
      desc = "Continue"
    },
    terminate = {
      key = "K",
      action = function() require("dap").terminate() end,
      desc = "Kill (terminate debug)"
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
    search = {
      key = "/",
      action = function ()
        require("debugmaster.debugmode").disable()
        vim.fn.feedkeys("/", "n")
      end,
    },
    search_backward = {
      key = "?",
      action = function()
          require("debugmaster.debugmode").disable()
          vim.fn.feedkeys("?", "n")
        end,
    },
    disable = {
      key = "<Esc>",
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
    toggle_ui = {
      key = "u",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:toggle()
        end
      end,
      desc = "Toggle ui",
    },
    last_pane_to_float = {
      key = "U",
      action = function()
        local state = require("debugmaster.state")
        if state.dapi then
          state.dapi:last_pane_to_float()
        end
      end,
      desc = "Toggle ui",
    },
    evaluate_variable = {
      key = "I",
      action = function()
        pcall(require('dap.ui.widgets').hover)
      end,
      desc = "Toggle ui",
    }
  }
}

return config
