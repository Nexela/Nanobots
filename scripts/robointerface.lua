-------------------------------------------------------------------------------
--[[robointerface]]
-------------------------------------------------------------------------------
local robointerface = {}
local Area = require("stdlib/area/area") --luacheck: ignore Area
local Position = require("stdlib/area/position")

--[[
raw-wood-cutting, scan for trees, if value is negative only scan for trees if wood in network is less then that amount
tile-item, scan for tiles, only checks first signal, if negative, will not place tiles unless that many are in network.
item-on-ground-sig, Scan for items on ground, if found cell will check for items-ground and mark for pickup if no enemies in range
networks-sig

parameters ={
    parameters = {
        {
            count = 1,
            index = 1,
            signal = {
                name = "nano-signal-item-on-ground",
                type = "virtual"
            }
        },
        {
            count = 1,
            index = 2,
            signal = {
                type = "item"
            }
        },
    }
}

--]]--

function robointerface.new(entity, interface)
    return {
        name = entity.name,
        unit_number = entity.unit_number,
        entity = entity,
        interface = interface
    }
end

local function get_parameters(params)
    local parameters = {}
    for _, param in pairs(params.parameters) do
        if param.signal.name then
            parameters[param.signal.name] = param.count
        end
    end
    return parameters
end

local function get_entity_info(entity)
    return entity.surface, entity.force, entity.position
end

local pop_queue = {}
function pop_queue.pickup_items(data, action)
    local surface, force, position = get_entity_info(data.logistic_cell.owner)
    if not surface.find_nearest_enemy{position=position, max_distance=data.logistic_cell.construction_radius, force=force} then
        local filter = {area=Position.expand_to_area(position, data.logistic_cell.construction_radius), type = action.find_type or "nil"}
        local bots = data.logistic_network.available_construction_robots
        local count = 1
        for _, item in pairs(surface.find_entities_filtered(filter)) do
            if not item.to_be_deconstructed(force) then
                if count < bots then
                    item.order_deconstruction(force)
                    count = count + 1
                else
                    break
                end
            end
        end
    end
end

local function find_network_and_cell(entity)
    local network = entity.surface.find_logistic_network_by_position(entity.position, entity.force)
    local cell = network and network.find_cell_closest_to(entity.position)
    return network, cell
end

local params_to_check = {
    ["nano-signal-chop-trees"] = {
        action = "pickup_items",
        find_filter ="tree"
    },
    ["nano-signal-item-on-ground"] = {
        action = "pickup_items",
        find_filter = "item-entity"
    },
    ["nano-tile"] = {
        action = "tile_ground"
    }
}

local function run_interface(interface)
    local behaviour = interface.entity.get_control_behavior()
    if behaviour and behaviour.enabled then
        local logistic_network, logistic_cell = find_network_and_cell(interface.entity, behaviour)
        if logistic_network and logistic_network.available_construction_robots > 0 then
            local queue = global.cell_queue
            local parameters = get_parameters(behaviour.parameters)
            local just_cell = (parameters["nano-signal-closest-roboport"] or 0) > 0 and logistic_cell and {logistic_cell} or nil
            for param_name, param_table in pairs(params_to_check) do

                if parameters[param_name] then
                    for _, cell in pairs(just_cell or logistic_network.cells) do
                        if cell.construction_radius > 0 then
                            queue[cell.owner.unit_number] = queue[cell.owner.unit_number] or {
                                logistic_cell = cell,
                                logistic_network = logistic_network,
                                actions = {}
                            }
                            queue[cell.owner.unit_number].actions[param_name] = {
                                action = param_table.action,
                                find_type = param_table.find_filter,
                                param = param_name,
                                value = parameters[param_name]
                            }
                        end
                    end
                end
            end
        end
    end
end

local function destroy_roboport_interface(event)
    if event.entity.name == "roboport-interface" then
        global.robointerfaces[event.entity.unit_number] = nil
    end
end
Event.register(Event.death_events, destroy_roboport_interface)

local function build_roboport_interface(event)
    if event.created_entity.name == "roboport-interface" then
        local entity = event.created_entity
        local pos = {x=entity.position.x, y=entity.position.y+1}
        local cc = entity.surface.create_entity{name="roboport-interface-cc", position=pos, direction=defines.direction.south, force=entity.force}
        local interface = robointerface.new(entity, cc)
        global.robointerfaces[interface.unit_number] = interface
    end
end
Event.register(Event.build_events, build_roboport_interface)

--Process 1 interface every 60 ticks
local function roboport_interface_tick(event)
    if event.tick % 16 == 0 then
        local qindex, data = next(global.cell_queue)
        if qindex then
            if data.logistic_cell.valid and data.logistic_network.valid and data.logistic_network.available_construction_robots > 0 then
                for signal_name, signal_data in pairs(data.actions) do
                    pop_queue[params_to_check[signal_name].action](data, signal_data)
                end
            end
            global.cell_queue[qindex] = nil
        else
            local index, interface = next(global.robointerfaces, global._next_interface)
            if index then
                if interface and interface.entity.valid then
                    run_interface(interface)
                else
                    interface[index] = nil
                end
            end
            global._next_interface = index
        end
        global._next_cell = qindex
    end

end
Event.register(defines.events.on_tick, roboport_interface_tick)

function robointerface.init()
    local interfaces = {}
    for _, surface in pairs(game.surfaces) do
        for _, interface in pairs(surface.find_entities_filtered{name = "roboport-interface"}) do
            interfaces[interface.unit_number] = robointerface.new(interface)
        end
    end
    return interfaces
end

return robointerface
