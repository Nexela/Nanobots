local Queue = require("stdlib/utils/queue")
local interface = {}

function interface.reset_mod(are_you_sure)
    local player_name = game.player and game.player.name or "script"
    if are_you_sure then
        global = {}
        MOD.on_init()
        MOD.log("Full Reset Completed by "..player_name)
    else
        MOD.log("Full reset attempted but "..player_name.." was not sure")
    end
end

function interface.reset_nano_queue()
    global.nano_queue = Queue.new()
    MOD.log("Resetting Nano Queue", 2)
end
function interface.reset_cell_queue()
    global.nano_queue = Queue.new()
    MOD.log("Resetting Interface Queue", 2)
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
        --game.print(name.."="..serpent.block(global[name], {comment=false, sparse=true}))
        game.write_file("/Nanobots/global.lua", name.."="..serpent.block(global[name], {nocode=true, sortkeys=true, comment=false, sparse=true}))
    else
        --game.print(serpent.block(global, {comment=false, sparse=true}))
        game.write_file("/Nanobots/global.lua", serpent.block(global, {nocode=true, sortkeys=true, comment=false, sparse=true}))
    end
end

interface.console = require("stdlib/debug/console")

--Register with creative-mode for easy testing
if remote.interfaces["creative-mode"] and remote.interfaces["creative-mode"]["register_remote_function_to_modding_ui"] then
    log("Nanobots - Registering with Creative Mode")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "print_global")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_mod")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset_queue")
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "console")
end

return interface
