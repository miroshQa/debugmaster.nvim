local view = {}
local api = vim.api

function view.new_float_anchored(buf)
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local width = 1
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line), 1)
  end
  local height = math.max(#lines, 1)

  ---@type vim.api.keyset.win_config
  local win_config = {
    row = 0,
    col = 0,
    relative = 'cursor',
    width = width,
    height = height,
    style = 'minimal',
    border = "rounded",
    focusable = true
  }

  -- Create and configure window
  local win = api.nvim_open_win(buf, true, win_config)
  return win
end

function view.make_centered_float_cfg()
  local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5)))
  local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10)))
  ---@type vim.api.keyset.win_config
  local cfg = {
    relative = "editor",
    border = "rounded",
    width = width,
    height = height,
    row = math.ceil(vim.o.lines - height) * 0.5 - 1,
    col = math.ceil(vim.o.columns - width) * 0.5 - 1
  }
  return cfg
end

---@param win number
function view.close_on_leave(win)
  local id
  id = api.nvim_create_autocmd("WinLeave", {
    callback = function()
      if api.nvim_win_is_valid(win) then
        api.nvim_win_close(win, true)
      end
      api.nvim_del_autocmd(id)
    end
  })
end

return view
