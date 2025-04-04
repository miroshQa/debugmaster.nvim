local activate_cursor_hl = function()
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
  local cursor_mode_off = "n-v-sm:block,i-t-ci-ve-c:ver25,r-cr-o:hor20"
  local cursor_mode_on = "n-v-sm:block-dCursor,i-t-ci-ve-c:ver25,r-cr-o:hor20"

  vim.api.nvim_create_autocmd("User", {
    pattern = "DebugModeChanged",
    callback = function(args)
      if args.data.enabled then
        vim.go.guicursor = cursor_mode_on
      else
        vim.go.guicursor = cursor_mode_off
      end
    end
  })
end

-- we want to see cursor line only in the current split
-- TODO: Open PR in neovim repo. Because this basic feature should be in the core
-- Add new hl group CursorLineInactive
local activate_local_cursorline = function()
  vim.wo[vim.api.nvim_get_current_win()][0].cursorline = true

  local function disable_for_all_except_cur_win_and_buf()
    local cur = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if win == cur then
        vim.wo[win][0].cursorline = true
      else
        vim.wo[win][0].cursorline = false
      end
    end
  end

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      print("win entered", vim.api.nvim_get_current_win(), "current buf", vim.api.nvim_get_current_buf())
      disable_for_all_except_cur_win_and_buf()
    end
  })
end


local activate_cursorline_hl = function()
  local cursorline_bg_orig = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("CursorLine")), "bg")

  vim.api.nvim_create_autocmd("User", {
    pattern = "DebugModeChanged",
    callback = function(args)
      if args.data.enabled then
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2c4e28" })
      else
        vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline_bg_orig })
      end
    end
  })
end

activate_cursor_hl()
-- activate_cursorline_hl()
-- activate_local_cursorline()
