---@class dm.KeySpec
---@field key string
---@field action fun(): string?
---@field desc string?
---@field nowait boolean?
---@field group string?

---@alias dm.MappingsGroup table<string, dm.KeySpec>
---@alias dm.MappingsSpec table<string, dm.MappingsGroup>

---@class dm.Config
local config = {
  ---@type dm.MappingsSpec
  mappings = {
    move_debugger = {
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
        desc = "Go to the next line (step_over)",
      },
      step_back = {
        key = "N",
        action = function() require("dap").step_back() end,
        desc = "Go to the previous line (step_back)",
      },
      continue = {
        key = "c",
        nowait = true,
        action = function() require("dap").continue() end,
        desc = "Continue or start debug session",
      },
      reverse_continue = {
        key = "C",
        nowait = true,
        action = function() require("dap").reverse_continue() end,
        desc = "Reverse continue",
      },
      run_to_cursor = {
        key = "r",
        action = function() require("dap").run_to_cursor() end,
        desc = "Run to cursor",
      },
    },


    inspect_state = {
      open_repl = {
        key = "R",
        action = function()
          local dapi = require("debugmaster.state").dapi
          if dapi then
            dapi:focus_repl()
          end
        end,
        desc = "Open repl",
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
            state.dapi:toggle_layout()
          end
        end,
        desc = "Toggle float layout when only one pane is be displayed in floating window",
      },
      evaluate_variable = {
        key = "I",
        action = function()
          pcall(require('dap.ui.widgets').hover)
        end,
        desc = "Toggle ui",
      },
    },


    miscellaneous = {
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
      terminate = {
        key = "K",
        action = function() require("dap").terminate() end,
        desc = "Kill (terminate debug)"
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
    },

    -- nodesck keys not shown in the help popup
    nodesc = {
      search = {
        key = "/",
        action = function()
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
    }


  },
  --- other config value
}

return config
