local dap = require("dap")
local api = vim.api

---@class dm.ui.Terminal: dm.ui.Sidepanel.IComponent
local Terminal = {}

local terms_per_session = {}

function Terminal.new()
  ---@class dm.ui.Terminal
  local self = setmetatable({}, { __index = Terminal })
  self.name = "[T]erminal"

  self._dummy_buf = api.nvim_create_buf(false, true)
  self.buf = self._dummy_buf
  local lines = {
    "Debug adapter didn't provide terminal",
    "1. Either no session is active",
    "2. Eiter you attached to the process",
    "And then you can move the neovim terminal with the program",
    "to this section using 'dm' keymap in the debug mode",
    "3. Either you need to tweak your adapter configugration options",
    "And probably, the program output is being redirected to the REPL right now.",
    "- Consult with your debug adapter documentation",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation",
    'Usually required option is `console = "integratedTerminal"`',
    "- Check nvim dap issues about your debug adapter",
  }
  api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = self.buf })


  dap.defaults.fallback.terminal_win_cmd = function()
    local term_buf = api.nvim_create_buf(false, false)
    self:attach_terminal_to_current_session(term_buf)
    return term_buf, nil
  end

  api.nvim_create_autocmd("User", {
    pattern = "DapSessionChanged",
    callback = vim.schedule_wrap(function()
      local session = assert(dap.session())
      local term = terms_per_session[session.id] or self._dummy_buf
      self.buf = term
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end),
  })

  return self
end

---@param buf number
---@return boolean indicate if attach was successful
function Terminal:attach_terminal_to_current_session(buf)
  local session = dap.session()
  if not session then
    print("Can't attach terminal. No active session")
    return false
  elseif terms_per_session[session.id] then
    print("Can't attach terminal. Already attached")
    return false
  end

  terms_per_session[session.id] = buf
  self.buf = buf
  api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })

  api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
    callback = function(args)
      if args.buf == self.buf then
        self.buf = self._dummy_buf
        terms_per_session[session.id] = nil
        api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
      end
    end
  })

  return true
end

return Terminal
