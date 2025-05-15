local api = vim.api

local M = {}

-- https://www.reddit.com/r/neovim/comments/tz6p7i/how_can_we_set_color_for_each_part_of_statusline/
---@return string
function M.status_line_apply_hl(str, hlGroup)
  return "%#" .. hlGroup .. "#" .. str .. "%*"
end

function M.get_windows_for_buffer(buf)
  local windows = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_buf(win) == buf then
      table.insert(windows, win)
    end
  end
  return windows
end

do
  local f = io.open(vim.fs.joinpath(vim.fn.stdpath("config"), "log.md"), "w+")
  local count = 1

  M.log = function(message, obj)
    count = count + 1
    f:write(string.format("[%s]: %s\n", tostring(count), message))
    f:write("```lua\n")
    f:write(vim.inspect(obj))
    f:write("\n")
    f:write("\n```\n")
  end
end


return M
