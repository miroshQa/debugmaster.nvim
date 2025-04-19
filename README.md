# debugmaster.nvim  

debugmaster.nvim is dap-ui alternative similar to dap-view that additionally introduces a separate debug mode (like "Insert" or "Normal" mode, but built for debugging) and tightly integrates it with the UI it provides. Simply put, debugmaster.nvim is the lovechild of dap-view and hydra.nvim with polished corners, trying to imagine how a debugging workflow should look in a modal editor.  

![split](https://github.com/user-attachments/assets/96d1f463-d4f8-42ed-809f-bab22d323a66)  

![float](https://github.com/user-attachments/assets/b5876f8b-b3d9-4e87-a6bb-48261a3da33b)  

debugmaster.nvim leverages nvim-dap's native widgets and adds its own when needed. The ultimate goal of this plugin is to establish a new debug Neovim mode, making debugging easy and convenient while providing a UI suitable for a modal editor — so you can always stay in the flow, focusing only on important things without any distractions

## Requirements  
- Neovim >= 0.11  
- nvim-dap  

## Status
The plugin is completely usable, but still under development.
Expect breaking changes—follow commit notices.

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
      vim.keymap.set({ "n", "v" }, "<leader>d", dm.mode.toggle, { nowait = true })  
      vim.keymap.set("t", "<C-/>", "<C-\\><C-n>", {desc = "Exit terminal mode"})  
        
      -- Example keymap modification:  
      -- dm.keys.get("x").key = "y"  
    end  
  }  
}  
```  

## Usage  
1. Configure your debug adapters using nvim-dap.  
2. Press `<leader>d` to toggle debug mode.  
3. Press `H` in debug mode to view available commands.  
4. Toggle the side panel with `u`.  
5. Toggle float mode with `U` if the side panel has too little space to display content.  
6. Set/toggle breakpoints with `t` and start debugging with `c`.  
7. Navigate through debug sessions using debug mode keymaps (you can view them in the Help section by pressing `H`).  

## Design Philosophy  

### 1. Debug mode should be transparent  
Looking at some keymaps, you might start wondering why I chose X instead of Y. Here, I list some of my considerations to help you understand my decisions.  

The first and main idea is to avoid disrupting the standard Normal mode navigation workflow. We constantly move around a file, inspect widgets, and navigate inside them to expand variables, remove breakpoints, etc. If each of these actions required switching from debug mode to Normal mode, it would become extremely tedious and inefficient. Because of this, motions like `b`, `w`, `e`, `hjkl`, `f`, `F`, `/`, `n`, and `N` are not overridden.  

Additionally, "i" was deliberately not used for "step into" because it’s a common use case to enter Insert mode from debug mode—for example, to enter an expression in the REPL or terminal. Instead, "m" is used for "step into," which also has a cool mnemonic: "mine." Of course, you can remap "m" to "i" if you’re okay with tradeoffs

As you may notice, all step actions (including 'continue') consist of only a single lowercase letter. This has two main benefits:  
- You use as many small letters as possible for the most common debug actions.  
- It makes it very easy to extend these motions with their reverse versions if you decide to use something like [nvim-dap-rr](https://github.com/jonboh/nvim-dap-rr?tab=readme-ov-file). Just follow the popular vim pattern where uppercase letters indicate reverse actions (e.g., `n` and `N`). `o` = step over, `O` = reverse step over; `c` = continue, `C` = reverse continue, etc.  

### 2. Non-invasive, anti-distracting interface  
Unlike nvim-dap-ui, debugmaster doesn’t create six panes to display all its widgets. Instead, it creates a single side panel on the right side with different sections that you can select while in debug mode using corresponding keymaps — even without focusing the side panel window (unlike dap-view). This side panel contains elements that are actually useful to see in passive mode while stepping through code (like scopes and the terminal). For other actions, such as switching and viewing frames and breakpoints, there are special float widgets that you can open using corresponding keymaps.
I believe this approach better aligns with Vim's modal editing spirit than the IDE-style GUI interface of dap-ui. After all, Vim users tend to despise screen clutter - like IDE-style tab bars or always-open file trees on the left side, etc. They prefer to focus only on important parts and "switch contexts". Additionally, this method adapts better to terminal resizing and windows layout changes

## Roadmap  
- [ ] Functional tests  
- [ ] Stepping granularity float widget  
- [ ] Exceptions float widget  

## Recipes  
1. An example of how to display DEBUG mode in your status line can be found here:  
https://github.com/miroshQa/dotfiles/blob/main/nvim/lua/plugins/lualine.lua  

## Acknowledgements  
- Inspired by [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view)  
