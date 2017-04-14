-------------------------------------------------------------------------------
--[[robointerface]]
-------------------------------------------------------------------------------
local Area = require("stdlib/area/area")
local Position = require("stdlib/area/position")
local Entity = require("stdlib/entity/entity")
local Queue = require("stdlib/utils/queue")

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
    },
    ["nano-signal-deconstruct-finished-miners"] = {
        action = "deconstruct_finished_miners",
        find_filter = "mining-drill"
    },
    ["nano-signal-landfill-the-world"] = {
        action = "landfill_the_world",
    },
    ["nano-signal-remove-tiles"] = {
        action = "remove_tiles",
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

Queue.mark_items_or_trees = function(data)
    if data.logistic_cell.valid and data.logistic_cell.construction_radius > 0 and data.logistic_cell.logistic_network then
        local surface, force, position = get_entity_info(data.logistic_cell.owner)
        if not surface.find_nearest_enemy{position = position, max_distance = data.logistic_cell.construction_radius, force = force} then
            local config = global.config
            local filter = {area = Position.expand_to_area(position, data.logistic_cell.construction_radius), type = data.find_type or "error", limit = 300}
            local available_bots = floor(data.logistic_cell.logistic_network.available_construction_robots * (config.robo_interface_free_bots_per / 100))
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

local function has_resources(miner)
    local _find = function(v, _) return v.prototype.resource_category == "basic_solid" and (v.amount > 0 or v.prototype.infinite_resource) end
    local filter = {area = Position.expand_to_area(miner.position, miner.prototype.mining_drill_radius), type = "resource"}
    if miner.mining_target then
        return (miner.mining_target.amount or 0) > 0
    else
        return table.find(miner.surface.find_entities_filtered(filter), _find)
    end
end

Queue.deconstruct_finished_miners = function(data)
    if not game.active_mods["AutoDeconstruct"] then
        if data.logistic_cell.valid and data.logistic_cell.construction_radius > 0 and data.logistic_cell.logistic_network then
            local surface, force, position = get_entity_info(data.logistic_cell.owner)
            --local config = global.config
            local filter = {area = Position.expand_to_area(position, data.logistic_cell.construction_radius), type = data.find_type or "error", force = force}
            for _, miner in pairs(surface.find_entities_filtered(filter)) do
                if not miner.to_be_deconstructed(force) and miner.minable and not miner.has_flag("not-deconstructable") and not has_resources(miner) then
                    miner.order_deconstruction(force)
                end
            end
        end
    end
end

local function find_network_and_cell(interface)
    local port = interface.surface.find_entities_filtered{name = "roboport-interface", area=Entity.to_collision_area(interface)}[1]
    if port.valid then
        local network = port.logistic_network
        local cell = table.find(port.logistic_cell.neighbours, function(v) return v.construction_radius > 0 end) or port.logistic_cell
        return network, cell
    end
end

local function run_interface(interface)
    local behaviour = interface.get_control_behavior()
    if behaviour and behaviour.enabled then
        local logistic_network, logistic_cell = find_network_and_cell(interface)
        if logistic_network and logistic_network.available_construction_robots > 0 then
            local queue, tick_spacing = global.cell_queue, global.config.robo_interface_tick_spacing
            local parameters = get_parameters(behaviour.parameters)
            -- If the closest roboport signal is present and > 0 then just run on the attached cell
            local just_cell = (parameters["nano-signal-closest-roboport"] or 0) > 0 and logistic_cell and {logistic_cell} or nil
            local fdata = global.forces[logistic_cell.owner.force.name]
            local next_tick = Queue.next(queue, fdata._next_cell_tick or game.tick, tick_spacing, true)
            for param_name, param_table in pairs(params_to_check) do
                if (parameters[param_name] or 0) ~= 0 then
                    for _, cell in pairs(just_cell or logistic_network.cells) do
                        local hash = Queue.get_hash(queue, cell.owner)
                        if not cell.mobile and cell.construction_radius > 0 and not (hash and hash[param_table.action]) then
                            local data = {
                                position = cell.owner.position,
                                logistic_cell = cell,
                                entity = cell.owner,
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
            fdata._next_cell_tick = next_tick()
        end
    end
end

local function execute_nano_queue(event)
    Queue.execute(event, global.cell_queue)
end
Event.register(defines.events.on_tick, execute_nano_queue)

-------------------------------------------------------------------------------
--[[Roboport Interface Scanner]]--
-------------------------------------------------------------------------------
local function kill_or_remove_interface_parts(event, destroy)
    destroy = destroy or event.mod == "creative-mode"
    if event.entity.name == "roboport-interface" then
        local interface = event.entity
        for _, entity in pairs(interface.surface.find_entities_filtered{area=Entity.to_collision_area(interface), force=interface.force}) do
            if entity ~= interface and entity.name:find("^roboport%-interface") then
                _ = (destroy and entity.destroy()) or entity.die()
            end
        end
    end
end

Event.register(defines.events.on_entity_died, function(event) kill_or_remove_interface_parts(event) end)
Event.register(Event.mined_events, function(event) kill_or_remove_interface_parts(event, true) end)

--Build the interface, after built check the area around it for interface components to revive or create.
local function build_roboport_interface(event)
    if event.created_entity.name == "roboport-interface" then
        local interface = event.created_entity
        local cc, ra = {}, {}
        for _, entity in pairs(interface.surface.find_entities_filtered{area=Entity.to_collision_area(interface), force=interface.force}) do
            if entity ~= interface then
                --If we have ghosts either via blueprint or something killed them
                if entity.name == "entity-ghost" then
                    if entity.ghost_name == "roboport-interface-cc" then
                        _, cc = entity.revive()
                        --Make sure the revived interface-cc is in the correct position. Blueprints can be rotated causing wonkiness
                        if cc.valid and not Position.equals(interface.position, Position.offset(cc.position, -.5, -.5)) then
                            cc.teleport(Position.offset(interface.position, .5, .5))
                        end
                    elseif entity.ghost_name == "roboport-interface-scanner" then
                        _, ra = entity.revive()
                    end
                elseif entity.name == "roboport-interface-cc" then
                    cc = entity
                elseif entity.name == "roboport-interface-scanner" then
                    ra = entity
                end
            end
        end
        --If neither CC or RA are valid at this point then let us create them.
        if not cc.valid then
            local pos = {x = interface.position.x + 0.5, y = interface.position.y + 0.5}
            cc = interface.surface.create_entity{name="roboport-interface-cc", position=pos, force=interface.force}
        end
        if not ra.valid then
            local pos = {x = interface.position.x - 0.5, y = interface.position.y + 0.5}
            ra = interface.surface.create_entity{name="roboport-interface-scanner", position=pos, force=interface.force}
        end
        --roboports start with a buffer of energy. Lets take that away!
        interface.energy = 0
        --Use the same backer name for the interface and radar
        ra.backer_name = interface.backer_name
        --max_health = 0 / revive() bug, try and set health to 1 to not trigger repair alerts.
        ra.health = 1
        cc.health = 1
        --cc.rotatable = false
    end
end
Event.register(Event.build_events, build_roboport_interface)

local function on_sector_scanned(event)
    --if not cc build cc.
    if event.radar.name == "roboport-interface-scanner" then
        local entity = event.radar
        local area = Area.offset(Entity.to_collision_area(entity), {x=1, y=0})
        local interface = entity.surface.find_entities_filtered{name="roboport-interface-cc", area = area, limit=1}
        if interface[1] and interface[1].valid then
            run_interface(interface[1])
        end
    end
end
Event.register(defines.events.on_sector_scanned, on_sector_scanned)

function robointerface.migrate()
end

function robointerface.new()
end

--Todo: rebuild scanners on config_changed
function robointerface.init()
    local robointerfaces = {}
    return robointerfaces
end

return robointerface
