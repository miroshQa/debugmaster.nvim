-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.opt.rtp:append(vim.fn.getcwd())

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  vim.opt.rtp:append('deps/mini.nvim')

  -- Set up 'mini.test'
  require('mini.test').setup()
end
