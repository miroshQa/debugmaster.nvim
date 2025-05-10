# 😎debugmaster.nvim  
debugmaster.nvim is a neovim plugin that provides two things:
1. DEBUG mode (like "Insert" or "Normal" mode, but built for debugging)
2. Debugger UI assembled from nvim-dap native widgets (so this plugin also serves as a dap-ui alternative)


https://github.com/user-attachments/assets/f49d5033-7a46-408a-980a-060c8093d5bf


The goals of this plugin:
1. establish a DEBUG mode for neovim
2. Imagine how a debugging workflow should look in a modal editor
3. Provide UI suitable for modal editor - so you can always stay in the flow, focusing only on important things without any distractions

## ⚡️Requirements  
- Neovim >= 0.10 (>= 0.11 is recommended)  
- nvim-dap  

## ⚠️Status
The plugin is completely usable, but still under development.
Breaking changes are possible—follow commit notices.

## 🚀Quickstart  
Using lazy.nvim plugin manager:  

```lua  
return {  
  {  
    "mfussenegger/nvim-dap",  
    config = function()  
      local dap = require("dap")  
      -- Configure your debug adapters here  
      -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
    end,  
  },  
  {  
    "miroshQa/debugmaster.nvim",  
    config = function()  
      local dm = require("debugmaster")  
      -- make sure you don't have any other keymaps that starts with "<leader>d" to avoid delay
      -- Alternative keybindings to "<leader>d" could be: "<leader>m", "<leader>;"
      vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })  
      -- If you want to disable debug mode in addition to leader+d using the Escape key:
      -- vim.keymap.set("n", "<Esc>", dm.mode.disable)
      -- This might be unwanted if you already use Esc for ":noh"
      vim.keymap.set("t", "<C-/>", "<C-\\><C-n>", {desc = "Exit terminal mode"})  
    end  
  }  
}  
```  
NOTE: Don't mix this plugin with dap-ui!

## Usage  
1. Configure your debug adapters using nvim-dap.  
2. Press `<leader>d` to toggle debug mode.  
3. Press `H` in debug mode to view available commands.  
4. Toggle the side panel with `u`.  
5. Toggle float mode with `U` if the side panel has too little space to display content.  
6. Set/toggle breakpoints with `t` and start debugging with `c`.  
7. Navigate through debug sessions using debug mode keymaps (`o` - step over, `m` - step into, `q` - step out, `r`- run to cursor). You can view all of them in the Help section by pressing `H`. 

## 🤔Design Philosophy  
You can find explanations regarding the choice of these keymaps and a dap-view-like UI [here](./doc/designphilosophy.md)

## ⚙️Configuration

```lua
local dm = require("debugmaster")  
-- keymaps changing example
dm.keys.get("x").key = "y" -- remap x key in debug mode to y

-- changing some plugin options (see 1. note)
dm.plugins.cursor_hl.enabled = false
dm.plugins.ui_auto_toggle.enabled = false

-- Changing debug mode cursor hl
-- Debug mode cursor color controlled by "dCursor" highlight group
-- so to change it you can use the following code
vim.api.nvim_set_hl(0, "dCursor", {bg = "#FF2C2C"})
-- make sure to call this after you do vim.cmd("colorscheme x")
-- otherwise this highlight group could be cleaned by your colorscheme 
```
1. You are assumed to discover other dm options either using lua language
server autocompletion or inspecting the correponding file


## 👨‍🍳Recipes  
Recipes for how to configure debugmaster for reverse debugging of c++, c, and rust,
how to display debug mode in your status line,
starting debug neovim lua code in two keypresses and more can be found [here](./doc/RECIPES.md).

## 🙏Acknowledgements  
- Inspired by [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)  
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
