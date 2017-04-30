-------------------------------------------------------------------------------
--[[Force]]
-------------------------------------------------------------------------------
require("stdlib/event/event")

local Force = {}

local function new(force_name)
    local obj = {
        index = force_name,
    }
    return obj
end

function Force.get(name)
    return game.forces[name], global.forces[name] or Force.init(name) and global.forces[name]
end

function Force.add_data_all(data)
    table.each(global.forces, function(v) table.merge(v, table.deepcopy(data)) end)
end

function Force.init(event, overwrite)
    event = event and type(event) == "string" and {force={name=event}} or event
    global.forces = global.forces or {}
    if event and event.force.name then
        if not global.forces[event.force.name] or (global.forces[event.force.name] and overwrite) then
            global.forces[event.force.name] = new(event.force.name)
        end
    else
        for name in pairs(game.forces) do
            if not global.forces[name] or (global.forces[name] and overwrite) then
                global.forces[name] = new(name)
            end
        end
    end
end
Event.register(defines.events.on_force_created, Force.init)

function Force.merge()
end
Event.register(defines.events.on_forces_merging, Force.merge)

return Force
