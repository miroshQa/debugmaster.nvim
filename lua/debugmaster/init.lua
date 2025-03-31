local M = {}
local keymaps = require("debugmaster.debug.keymaps")

M.mode = {
  toggle = function()
    require("debugmaster.state")
    require("debugmaster.plugins.cursor")
    require("debugmaster.plugins.smart_rerun")
    require("dap")
    require("debugmaster.debug.mode").toggle()
  end
}

M.keys = {
  get = keymaps.get,
}

vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'


return M
