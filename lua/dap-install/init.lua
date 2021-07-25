local M = {}

local dap = require("dap")
local utils_tbl = require("dap-install.utils.tables.init")
local utils_paths = require("dap-install.utils.paths.init")
local dbg_list = require("dap-install.debuggers_list").debuggers
local install = require("dap-install.tools.tool_install.init")

function M.setup(custom_opts)
    require("dap-install.config").set_options(custom_opts)
end

-- Initialise DAP.
-- @param debugger - the deugger name, a key for the dbg_list.
-- @param dbg_list - a list of debuggers defined by debugger_list.lua.
-- @param config - a debugger conguration table, as specified in the installation docs.
local function call_on_dap(debugger, dbg_list, user_config)
    local dbg = require(dbg_list[debugger][1])
    local final_config = vim.tbl_deep_extend("force", dbg.config, user_config)

    if (dbg.config["adapters"] ~= nil) then
        dap.adapters[dbg.dap_info["name_adapter"]] = final_config["adapters"]
    end

    if (dbg.config["configurations"] ~= nil) then
        dap.configurations[dbg.dap_info["name_configuration"]] = final_config["configurations"]
    end
end

-- TODO: move me to a module
local function is_supported(debugger)
    return utils_tbl.tbl_has_element(dbg_list, debugger, "index")
end

local function is_installed(debugger)
  return utils_paths.assert_dir(dbg_list[debugger][2]) == 1
end

local function not_installed(debugger)
  return is_installed(debugger) == false
end

local function auto_install(debuggers)
    -- don't do nil check, that's the caller's problem.
    if type(debuggers) ~= "table" then
        print("DAPInstall: auto-installed debuggers must be a table (list) or nil")
        return
    end
    if #debuggers == 0 then return end


    local unsupported = {}
    local supported = {}
    for _, d in pairs(debuggers) do
        if is_supported(d) then
            table.insert(supported, d)
        else
            table.insert(unsupported, d)
        end
    end


    if #unsupported > 0 then
        local msg = "DAPInstall: these auto-installed debuggers are either unsupported or incorrect: "
        msg = msg..table.concat(unsupported, ", ")
        print(msg)
    end


    for _, d in pairs(supported) do
        if not_installed(d) then install(d, true) end
    end
end

-- The configuration function called directly from the user's config.
-- @param debugger - the deugger name, a key for the debuggers_list.
-- @param config - a debugger conguration table, as specified in the installation docs.
function M.config(debugger, config)
    config = config or {}
    local options = require("dap-install.config").options["verbosely_call_debuggers"]

    -- TODO: check autoinstall bool here, then do install if true.
    if options.auto_install then auto_install(options.auto_install) end

    if (options.verbosely_call_debuggers == true) then
        print("DAPInstall: Passing the " .. debugger .. " to nvim-dap...")
    end

    if is_supported(debugger) then
        if (utils_paths.assert_dir(dbg_list[debugger][2]) == 1) then
            call_on_dap(debugger, dbg_list, config)
        else
            print("DAPInstall: The debugger " .. debugger .. " is not installed")
        end
    else
        print("DAPInstall: The debugger " .. debugger .. " is unsupported")
    end
end

return M
