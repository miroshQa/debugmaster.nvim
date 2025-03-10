local M = {}

---@class debugmaster.HelpPopup
local HelpPopup = {}

---@param mappings table<string, dm.KeySpec>
function M.new(mappings)
  ---@class debugmaster.HelpPopup
  local self = setmetatable({}, { __index = HelpPopup })
  self.buf = vim.api.nvim_create_buf(false, true)
  self.win = nil
  local lines = {}
  for key, spec in pairs(mappings) do
    local indent = string.rep(" ", 10 - #key)
    table.insert(lines, string.format("%s %s  %s", key, indent, spec.desc))
  end
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
  vim.api.nvim_buf_set_keymap(self.buf, "n", "q", "<cmd>q<CR>", {})
  return self
end

function HelpPopup:open()
  if self.win and vim.api.nvim_buf_is_valid(self.win) then
    return
  end
  local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))
  local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
  self.win = vim.api.nvim_open_win(self.buf, true, {
    relative = "editor",
    border = "rounded",
    width = width,
    height = height,
    row = math.ceil(vim.o.lines - height) * 0.5 - 1,
    col = math.ceil(vim.o.columns - width) * 0.5 - 1
  })
  vim.api.nvim_set_option_value("number", false, { win = self.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = self.win })
end

function HelpPopup:close()
  if self.win and vim.api.nvim_buf_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
end

return M
