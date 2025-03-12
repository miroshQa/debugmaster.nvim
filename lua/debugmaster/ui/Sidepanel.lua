local utils = require("debugmaster.utils")

---@class debugmaster.ui.Sidepanel.IComponent
---@field name string
---@field buf number

local M = {}

--- Debug adapter interface
---@class debugmaster.ui.Sidepanel
local Sidepanel = {}


function M.new()
  ---@class debugmaster.ui.Sidepanel
  local self = setmetatable({}, { __index = Sidepanel })
  self.win = nil
  self.direction = "right"
  self.float = false

  ---@type debugmaster.ui.Sidepanel.IComponent[]
  self.components = {}
  ---@type debugmaster.ui.Sidepanel.IComponent
  self.active = nil

  return self
end

function Sidepanel:toggle()
  if not utils.is_win_valid(self.win) then
    self:open()
  else
    self:close()
  end
end

---@class debugmaster.ui.Sidepanel.OpenOptions
---@field direction "left" | "right" | "above" | "below" | nil Opens in previous state if nil (right when open first time)
---@field float boolean? If float specified then it creates float window and ignore direction

---@param opts debugmaster.ui.Sidepanel.OpenOptions?
function Sidepanel:open(opts)
  if utils.is_win_valid(self.win)  then
    return
  end

  -- preparing new options (float, direction)
  opts = opts or {}
  local float = self.float
  if opts.float ~= nil then
    float = opts.float
  end
  local direction = opts.direction or self.direction
  ---@type vim.api.keyset.win_config
  local cfg = {}
  local enter = false

  if float then
    cfg = utils.make_center_float_win_cfg()
    enter = true
  else
    cfg.split = direction
  end

  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.active.buf, enter, cfg)
  if not ok then
    print("can't open window", res)
    return
  end

  -- Applying new options (if pcall successfull)
  self.win = res
  self.direction = direction
  self.float = float
  vim.api.nvim_set_option_value("number", false, {win = self.win})
  vim.api.nvim_set_option_value("relativenumber", false, {win = self.win})
  if self.float then
    utils.register_to_close_on_leave(self.win)
  end
  self:_cook_winbar()
end

function Sidepanel:_cook_winbar()
  local indent = "    "
  local winbar = {}
  for _, comp in ipairs(self.components) do
    local text = comp.name
    if comp == self.active then
      text = utils.status_line_apply_hl(text, "Exception")
    end
    table.insert(winbar, text)
  end
  vim.wo[self.win].winbar = table.concat(winbar, indent)
end

function Sidepanel:close()
  if utils.is_win_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
end

---rotate sidebar clockwise
---@param step number
function Sidepanel:rotate(step)
  if not utils.is_win_valid(self.win) then
    return
  end
  local cur_direction = self.direction
  self:close()
  local directions = { "below", "left", "above", "right" }
  for i, direction in ipairs(directions) do
    if direction == cur_direction then
      -- let's pretend array starts with zero (hence i - 1)
      local index = ((i - 1) + step) % #directions
      local next = directions[index + 1]
      self:open({ direction = next })
    end
  end
end

function Sidepanel:toggle_layout()
  if not utils.is_win_valid(self.win) then
    self:open()
  end
  self:close()
  self:open({ float = not self.float })
end

---@param comp debugmaster.ui.Sidepanel.IComponent
function Sidepanel:set_active(comp)
  self.active = comp
  if self.win then
    vim.api.nvim_win_set_buf(self.win, comp.buf)
    self:_cook_winbar()
  end
end

---@param comp debugmaster.ui.Sidepanel.IComponent
function Sidepanel:add_component(comp)
  table.insert(self.components, comp)
end


return M

