local M = {}

-- https://github.com/mfussenegger/nvim-dap/issues/792
---@param dir "next"|"prev"
function M.gotoBreakpoint(dir)
  local breakpoints = require("dap.breakpoints").get()
  if #breakpoints == 0 then
    vim.notify("No breakpoints set", vim.log.levels.WARN)
    return
  end
  local points = {}
  for bufnr, buffer in pairs(breakpoints) do
    for _, point in ipairs(buffer) do
      table.insert(points, { bufnr = bufnr, line = point.line })
    end
  end

  local current = {
    bufnr = vim.api.nvim_get_current_buf(),
    line = vim.api.nvim_win_get_cursor(0)[1],
  }

  local nextPoint
  for i = 1, #points do
    local isAtBreakpointI = points[i].bufnr == current.bufnr and points[i].line == current.line
    if isAtBreakpointI then
      local nextIdx = dir == "next" and i + 1 or i - 1
      if nextIdx > #points then nextIdx = 1 end
      if nextIdx == 0 then nextIdx = #points end
      nextPoint = points[nextIdx]
      break
    end
  end
  if not nextPoint then nextPoint = points[1] end

  vim.cmd(("buffer +%s %s"):format(nextPoint.line, nextPoint.bufnr))
end

function M.make_center_float_win_cfg()
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
function M.register_to_close_on_leave(win)
  local id
  id = vim.api.nvim_create_autocmd("WinLeave", {
    callback = function(args)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      vim.api.nvim_del_autocmd(id)
    end
  })
end

-- https://www.reddit.com/r/neovim/comments/tz6p7i/how_can_we_set_color_for_each_part_of_statusline/
---@return string
function M.status_line_apply_hl(str, hlGroup)
  return "%#" .. hlGroup .. "#" .. str .. "%*"
end

function M.get_windows_for_buffer(buf)
  local windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      table.insert(windows, win)
    end
  end
  return windows
end

function M.open_floating_window(buf, opts)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local width = 1
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line), opts.min_width or 1)
  end
  local height = math.max(#lines, 1)

  ---@type vim.api.keyset.win_config
  local win_config = {
    row = 0,
    col = 0,
    relative = 'cursor',
    width = width,
    height = height + (opts.additional_height or 0),
    style = 'minimal',
    border = "rounded",
    focusable = true
  }

  -- Create and configure window
  local win = vim.api.nvim_open_win(buf, true, win_config)
  return win
end

function M.debounce(fn, ms)
  local timer = assert(vim.uv.new_timer())
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(function()
      fn(unpack(args))
    end))
  end
end

return M
