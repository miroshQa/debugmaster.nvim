local M = {}

local config = require("debugmaster.config")
local mode = require("debugmaster.debug.mode")
require("debugmaster.state")

vim.api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'

-- https://github.com/mfussenegger/nvim-dap/issues/786
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("PromptBufferCtrlwFix", {}),
  pattern = {"dap-repl"},
  callback = function()
    vim.keymap.set("i", "<C-w>", "<C-S-w>", {buffer = true})
  end
})

vim.keymap.set("n", config.debug_mode_key, function()
  mode.toggle()
end, {nowait = true})


return M
