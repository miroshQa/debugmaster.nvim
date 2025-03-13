local dap = require("dap")
local groups = require("debugmaster.debug.keymaps").groups

---@class debugmaster.State
local M = {}

local term_buf = nil

dap.defaults.fallback.terminal_win_cmd = function(cfg)
  term_buf = vim.api.nvim_create_buf(false, false)
  return term_buf, nil
end

M.sidepanel = require("debugmaster.ui.Sidepanel").new()
M.terminal = require("debugmaster.ui.Terminal").new()
M.repl = require("debugmaster.ui.Repl").new()
M.scopes = require("debugmaster.ui.Scopes").new()
M.help = require("debugmaster.ui.Help").new(groups)

M.sidepanel:add_component(M.scopes)
M.sidepanel:add_component(M.terminal)
M.sidepanel:add_component(M.repl)
M.sidepanel:add_component(M.help)

M.sidepanel:set_active(M.scopes)

M.sidepanel:set_on_active_callback(function(buf)
  vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = buf })
  vim.keymap.set("n", "u", function() M.sidepanel:toggle() end, { buffer = buf })
  vim.keymap.set("n", "U", function() M.sidepanel:toggle_layout() end, { buffer = buf })
  vim.keymap.set("n", "H", function() M.sidepanel:toggle_active_with_open(M.help) end, { buffer = buf })
  vim.keymap.set("n", "S", function() M.sidepanel:toggle_active_with_open(M.scopes) end, { buffer = buf })
  vim.keymap.set("n", "R", function() M.sidepanel:toggle_active_with_open(M.repl) end, { buffer = buf })
  vim.keymap.set("n", "P", function() M.sidepanel:toggle_active_with_open(M.terminal) end, { buffer = buf })
end)

dap.listeners.before.launch.dapui_config = function()
  M.sidepanel:open()
  if term_buf then
    M.terminal:attach_terminal(term_buf)
  end
  term_buf = nil
end

dap.listeners.before.attach.dapui_config = function()
  M.sidepanel:open()
  term_buf = nil
end

dap.listeners.before.event_terminated.dapui_config = function()
  M.sidepanel:close()
  print("dap terminated")
end

dap.listeners.before.event_exited.dapui_config = function()
  M.sidepanel:close()
  print("dap exited")
end

return M
