local api = vim.api
local M = {}

local plugins = {}

---@class dm.Plugin
---@field activate fun() internal plugin function. User shouldn't call it
---@field enabled boolean? nil means plugin is enabled

plugins.cursor_hl = (function()
  ---@type dm.Plugin
  local plugin = {
    activate = function()
      local dcursor = api.nvim_get_hl(0, { name = "dCursor" })
      -- https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
      if next(dcursor) == nil then
        api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
      end

      local cursor_mode_off = vim.o.guicursor
      local cursor_mode_on = cursor_mode_off .. ",a:dCursor"

      api.nvim_create_autocmd("User", {
        pattern = "DebugModeChanged",
        callback = function(args)
          if args.data.enabled then
            vim.go.guicursor = cursor_mode_on
          else
            vim.go.guicursor = cursor_mode_off
          end
        end
      })
    end
  }
  return plugin
end)()

plugins.ui_auto_toggle = (function()
  ---@type dm.Plugin
  local plugin = {
    activate = function()
      local dap = require("dap")
      dap.listeners.before.launch["debugmaster"] = function()
        require("debugmaster.state").sidepanel:open()
      end

      dap.listeners.before.attach["debugmaster"] = function()
        require("debugmaster.state").sidepanel:open()
      end

      dap.listeners.before.event_terminated["debugmaster"] = function()
        require("debugmaster.state").sidepanel:close()
        print("dap terminated")
      end

      dap.listeners.before.event_exited["debugmaster"] = function()
        require("debugmaster.state").sidepanel:close()
        print("dap exited")
      end

      dap.listeners.before.disconnect["debugmaster"] = function()
        require("debugmaster.state").sidepanel:close()
        print("dap disconnected")
      end
    end
  }
  return plugin
end)()

-- probably this code doesn't fit in the plugins concept. Need to move it somewhere
plugins.last_config_rerunner = (function()
  local dap = require("dap")
  local session_configs = {}
  local last_config = nil
  ---@type dm.Plugin
  local plugin = {
    activate = function()
      dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
        local config = session.config
        last_config = config
        session_configs[session.id] = config
      end
    end,
    run_last_cached = function()
      local session = require("dap").session()
      if session then
        local config = assert(session_configs[session.id], "Active session exist, but config doesn't. Strange...")
        return dap.run(config)
      elseif last_config then
        return dap.run(last_config)
      end
      print("No configuration available to re-run")
    end
  }
  return plugin
end)()

---@type dm.Plugin
plugins.dap_float_close_on_q = {
  activate = function()
    api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'
  end,
}

---@type dm.Plugin
plugins.osv_integration = {
  enabled = false,
  activate = function()
    local dap = require("dap")
    dap.adapters.debugmasterosv = (function()
      local id = "nvimdebug"
      local buf = -1
      dap.listeners.after.disconnect[id] = function()
        pcall(vim.api.nvim_buf_delete, buf, { force = true, unload = true })
      end
      local function find_module_path(name, no_suffix)
        local suffixes = { string.format("lua/%s.lua", name), string.format("lua/%s/init.lua", name) }
        for _, suf in ipairs(suffixes) do
          local path = vim.api.nvim_get_runtime_file(suf, false)[1]
          if path then
            return no_suffix and path:match("(.+)" .. suf) or path
          end
        end
      end
      return function(callback)
        -- we can't capture even integers for the function we dump
        -- hence using this json trick
        ---@param vars init-vars
        local init = function(vars)
          vim.opt.rtp:prepend(vars.dap_path)
          vim.opt.rtp:prepend(vars.osv_path)
          -- disable output because it significantly degrade performance
          require('osv').launch({ blocking = true, port = vars.port, output = false })
        end
        ---@class init-vars
        local vars = {
          port = math.random(49152, 65535),
          osv_path = assert(find_module_path("osv", true), "abort: one-small-step-for-vimkind not installed!!!"),
          dap_path = assert(find_module_path("dap", true), "abort: dap not installed!!!"),
        }
        -- https://gist.github.com/veechs/bc40f1f39b30cb1251825f031cd6d978
        local cmd = string.format(
          [[split | terminal nvim --cmd "lua loadstring( vim.base64.decode('%s') )( vim.json.decode(vim.base64.decode('%s')) )"]],
          vim.base64.encode(string.dump(init)), vim.base64.encode(vim.json.encode(vars))
        )
        vim.cmd(cmd)
        buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_close(0, true)
        dap.listeners.after.initialize[id] = function()
          local state = require("debugmaster.state")
          state.terminal:attach_terminal_to_current_session(buf)
          state.sidepanel:set_active(state.terminal)
          dap.listeners.after.initialize[id] = nil
        end
        callback({ type = 'server', host = "127.0.0.1", port = vars.port })
      end
    end)()

    dap.configurations.lua = dap.configurations.lua or {}
    table.insert(dap.configurations.lua, {
      type = 'debugmasterosv',
      request = 'attach',
      name = "Debug neovim (lua). Provided by debugmaster.nvim",
    })
  end
}

local plugins_enabled = false
M.init = function()
  if not plugins_enabled then
    for _, plugin in pairs(M.plugins) do
      if plugin.enabled == nil or plugin.enabled then
        plugin.activate()
      end
    end
    plugins_enabled = true
  end
end

M.plugins = plugins

return M
