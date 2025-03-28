local mode = require("debugmaster.debug.mode")

---@class dm.ui.Terminal: dm.ui.Sidepanel.IComponent
local Terminal = {}

function Terminal.new()
  ---@class dm.ui.Terminal
  local self = setmetatable({}, { __index = Terminal })
  self.name = "[P]rogram"

  self._dummy_buf = vim.api.nvim_create_buf(false, true)
  self.buf = self._dummy_buf
  local lines = {
    "Debug adapter didn't provide terminal",
    "Eiter you attached to the process",
    "Either you need to tweak your adapter configugration options",
    "And probably, the program output is being redirected to the REPL right now.",
    "- Consult with your debug adapter documentation",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation",
    'Usually required option is `console = "integratedTerminal"`',
    "- Check nvim dap issues about your debug adapter",
  }
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })

  return self
end

---@param buf number
function Terminal:attach_terminal(buf)
  self.buf = buf

  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", {buffer = self.buf})

  vim.api.nvim_create_autocmd({"BufDelete", "BufUnload"}, {
    callback = function(args)
      if args.buf == self.buf then
        self.buf = self._dummy_buf
      end
    end
  })
end

return Terminal
