local M = {}

local dap = require("dap")
local config = require("debugmaster.config")
local Dapi = require("debugmaster.Dapi")
local debugmode = require("debugmaster.debugmode")
local state = require("debugmaster.state")

local term_buf = nil


vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'

-- https://github.com/mfussenegger/nvim-dap/issues/786
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("PromptBufferCtrlwFix", {}),
  pattern = {"dap-repl"},
  callback = function()
    vim.keymap.set("i", "<C-w>", "<C-S-w>", {buffer = true})
  end
})

dap.defaults.fallback.terminal_win_cmd = function(cfg)
  term_buf = vim.api.nvim_create_buf(false, false)
  return term_buf, nil
end

vim.keymap.set("n", "<leader>du", function()
  if state.dapi then
    state.dapi:toggle()
  end
end)

-- Alternatives:
-- 1. Enter, m
-- Tab is bad because it equals to <C-i>
vim.keymap.set("n", "m", function()
  debugmode.toggle()
end)

dap.listeners.before.launch.dapui_config = function()
  state.dapi = Dapi.new(term_buf)
  state.dapi:open()
end

dap.listeners.before.event_terminated.dapui_config = function()
  state.dapi:close()
end

return M
