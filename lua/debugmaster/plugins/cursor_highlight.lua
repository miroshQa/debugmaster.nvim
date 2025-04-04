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

activate_cursor_hl()
