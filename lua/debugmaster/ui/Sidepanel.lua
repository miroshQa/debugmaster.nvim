local utils = require("debugmaster.utils")

---@class dm.ui.Sidepanel.IComponent
---@field name string
---@field buf number

---@class dm.ui.Sidepanel
local Sidepanel = {}


function Sidepanel.new()
  ---@class dm.ui.Sidepanel
  local self = setmetatable({}, { __index = Sidepanel })
  self.win = -1 -- always need to check if valid before doing something
  self.direction = "right"
  self.float = false
  self.size = 50 -- size for the split. not applied to float. always in the range [10;90]

  ---@type dm.ui.Sidepanel.IComponent[]
  self.components = {}
  ---@type dm.ui.Sidepanel.IComponent
  self.active = nil

  vim.api.nvim_create_autocmd("User", {
    pattern = "WidgetBufferNumberChanged",
    callback = vim.schedule_wrap(function(args)
      if self.active and self:is_open() then
        vim.api.nvim_win_set_buf(self.win, self.active.buf)
        self:_cook_winbar()
      end
    end)
  })

  return self
end

function Sidepanel:is_open()
  return vim.api.nvim_win_is_valid(self.win)
end

function Sidepanel:is_focused()
  return vim.api.nvim_get_current_win() == self.win
end

function Sidepanel:toggle()
  if not self:is_open() then
    self:open()
  else
    self:close()
  end
end

---@class dm.ui.Sidepanel.OpenOptions
---@field direction "left" | "right" | "above" | "below" | nil Opens in previous state if nil (right when open first time)
---@field float boolean? If float specified then it creates float window and ignore direction

---@param opts dm.ui.Sidepanel.OpenOptions?
function Sidepanel:open(opts)
  if self:is_open() then
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
    cfg.win = -1
    cfg.width = math.floor(vim.o.columns  * (self.size / 100))
    cfg.height = math.floor(vim.o.lines  * (self.size / 100))
  end

  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.active.buf, enter, cfg)
  if not ok then
    print("Can't open window.", res)
    return
  end

  -- Applying new options (if pcall successfull)
  self.win = res
  self.direction = direction
  self.float = float
  vim.api.nvim_set_option_value("number", false, { win = self.win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = self.win })
  if self.float then
    utils.register_to_close_on_leave(self.win)
  end
  self:_cook_winbar()
end

function Sidepanel:_cook_winbar()
  -- TODO: redraw on resize
  local win_width = vim.api.nvim_win_get_width(self.win)
  local join_text_width = 0
  for _, comp in ipairs(self.components) do
    join_text_width = join_text_width + #comp.name
  end
  local max_indent = math.floor((win_width - join_text_width) / #self.components)
  local indent = string.rep(" ", max_indent)

  local winbar = {}
  for i, comp in ipairs(self.components) do
    local text = comp.name
    -- Each clickable region needs a unique identifier (using index i)
    text = string.format("%%%d@v:lua.DebugmasterClickWinbar@%s%%*", i, text)

    if comp == self.active then
      -- Apply highlight after the clickable region
      text = utils.status_line_apply_hl(text, "Exception")
    end

    table.insert(winbar, text)
  end

  vim.wo[self.win].winbar = table.concat(winbar, indent)
end

function DebugmasterClickWinbar(index)
  -- this code is absolutely cursed, don't want to even speak about this...
  local self = require("debugmaster.state").sidepanel
  local comp = self.components[index]
  self:set_active(comp)
end

function Sidepanel:close()
  if self:is_open() then
    -- may fail if trying to close last window
    pcall(vim.api.nvim_win_close, self.win, true)
  end
end

---rotate sidebar clockwise
---@param step number
function Sidepanel:rotate(step)
  if not vim.api.nvim_win_is_valid(self.win) or self.float then
    return
  end
  local was_focused = self:is_focused()
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
  if was_focused then
    vim.api.nvim_set_current_win(self.win)
  end
end

function math.clamp(n, low, high)
  return math.min(math.max(n, low), high)
end

function Sidepanel:resize(step)
  if self.float or not self:is_open() then
    return
  end
  self.size = math.clamp(self.size + step, 10, 90)
  self:close()
  self:open()
end

function Sidepanel:toggle_layout()
  if not self:is_open() then
    self:open()
  end
  self:close()
  self:open({ float = not self.float })
end

---@param comp dm.ui.Sidepanel.IComponent
function Sidepanel:set_active(comp)
  self.active = comp
  if self:is_open() then
    vim.api.nvim_win_set_buf(self.win, self.active.buf)
    self:_cook_winbar()
  end
end

-- if this comp already active then it do nothing
-- set comp as active and open panel if it is closed
---@param comp dm.ui.Sidepanel.IComponent
function Sidepanel:set_active_with_open(comp)
  if self.active == comp and self:is_open() then
    return
  end
  self:set_active(comp)
  self:open()
end

---@param comp dm.ui.Sidepanel.IComponent
function Sidepanel:add_component(comp)
  table.insert(self.components, comp)
end

return Sidepanel
