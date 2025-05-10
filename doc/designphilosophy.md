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

