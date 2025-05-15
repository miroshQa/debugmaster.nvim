--TODO: Write own implementatin using tree. Man... that sounds nuts

local repl = {}

local dap_repl = require 'dap.repl'
local dap = require("dap")
local api = vim.api

local repl_buf, repl_win = dap_repl.open(nil, "vertical split")
api.nvim_win_close(repl_win, true)
vim.keymap.set("i", "<C-w>", "<C-S-w>", { buffer = repl_buf })
vim.keymap.set("n", "<Tab>", "<CR>", { buffer = repl_buf, remap = true })
vim.keymap.del("n", "o", { buffer = repl_buf })

dap.listeners.after.initialize["repl-hl"] = function()
  pcall(vim.treesitter.stop, repl_buf)
  pcall(vim.treesitter.start, repl_buf, vim.o.filetype)
end

repl.comp =  {
  name = "[R]epl",
  buf = repl_buf,
}

return repl
