- [Display debug mode in lualine](#Display debug mode in statusline)
- Reverse debugging
- DAP config to debug neovim in two keypress


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



## Reverse debugging
TODO



## Neovim lua debugging in three keypress
TODO 
