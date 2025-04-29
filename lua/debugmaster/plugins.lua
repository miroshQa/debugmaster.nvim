local cfg = require("debugmaster.cfg")
local api = vim.api
local M = {}

M.cursor_hl = (function()
  local plugin = {}
  plugin.activate = function()
    local dcursor = api.nvim_get_hl(0, { name = "dCursor" })
    -- https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
    if next(dcursor) == nil then
      api.nvim_set_hl(0, "dCursor", { bg = "#2da84f" })
    end
    local cursor_mode_off = "n-v-sm:block,i-t-ci-ve-c:ver25,r-cr-o:hor20"
    local cursor_mode_on = "n-v-sm:block-dCursor,i-ci-ve-c:ver25-dCursor,t:ver25,r-cr-o:hor20"

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
  return plugin
end)()

M.ui_auto_toggle = (function()
  local plugin = {}
  plugin.activate = function()
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
  return plugin
end)()

M.last_config_rerunner = (function()
  local plugin = {}
  local dap = require("dap")
  local session_configs = {}
  local last_config = nil
  plugin.activate = function()
    dap.listeners.after.event_initialized["dm-saveconfig"] = function(session)
      local config = session.config
      last_config = config
      session_configs[session.id] = config
    end
  end

  plugin.run_last_cached = function()
    local session = require("dap").session()
    if session then
      local config = assert(session_configs[session.id], "Active session exist, but config doesn't. Strange...")
      return dap.run(config)
    elseif last_config then
      return dap.run(last_config)
    end
    print("No configuration available to re-run")
  end

  return plugin
end)()

M.dap_float_close_on_q = {
  activate = function()
    api.nvim_command 'autocmd FileType dap-float nnoremap <buffer><silent> q <cmd>close!<CR>'
  end,
}

for plugin_name, plugin in pairs(M) do
  if cfg[plugin_name] ~= false then
    plugin.activate()
  end
end

return M
