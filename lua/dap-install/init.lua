local M = {}

local dap = require("dap")
local utils_tbl = require("dap-install.utils.tables.init")

function M.setup(custom_opts)
    require("dap-install.config").set_options(custom_opts)
end

local function call_on_dap(debugger, dbg_list)
    local dbg = require(dbg_list[debugger][1])
    local dbg_name = dbg.dap_info["name"]

    dap.adapters[dbg_name] = dbg.config["adapters"]
    dap.configurations[dbg_name] = dbg.config["configurations"]
end

function M.config(debugger, config)
    config = config or {}
    local dbg_list = require("dap-install.debuggers_list").debuggers

    if utils_tbl.tbl_has_element(dbg_list, debugger, "index") then
        local dbg = require(dbg_list[debugger][1])

        if next(config) then
            for opt, _ in pairs(config) do
                if (opt == "adapters") then
                    for inner_opt, _ in pairs(config[opt]) do
                        if (dbg.config[opt][inner_opt] ~= nil) then -- not nil
                            dbg.config[opt][inner_opt] = config[opt][inner_opt]
                        end
                    end
                elseif (opt == "configurations") then
                    for inner_opt, _ in pairs(config[opt][1]) do
                        if (dbg.config[opt][1][inner_opt] ~= nil) then -- not nil
                            dbg.config[opt][1][inner_opt] = config[opt][1][inner_opt]
                        end
                    end
                else
                    print("Config option" .. tostring(opt) .. " was not recognized!")
                end
            end
        end
	else
		print("DAPInstall: The debugger "..debugger.." is unsupported")
    end

    call_on_dap(debugger, dbg_list)
end

return M
