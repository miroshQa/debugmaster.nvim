# 😎debugmaster.nvim  

debugmaster.nvim is a dap-ui alternative, similar to dap-view, that additionally introduces a separate debug mode (like "Insert" or "Normal" mode, but built for debugging) and tightly integrates it with the UI it provides. Simply put, debugmaster.nvim is the child of dap-view and hydra.nvim, trying to imagine how a debugging workflow should look in a modal editor.  


https://github.com/user-attachments/assets/f49d5033-7a46-408a-980a-060c8093d5bf


debugmaster.nvim leverages nvim-dap's native widgets and adds its own when needed. The ultimate goal of this plugin is to establish a new debug Neovim mode, making debugging easy and convenient while providing a UI suitable for a modal editor — so you can always stay in the flow, focusing only on important things without any distractions

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
      vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })  
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
7. Navigate through debug sessions using debug mode keymaps (you can view them in the Help section by pressing `H`).  

## 🤔Design Philosophy  

### 1. Debug mode should be transparent  
Looking at some keymaps, you might start wondering why I chose X instead of Y. Here, I list some of my considerations to help you understand my decisions.  

The first and main idea is to avoid disrupting the standard Normal mode navigation workflow. We constantly move around a file, inspect widgets, and navigate inside them to expand variables, remove breakpoints, etc. If each of these actions required switching from debug mode to Normal mode, it would become extremely tedious and inefficient. Because of this, motions like `b`, `w`, `e`, `hjkl`, `f`, `F`, `/`, `n`, and `N` are not overridden.  

Additionally, "i" was deliberately not used for "step into" because it’s a common use case to enter Insert mode from debug mode—for example, to enter an expression in the REPL or terminal. Instead, "m" is used for "step into," which also has a cool mnemonic: "mine." Of course, you can remap "m" to "i" if you’re okay with tradeoffs

As you may notice, all step actions (including 'continue') consist of only a single lowercase letter. This has two main benefits:  
- You use as many small letters as possible for the most common debug actions.  
- It makes it very easy to extend these motions with their reverse versions if you decide to use something like [nvim-dap-rr](https://github.com/jonboh/nvim-dap-rr?tab=readme-ov-file). Just follow the popular vim pattern where uppercase letters indicate reverse actions (e.g., `n` and `N`). `o` = step over, `O` = reverse step over; `c` = continue, `C` = reverse continue, etc.  

### 2. Non-invasive, anti-distracting interface  
Unlike nvim-dap-ui, debugmaster doesn’t create six panes to display all its widgets. Instead, it creates a single side panel on the right side with different sections that you can select while in debug mode using corresponding keymaps — even without focusing the side panel window (unlike dap-view). This side panel contains elements that are actually useful to see in passive mode while stepping through code (like scopes and the terminal). For other actions, such as switching and viewing frames and breakpoints, there are special float widgets that you can open using corresponding keymaps.
This approach better aligns with Vim's modal editing spirit than the IDE-style GUI interface of dap-ui. After all, Vim users tend to dislike screen clutter - like IDE-style tab bars or always-open file trees on the left side, etc. They prefer to focus only on important parts and "switch contexts". Additionally, this method adapts better to terminal resizing and windows layout changes

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
