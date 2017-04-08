-------------------------------------------------------------------------------
--[[robointerface]]
-------------------------------------------------------------------------------
--local Area = require("stdlib/area/area")
local Position = require("stdlib/area/position")
local Entity = require("stdlib/entity/entity")
local Queue = require("scripts/queue")

local floor = math.floor

local robointerface = {}

local params_to_check = {
    ["nano-signal-chop-trees"] = {
        action = "mark_items_or_trees",
        find_filter ="tree"
    },
    ["nano-signal-item-on-ground"] = {
        action = "mark_items_or_trees",
        find_filter = "item-entity"
    },
    ["nano-tile"] = {
        action = "tile_ground"
    }
}

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

function Queue.mark_items_or_trees(data)
    if data.logistic_cell.valid then
        local surface, force, position = get_entity_info(data.logistic_cell.owner)
        if not surface.find_nearest_enemy{position=position, max_distance=data.logistic_cell.construction_radius, force=force} then
            local config = global.config
            local filter = {area=Position.expand_to_area(position, data.logistic_cell.construction_radius), type = data.find_type or "error", limit = 300}
            local available_bots = floor(data.logistic_cell.logistic_network.available_construction_robots * (config.robo_interface_free_bots_per/100))
            local limit = -99999999999
            if data.value < 0 and data.find_type == " tree" then
                limit = (data.logistic_cell.logistic_network.get_contents()["raw-wood"] or 0) - data.value
            end

            for _, item in pairs(surface.find_entities_filtered(filter)) do
                if available_bots > 0 and (limit < 0) then
                    if not item.to_be_deconstructed(force) then
                        item.order_deconstruction(force)
                        available_bots = available_bots - 1
                        limit = limit + 1
                    end
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

local function run_interface(interface)
    local behaviour = interface.cc.get_control_behavior()
    if behaviour and behaviour.enabled then
        local logistic_network, logistic_cell = find_network_and_cell(interface.cc, behaviour)
        if logistic_network and logistic_network.available_construction_robots > 0 then
            local queue, tick_spacing = global.cell_queue, global.config.robo_interface_tick_spacing
            local parameters = get_parameters(behaviour.parameters)
            -- If the closest roboport signal is present and > 0 then just run on the attached cell
            local just_cell = (parameters["nano-signal-closest-roboport"] or 0) > 0 and logistic_cell and {logistic_cell} or nil
            for param_name, param_table in pairs(params_to_check) do
                if (parameters[param_name] or 0) ~= 0 then
                    for _, cell in pairs(just_cell or logistic_network.cells) do
                        local hash = Queue.get_hash(queue, cell.owner.unit_number)
                        if cell.construction_radius > 0 and not (hash and hash[param_table.action]) then
                            local next_tick = Queue.next(queue, game.tick, tick_spacing, true)
                            local data = {
                                position = cell.owner.position,
                                logistic_cell = cell,
                                logistic_network = logistic_network,
                                name = param_name,
                                action = param_table.action,
                                find_type = param_table.find_filter,
                                value = parameters[param_name],
                                unit_number = cell.owner.unit_number
                            }
                            Queue.insert(queue, data, next_tick())
                        end
                    end
                end
            end
        end
    end
end

local function execute_nano_queue(event)
    Queue.execute(event, global.cell_queue)
end
Event.register(defines.events.on_tick, execute_nano_queue)

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
