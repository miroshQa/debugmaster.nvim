local dap = require("dap")
local utils = require("debugmaster.utils")
local widgets = require('dap.ui.widgets')
local repl = require 'dap.repl'

local M = {}

--- Debug adapter interface
---@class debugmaster.Dapi
local Dapi = {}

function M.new(term_buf)
  ---@class debugmaster.Dapi
  local self = setmetatable({}, { __index = Dapi })
  self.hints_ns = vim.api.nvim_create_namespace("dapi-hints")
  self.main_win = nil
  local scopes = widgets.sidebar(widgets.scopes)

  local repl_buf, repl_win = repl.open()
  self.repl_buf = repl_buf
  vim.api.nvim_win_close(repl_win, true)

  local scopes_buf, scopes_win = scopes.open()
  print("scopes_buf", scopes_buf)
  self.scopes_buf = scopes_buf
  vim.api.nvim_win_close(scopes_win, true)

  self.terminal_buf = term_buf


  return self
end

function Dapi:toggle()
  if not self.main_win then
    self:open()
  else
    self:close()
  end
end

---@class debugmaster.Dapi.OpenOptions
---@field direction "left" | "right" | "above" | "below" | nil Opens right by default if nil
---@field float boolean? If float specified then it creates float window and ignore direction

---@param opts debugmaster.Dapi.OpenOptions?
function Dapi:open(opts)
  if not self.scopes_buf then
    print("scopes_buf in open:", self.scopes_buf)
    return print("Can't open dapi. Debug session is not active")
  end

  opts = opts or {}
  if self.main_win then
    return
  end
  local direction = opts.direction or self.direction or "right"
  ---@type vim.api.keyset.win_config
  local cfg = {}
  if opts.float then
    cfg = utils.make_center_float_win_cfg()
  else
    cfg.split = direction
  end

  --  it saves us if we try open it in a float window
  local ok, res = pcall(vim.api.nvim_open_win, self.scopes_buf, false, cfg)

  if ok then
    self.main_win = res
    self.direction = direction
    self.float = opts.float
    local id
    id = vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(self.main_win),
      callback = function()
        self.main_win = nil
        vim.api.nvim_del_autocmd(id)
      end
    })
  end
end

function Dapi:close()
  if self.main_win then
    vim.api.nvim_win_close(self.main_win, true)
  end
end

function Dapi:rotate()
  if not self.main_win then
    return
  end
  local cur_direction = self.direction
  self:close()
  local directions = {"below", "left", "above", "right"}
  for i, direction in ipairs(directions) do
    if direction == cur_direction then
      -- damn lua...
      local next = directions[i % #directions + 1]
      self:open({direction = next})
    end
  end
end

function Dapi:last_pane_to_float()
  if not self.main_win then
    return
  end
  print("before close", self.scopes_buf)
  Dapi:close()
  print("after close, before open", self.scopes_buf)
  Dapi:open({float = true})
end

function Dapi:focus_scopes()
  vim.api.nvim_win_set_buf(self.main_win, self.scopes_buf)
end

function Dapi:focus_repl()
  vim.api.nvim_win_set_buf(self.main_win, self.repl_buf)
end

function Dapi:focus_terminal()
  vim.api.nvim_win_set_buf(self.main_win, self.terminal_buf)
end

return M
