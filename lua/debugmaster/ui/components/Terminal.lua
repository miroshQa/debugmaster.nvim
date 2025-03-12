local M = {}

---@class debugmaster.ui.Terminal: debugmaster.ui.Sidepanel.IComponent
local Terminal = {}

---@param params debugmaster.DapiParams
function M.new(params)
  ---@class debugmaster.ui.Terminal
  local self = setmetatable({}, {__index = Terminal})

  assert(not (params.attach and params.term_buf), "we can get term_buf when attaching wtf?")
  local term_buf = params.term_buf
  if not term_buf then
    term_buf = vim.api.nvim_create_buf(false, true)
    local lines = {
      "Debug adapter didn't provide terminal",
      "Probably you need to enable some config options for you debug adapter configuration",
      "Consult with your debug adapter documentation",
      "Check nvim dap issues about your debug adapter",
      "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation"
    }
    if params.attach then
      lines = {"You attached to the process", "Use your terminal when you program is running"}
    end
    vim.api.nvim_buf_set_lines(term_buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = term_buf })
  end

  return self
end

return M
