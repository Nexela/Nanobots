-------------------------------------------------------------------------------
--[[Force]]
-------------------------------------------------------------------------------
require("stdlib/event/event")
local Force = {}

function Force.get_object_and_data(name)
    if game.forces[name] then
        return game.forces[name], global.forces[name]
    end
end

function Force.new(force_name)
    local obj = {
        index = force_name,
    }
    return obj
end

function Force.add_data_all(data)
    local fdata = global.forces
    table.each(fdata, function(v) table.merge(v, table.deepcopy(data)) end)
end

function Force.init(event, overwrite)
    global.forces = global.forces or {}
    local fdata = global.forces or {}
    if event and event.force.name then
        if not fdata[event.force.name] or (fdata[event.force.name] and overwrite) then
            fdata[event.force.name] = Force.new(event.force.name)
        end
    else
        for name in pairs(game.forces) do
            if not fdata[name] or (fdata[name] and overwrite) then
                fdata[name] = Force.new(name)
            end
        end
    end
end
Event.register(defines.events.on_force_created, function(event) Force.init(event.force.name) end)

function Force.merge()
end
Event.register(defines.events.on_forces_merging, Force.merge)

return Force
