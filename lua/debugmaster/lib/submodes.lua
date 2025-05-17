local submodes = {}
local api = vim.api

---@class dm.lib.Submodes.Mapping
---@field mode string
---@field lhs string
---@field rhs string
---@field opts vim.api.keyset.keymap

---@param new_mappings dm.lib.Submodes.Mapping[]
---@return dm.lib.Submodes.Mapping[] replaced
function submodes.apply_keymaps_over_current_mode(new_mappings)
  --TODO: api.nvim_get_keymap("n").extend(api.nvim_get_keymap("v")).extend(api.nvim_get_keymap("i"))...
  local current_mappings = api.nvim_get_keymap("n")

  -- 1. making lookup of old mappings by key (lhs)
  ---@type table<string, dm.lib.Submodes.Mapping>
  local current_mapping_by_lhs = {}
  for _, current in ipairs(current_mappings) do
    ---@type dm.lib.Submodes.Mapping
    local cur = {
      mode = current.mode,
      rhs = current.rhs or "",
      lhs = current.lhs,
      opts = {
        desc = current.desc,
        callback = current.callback,
      }
    }
    current_mapping_by_lhs[current.lhs] = cur
  end

  -- 2. saving old mappings that will be overrided and apply new one
  ---@type dm.lib.Submodes.Mapping[]
  local originals = {}
  for _, new in ipairs(new_mappings) do
    local current = current_mapping_by_lhs[new.lhs]
    if not current then
      ---@type dm.lib.Submodes.Mapping
      current = { mode = "n", lhs = new.lhs, rhs = new.lhs, opts = {}, }
    end

    table.insert(originals, current)
    api.nvim_set_keymap(new.mode, new.lhs, new.rhs, new.opts)
  end

  return originals
end

---@class debugmaster.lib.Submode
---@field private enabled boolean
---@field private name string
---@field private mappings vim.api.keyset.get_keymap[]
---@field private replaced vim.api.keyset.get_keymap[]
local SubModeMethods = {}
---@private
SubModeMethods.__index = SubModeMethods

function SubModeMethods:toggle()
  if self.enabled then
    return self:disable()
  end
  self:enable()
end

function SubModeMethods:is_enabled()
  return self.enabled
end

function SubModeMethods:disable()
  if not self.enabled then return end
  self.enabled = false
  local pattern = self.name .. "ModeChanged"
  api.nvim_exec_autocmds("User", { pattern = pattern, data = { enabled = false } })
  submodes.apply_keymaps_over_current_mode(self.replaced)
end

function SubModeMethods:enable()
  if self.enabled then return end
  self.enabled = true
  local pattern = self.name .. "ModeChanged"
  api.nvim_exec_autocmds("User", { pattern = pattern, data = { enabled = true } })
  self.replaced = submodes.apply_keymaps_over_current_mode(self.mappings)
end

---@param params {name: string, mappings: vim.api.keyset.get_keymap[]}
function submodes.new(params)
  ---@type debugmaster.lib.Submode
  local self = setmetatable({
    name = params.name,
    mappings = params.mappings,
    replaced = params.mappings,
    enabled = false,
  }, SubModeMethods)
  return self
end

return submodes
