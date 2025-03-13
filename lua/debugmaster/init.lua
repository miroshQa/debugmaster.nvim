local M = {}

local config = require("debugmaster.config")
local mode = require("debugmaster.debug.mode")
require("debugmaster.state")

vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'

vim.keymap.set("n", config.debug_mode_key, function()
  mode.toggle()
end, {nowait = true})


return M
