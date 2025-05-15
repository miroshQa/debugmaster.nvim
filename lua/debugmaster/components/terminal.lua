local dap = require("dap")
local api = vim.api
local SessionManager = require("debugmaster.managers.SessionsManager")
local terminal = {}

terminal.comp = (function()
  local _dummy_buf = api.nvim_create_buf(false, true)
  local comp = {
    name = "[T]erminal",
    buf = _dummy_buf,
  }

  local lines = {
    "Debug adapter didn't provide term",
    "1. Either no session is active",
    "2. Eiter you attached to the process",
    "And then you can move the neovim term with the program",
    "to this section using 'dm' keymap in the debug mode",
    "3. Either you need to tweak your adapter configugration options",
    "And probably, the program output is being redirected to the REPL right now.",
    "- Consult with your debug adapter documentation",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation",
    'Usually required option is `console = "integratedterm"`',
    "- Check nvim dap issues about your debug adapter",
  }
  api.nvim_buf_set_lines(comp.buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = comp.buf })


  dap.defaults.fallback.terminal_win_cmd = function()
    local term_buf = api.nvim_create_buf(false, false)
    comp.attach_terminal_to_current_session(term_buf)
    comp.buf = term_buf
    return term_buf, nil
  end

  api.nvim_create_autocmd("User", {
    pattern = "DapSessionChanged",
    callback = vim.schedule_wrap(function()
      local session = assert(dap.session())
      local new_buf = SessionManager.get(session).terminal or _dummy_buf
      comp.buf = new_buf
      api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
    end),
  })

  ---@param buf number
  ---@return boolean indicate if attach was successful
  function comp.attach_terminal_to_current_session(buf)
    local session = dap.session()
    if not session then
      print("Can't attach term. No active session")
      return false
    elseif SessionManager.get(session).terminal then
      print("Can't attach term. Already attached")
      return false
    end

    SessionManager.register_term(session, buf)
    comp.buf = buf
    api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })

    api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
      callback = function(args)
        if args.buf == buf then
          buf = _dummy_buf
          SessionManager.register_term(session, nil)
          api.nvim_exec_autocmds("User", { pattern = "WidgetBufferNumberChanged" })
        end
      end
    })

    return true
  end

  return comp
end)()

return terminal
