local cursor_mode_off = "n-v-sm:block,i-t-ci-ve-c:ver25,r-cr-o:hor20"
local cursor_mode_on = "n-v-sm:block-dCursor,i-t-ci-ve-c:ver25,r-cr-o:hor20"
local cursorline_orig = vim.o.cursorline
local cursorline_bg_orig = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("CursorLine")), "bg")
local cursorline_au_id = nil
local last_entered_win = 0
vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })


local function on_enable()
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
  vim.go.guicursor = cursor_mode_on

  last_entered_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_option_value("cursorline", true, { scope = "local", win = last_entered_win })
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2c4e28" })
  -- we want to see cursor line only in the current split
  -- TODO: Open PR in neovim repo. Because this basic feature should be in the core
  -- Add new hl group CursorLineInactive
  cursorline_au_id = vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      if vim.api.nvim_win_is_valid(last_entered_win) then
        vim.api.nvim_set_option_value("cursorline", false, { scope = "local", win = last_entered_win })
      end
      last_entered_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("cursorline", true, { scope = "local", win = last_entered_win })
    end
  })
end

local function on_disable()
  vim.go.guicursor = cursor_mode_off
  if cursorline_au_id then
    vim.api.nvim_del_autocmd(cursorline_au_id)
    vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline_bg_orig })
    if vim.api.nvim_win_is_valid(last_entered_win) then
      vim.api.nvim_set_option_value("cursorline", cursorline_orig, { scope = "local", win = last_entered_win })
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "DebugModeEnabled",
  callback = vim.schedule_wrap(on_enable)
})

vim.api.nvim_create_autocmd("User", {
  pattern = "DebugModeDisabled",
  callback = vim.schedule_wrap(on_disable)
})
