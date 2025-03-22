# debugmaster.nvim 

A Neovim plugin designed to supercharge your debugging workflow.
It builds on the dap-view concept, reimagining how debugging interfaces should look and behave in a modal editor —plus introduces a dedicated DEBUG mode (like "insert" or "normal" mode, but built for debugging)

![split](https://github.com/user-attachments/assets/96d1f463-d4f8-42ed-809f-bab22d323a66)

![float](https://github.com/user-attachments/assets/b5876f8b-b3d9-4e87-a6bb-48261a3da33b)

## Requirements
- Neovim >= 0.10
- nvim-dap (required dependency)

## Features
- Dedicated debug mode
- Anti GUI debugger interface with tight debug mode integration

## Quickstart
Using lazy.nvim plugin manager:

```lua
return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      -- Configure your debug adapters here
      -- https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt
    end,
  },
  {
    "miroshQa/debugmaster.nvim",
    config = function()
      local dm = require("debugmaster")
      vim.keymap.set("n", "<leader>d", dm.mode.toggle, { nowait = true })
      
      -- Example keymap modification:
      dm.keys.get("L").key = "o"
    end
  }
}
```

## Usage
1. Configure your debug adapters using nvim-dap
2. Press `<leader>d` to toggle debug mode
3. Press `H` in debug mode to view available commands
4. Toggle sidepanel with `u` (toggle float mode with `U`)
5. Set / toggle breakpoints with `a` and start debugging with `c`
6. Navigate through debug sessions using Debug mode keymaps (you can watch them in Help section (press `H`))

## Design Philosophy
### 1. Transparent debugging workflow
- Maintains standard normal-mode navigation
- Only overrides edit-related keys (`p`, `J`, `S`, `d`, `D`, `c`, `C`)

### 2. Not invasive interface
- Single-panel interface that can operate in either:
    1. Floating mode
    2. Right-side split window mode

## Roadmap
- [ ] Finish Threads and Breakpoints section (not usable right now)
- [ ] Watch expressions section
- [ ] Functional tests

## Acknowledgements
- Inspired by [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)  
