local M = {}
local keymaps = require("debugmaster.debug.keymaps")
local dap = require("dap")
local events_id = "debugmaster"

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
  add = keymaps.add
}

vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'

dap.listeners.before.launch[events_id] = function()
  require("debugmaster.state").sidepanel:open()
end

dap.listeners.before.attach[events_id]= function()
  require("debugmaster.state").sidepanel:open()
end

dap.listeners.before.event_terminated[events_id] = function()
  require("debugmaster.state").sidepanel:close()
  print("dap terminated")
end

dap.listeners.before.event_exited[events_id] = function()
  require("debugmaster.state").sidepanel:close()
  print("dap exited")
end

dap.listeners.before.disconnect[events_id] = function()
  require("debugmaster.state").sidepanel:close()
  print("dap disconnected")
end



return M
