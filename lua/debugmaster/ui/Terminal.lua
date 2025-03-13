local mode = require("debugmaster.debug.mode")

local M = {}

---@class debugmaster.ui.Terminal: debugmaster.ui.Sidepanel.IComponent
local Terminal = {}

function M.new() ---@class debugmaster.ui.Terminal
  local self = setmetatable({}, { __index = Terminal })
  self.name = "[P]rogram"

  self._dummy_buf = vim.api.nvim_create_buf(false, true)
  self.buf = self._dummy_buf
  local lines = {
    "Debug adapter didn't provide terminal",
    "Eiter you attached to the process",
    "Either you need to tweak your adapter configugration options",
    "Consult with your debug adapter documentation",
    "Check nvim dap issues about your debug adapter",
    "https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation"
  }
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })

  return self
end

---@param buf number
function Terminal:attach_terminal(buf)
  self.buf = buf

  vim.keymap.set("t", "<Esc>", [[C-\><C-n>]], {buffer = self.buf})
  vim.api.nvim_create_autocmd("ModeChanged", {
    callback = function(args)
      if args.buf == self.buf then
      local modes = vim.split(args.match, ":")
      local old, new = modes[1], modes[2]
      if new == "t" and mode.is_active() then
        mode.disable()
      end
      end
    end
  })

  vim.api.nvim_create_autocmd({"BufDelete", "BufUnload"}, {
    callback = function(args)
      if args.buf == self.buf then
        self.buf = self._dummy_buf
      end
    end
  })
end

return M
