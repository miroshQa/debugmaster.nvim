local M = {}
local keymaps = require("debugmaster.debug.keymaps")
local dap = require("dap")

M.mode = {
  toggle = function()
    require("debugmaster.state")
    require("debugmaster.plugins.cursor_highlight")
    require("debugmaster.plugins.smart_rerun")
    require("debugmaster.debug.mode").toggle()
  end
}

M.keys = {
  get = keymaps.get,
}

vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'

dap.listeners.before.launch["dm-autoopen"] = function()
  require("debugmaster.state").sidepanel:open()
end

dap.listeners.before.attach["dm-autoopen"] = function()
  require("debugmaster.state").sidepanel:open()
end

dap.listeners.before.event_terminated["dm-autoclose"] = function()
  require("debugmaster.state").sidepanel:close()
  print("dap terminated")
end

dap.listeners.before.event_exited["dm-autoclose"] = function()
  require("debugmaster.state").sidepanel:close()
  print("dap exited")
end



return M
