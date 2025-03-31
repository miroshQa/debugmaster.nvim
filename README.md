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
      vim.keymap.set({ "n", "t" }, "<leader>d", dm.mode.toggle, { nowait = true })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", {desc = "Exit terminal mode"})
      
      -- Example keymap modification:
      dm.keys.get("q").key = "O"
    end
  }
}
```

## Usage
1. Configure your debug adapters using nvim-dap
2. Press `<leader>d` to toggle debug mode
3. Press `H` in debug mode to view available commands
4. Toggle sidepanel with `u` 
5. Toggle float mode with `U` if the side panel has too little space to display content.
6. Set / toggle breakpoints with `a` and start debugging with `c`
7. Navigate through debug sessions using Debug mode keymaps (you can watch them in Help section (press `H`))

## Design Philosophy
### 1. Transparent debugging workflow
- Maintains standard normal-mode navigation
- Only overrides edit-related keys (`p`, `J`, `S`, `d`, `D`, `c`, `C`)

### 2. Not invasive interface
- Single-panel interface that can operate in either:
    1. Floating mode
    2. Right-side split window mode

## Roadmap
- [ ] Functional tests
- [ ] Remove breakponts section and make it float based like with frames and threads

## Recipes
1. An example of how to display DEBUG mode in your status line can be found here:
https://github.com/miroshQa/dotfiles/blob/main/nvim/lua/plugins/lualine.lua


## Acknowledgements
- Inspired by [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)  
