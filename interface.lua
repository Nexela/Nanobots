local Queue = require("stdlib/utils/queue")
local interface = {}

function interface.reset_mod(are_you_sure)
    local player_name = game.player and game.player.name or "script"
    if are_you_sure then
        MOD.on_init()
        MOD.log("Full Reset Completed by "..player_name)
    else
        MOD.log("Full reset attempted but "..player_name.." was not sure")
    end
end

function interface.reset_config()
    interface.config("reset")
end

function interface.reset_nano_queue()
    global.nano_queue = Queue.new()
    MOD.log("Resetting Nano Queue", 2)
end
function interface.reset_cell_queue()
    global.nano_queue = Queue.new()
    MOD.log("Resetting Interface Queue", 2)
end

function interface.config(key, value, silent)
    local config = Config.new(global.config)
    if key then
        if key == "reset" then
            global.config = MOD.config.control
            if not silent then MOD.log("Reset config to default.", 2) end
            return true
        end
        --key=string.upper(key)
        if config.get(key) ~= nil then
            if value ~= nil then
                config.set(key, value)
                local val=config.get(key)
                if not silent then MOD.log("New value for '" .. key .. "' is " .. "'" .. tostring(val) .."'", 2) end
                return val-- all is well
            else --value nil
                local val = config.get(key)
                if not silent then MOD.log("Current value for '" .. key .. "' is " .. "'" .. tostring(val) .."'") end
                return val
            end
        else --key is nill
            if not silent then game.print(MOD.log"Config '" .. key .. "' does not exist", 2) end
            return nil
        end
    else
        if not silent then
            MOD.log("Config requires a key name", 2)
            game.print(serpent.block(global.config, {comment = false, compact = true, nocode = true}))
        end
        return nil
    end
end

function interface.get_nano_queue()
    return(global.nano_queue)
end
function interface.get_cell_queue()
    return(global.cell_queue)
end

function interface.add_to_queue(data, tick)
    if tick and data and type(data) =="table" and data.action then
        Queue.insert(global.queue, data, tick)
        return true
    end
end

function interface.print_global(name)
    if name and type(name) == "string" then
        game.print(name.."="..serpent.block(global[name], {comment=false, sparse=true}))
        game.write_file("/Nanobots/global.lua", name.."="..serpent.block(global[name], {comment=false, sparse=true}))
    else
        game.print(serpent.block(global, {comment=false, sparse=true}))
        game.write_file("/Nanobots/global.lua", serpent.block(global, {comment=false, sparse=true}))
    end
end

-- function interface.toggle_tick_handler()
-- interface.toggle_handlers("tick", nil, false)
-- end

function interface.nano_fast_test_mode()
    local config = Config.new(global.config)
    config.set("poll_rate", 10)
    config.set("nanobots_tick_spacing", 1)
    MOD.log("Fast test mode enabled", 2)
end

function interface.nano_slow_test_mode()
    local config = Config.new(global.config)
    config.set("poll_rate", 60)
    config.set("nanobots_tick_spacing", 60)
    MOD.log("Slow test mode enabled", 2)
end

interface.console = require("stdlib/debug/console")

--Register with creative-mode for easy testing
if remote.interfaces["creative-mode"] and remote.interfaces["creative-mode"]["register_remote_function_to_modding_ui"] then
    log("Nanobots - Registering with Creative Mode")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "print_global")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_mod")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_config")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_queue")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "toggle_tick_handler")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "fast_test_mode")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "slow_test_mode")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "console")
end

return interface
