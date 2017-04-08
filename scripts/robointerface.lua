-------------------------------------------------------------------------------
--[[robointerface]]
-------------------------------------------------------------------------------
local Area = require("stdlib/area/area") --luacheck: ignore Area
local Position = require("stdlib/area/position")
local Entity = require("stdlib/entity/entity")

local robointerface = {}

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
    local behaviour = interface.cc.get_control_behavior()
    if behaviour and behaviour.enabled then
        local logistic_network, logistic_cell = find_network_and_cell(interface.cc, behaviour)
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

--Process 1 queued interface every 15 ticks
local function roboport_interface_tick(event)
    if event.tick % 15 == 0 then
        local qindex, data = next(global.cell_queue)
        if qindex then
            if data.logistic_cell.valid and data.logistic_network.valid and data.logistic_network.available_construction_robots > 0 then
                for signal_name, signal_data in pairs(data.actions) do
                    pop_queue[params_to_check[signal_name].action](data, signal_data)
                end
            end
            global.cell_queue[qindex] = nil
        end
        global._next_cell = qindex
    end

end
Event.register(defines.events.on_tick, roboport_interface_tick)

local function destroy_roboport_interface(event)
    if event.entity.name == "roboport-interface" then
        local roboport_interface = global.robointerfaces[event.entity.unit_number]
        if roboport_interface and roboport_interface.cc and roboport_interface.cc.valid then
            roboport_interface.cc.destroy()
        end
        global.robointerfaces[event.entity.unit_number] = nil
    end
end
Event.register(Event.death_events, destroy_roboport_interface)

local function build_roboport_interface(event)
    if event.created_entity.name == "roboport-interface" then
        local entity = event.created_entity
        local pos = {x = entity.position.x, y = entity.position.y + 0.5}
        local cc = entity.surface.create_entity{name="roboport-interface-cc", position=pos, direction=defines.direction.south, force=entity.force}
        global.robointerfaces[entity.unit_number] = robointerface.new(entity, cc)
    end
end
Event.register(Event.build_events, build_roboport_interface)

--Todo: rebuild scanners on config_changed

local function on_sector_scanned(event)
    --if not cc build cc.
    if event.radar.name == "roboport-interface" then
        local entity = event.radar
        local roboport_interface = global.robointerfaces[entity.unit_number]
        if roboport_interface then
            run_interface(roboport_interface)
        else
            build_roboport_interface({created_entity = entity})
        end
    end
end
Event.register(defines.events.on_sector_scanned, on_sector_scanned)

function robointerface.new(entity, cc, radar)
    return {
        name = entity.name,
        unit_number = entity.unit_number,
        entity = entity,
        cc = cc,
        radar = radar
    }
end

function robointerface.init()
    local robointerfaces = {}
    for _, surface in pairs(game.surfaces) do
        for _, scanner in pairs(surface.find_entities_filtered{name = "roboport-interface"}) do
            local cc = surface.find_entities_filtered{
                name = "roboport-interface-cc",
                area = Entity.to_collision_area(scanner),
                limit = 1
            }[1]
            if cc then
                robointerfaces[scanner.unit_number] = robointerface.new(scanner, cc)
            else
                build_roboport_interface({created_entity = scanner})
            end
        end
    end
    return robointerfaces
end

return robointerface
