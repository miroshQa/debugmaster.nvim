- Display debug mode in lualine
- DAP config to debug neovim in two keypress
- Reverse debugging c++, rust, c 

## Display debug mode in statusline
To display debug mode in your status line, you first need to learn how to determine whether this mode is enabled.
You can do this in two ways:
```lua
--Firt way
require("debugmaster.debug.mode").is_active()

--Second way (recommended)
local dmode_enabled = false
vim.api.nvim_create_autocmd("User", {
  pattern = "DebugModeChanged",
  callback = function(args)
    dmode_enabled = args.data.enabled
  end
})

```
Now that you know how to track debug mode status, the next step is to write a statusline component for your statusline plugin.
An example for lualine can be found [here](https://github.com/miroshQa/dotfiles/blob/2cb9dc3368b1ac0982f26af724db8eac073ba55c/nvim/lua/plugins/lualine.lua#L25C1-L47C1)


## Neovim lua debugging in three keypress
1. Install [one-small-step-for-vimkind](https://github.com/jbyuki/one-small-step-for-vimkind).
2. Enable osv integration
```lua
dm.plugins.osv_integration.enabled = true
```
3. Open any neovim file. Enable debug mode (`leader + d`).
4. Set breakpoint (`t`). Launch debugging (`c`).
5. Do actions that trigger breakpoints in the neovim instance opened in the [T]erminal section

TODO: Add video


## Reverse debugging c++, rust, c 
0. Install and configure cpptools adapter using this for reference:
https://github.com/jonboh/nvim-dap-rr

1. Add keymap to change direction:
```lua
dm.keys.add {
  key = "p",
  action = (function()
    local dir = "forward"
    return function()
      local s = require("dap").session()
      if not s then
        return print "Can't change execution direction. Session isn't enabled"
      end
      dir = (dir == "forward" and "reverse" or "forward")
      s:evaluate("-exec set exec-direction " .. dir)
      print("new direction: " .. dir)
    end
  end)()
}
-- This approach is arguably better than creating 5 new additional keymaps for reverse (M, O, C, Q, R)
```
2. Record session using `rr` [guide](https://jonboh.dev/posts/rr/) and start replay server
3. Step over through session changing direction using `p`
