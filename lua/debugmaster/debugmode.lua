local dap = require("dap")
local config = require("debugmaster.config")
local HelpPopup = require("debugmaster.HelpPopup").new(config.mappings)

local M = {}

M.active = false
local mappings = config.mappings

---@type vim.api.keyset.get_keymap[]
local originals = {
}
local guicursor_original = nil

local function save_original_settings()
  local all = vim.api.nvim_get_keymap("n")
  for _, mapping in ipairs(all) do
    local lhs = mapping.lhs
    if lhs and mappings[lhs] then
      originals[lhs] = mapping
    end
  end
  guicursor_original = vim.opt.guicursor._value
end
save_original_settings()

function M.activate()
  if M.active then
    return
  end
  M.active = true
  for key, spec in pairs(mappings) do
    local action = spec.action
    vim.keymap.set("n", key, action)
  end

  vim.keymap.set("n", config.help_key, function()
    HelpPopup:open()
  end)
  guicursor_original = vim.opt.guicursor._value
  vim.api.nvim_set_hl(0, "dCursor", { bg = "#2da84f"})
  vim.opt.guicursor = "n-v-c-sm:block-dCursor,i-t-ci-ve:ver25,r-cr-o:hor20"
end

function M.disable()
  M.active = false
  for key, _ in pairs(mappings) do
    local original = originals[key] or key
    vim.keymap.set("n", key, original.callback or original, {desc = original.desc})
  end
  vim.opt.guicursor = guicursor_original
end

return M
