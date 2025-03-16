# Neovim modal editor style focused dap interface

## Requireiments
- Neovim version >= 0.10

## Quickstart

```lua
return {
  {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require("dap")
  end,
},
{
  dir = "miroshQa/debugmaster.nvim/",
  config = function()
    local dm = require("debugmaster")
    vim.keymap.set("n", "<leader>d", dm.mode.toggle, {nowait = true})
  end
}
}

```

## Design philosophy
### 1. Debug mode should be "transparent" and "constant":
- Debug mode doesn't override any default normal mode motions
so use can use your typical file navigation as usual  ( but there is always exceptions :) )
- Debug mode override most of the edit normal mode motions (p, J, S, d, D, c, C)

### 2. Single pane philosophy:
- UI provided by this plugin is always a single pane


## Future possible improvements
- Action to expand all variables in the scope pane ()
- Fix extra verbose output in scopes
- Expandable search in scopes for a variable (dap core related)
- WATCHES section
- TESTS

## Credits
- for inspiration: https://github.com/igorlfs/nvim-dap-view 
