local Event = require('__stdlib__/stdlib/event/event').set_protected_mode(true)
local Area = require('__stdlib__/stdlib/area/area')
local Position = require('__stdlib__/stdlib/area/position')
local table = require('__stdlib__/stdlib/utils/table')

local Config = require('config')
local setting = require('scripts/setting')
local Queue = require('scripts/hash_queue')
local prepare_chips = require('scripts/armor-mods')
local queue --- @type Nanobots.queue
local max, floor, table_size, table_find = math.max, math.floor, table_size, table.find

local BOT_RADIUS = Config.BOT_RADIUS
local QUEUE_SPEED = Config.QUEUE_SPEED_BONUS
local NANO_EMITTER = Config.NANO_EMITTER
local moveable_types = { train = true, car = true, spidertron = true } ---@type { [string]: true }
local blockable_types = { ['straight-rail'] = true, ['curved-rail'] = true } ---@type { [string]: true }
local explosives = {
    { name = 'cliff-explosives', count = 1 }, { name = 'explosives', count = 10 }, { name = 'explosive-rocket', count = 4 },
    { name = 'explosive-cannon-shell', count = 4 }, { name = 'cluster-grenade', count = 2 }, { name = 'grenade', count = 14 },
    { name = 'land-mine', count = 5 }, { name = 'artillery-shell', count = 1 }
} --- @type { [number]: SimpleItemStack }

local function unique(tbl)
    return table.keys(table.invert(tbl))
end

local main_inventories = unique {
    defines.inventory.character_trash, defines.inventory.character_main, defines.inventory.god_main, defines.inventory.chest,
    defines.inventory.character_vehicle, defines.inventory.car_trunk, defines.inventory.cargo_wagon
}

--- Return the name of the item found for table.find if we found at least 1 item
--- or cheat_mode is enabled. Does not return items with inventory
--- @param simple_stack ItemStackDefinition
--- @param _ any
--- @param player LuaPlayer
--- @param at_least_one boolean
--- @return boolean
local _find_item = function(simple_stack, _, player, at_least_one)
    local item, count = simple_stack.name, simple_stack.count
    count = at_least_one and 1 or count
    local prototype = game.item_prototypes[item]
    if prototype.type ~= 'item-with-inventory' then
        if player.cheat_mode or player.get_item_count(item) >= count then
            return true
        else
            local vehicle = player.vehicle
            local train = vehicle and vehicle.train --- @type LuaTrain
            return vehicle and ((vehicle.get_item_count(item) >= count) or (train and train.get_item_count(item) >= count))
        end
    end
end

--- Is the player ready?
--- @param player LuaPlayer
--- @return boolean
local function is_ready(player)
    return setting.afk_time == 0 or player.afk_time <= (setting.afk_time * 60)
end

--- Is this equipment powered?
--- @param character LuaEntity
--- @param eq_name string
--- @return boolean
local function is_equipment_powered(character, eq_name)
    local grid = character.grid
    if grid and grid.get_contents()[eq_name] then
        return table_find(grid.equipment, function(v)
            return v.name == eq_name and v.energy > 0
        end)
    end
    return false
end

--- Is the target not in a construction network with robots?
--- @param character LuaEntity
--- @param target? LuaEntity
--- @return boolean
local function is_outside_network(character, target)
    if is_equipment_powered(character, 'equipment-bot-chip-nanointerface') then
        return true
    else
        target = target or character
        local networks = target.surface.find_logistic_networks_by_construction_area(target.position, target.force)
        local has_network_bots = table.any(networks, function(each_network)
            return each_network.all_construction_robots > 0
        end)
        return not has_network_bots
    end
    return true
end

--- Can nanobots repair this entity?
--- @param entity LuaEntity
--- @return boolean
local function is_nanobot_repairable(entity)
    if entity.has_flag('not-repairable') or entity.type:find('robot') then return false end
    if blockable_types[entity.type] and entity.minable == false then return false end
    if (entity.get_health_ratio() or 1) >= 1 then return false end
    if moveable_types[entity.type] and entity.speed > 0 then return false end
    return table_size(entity.prototype.collision_mask) > 0
end

--- Get both the gun and ammo that matches gun_name.
--- @param player LuaPlayer
--- @param gun_name string
--- @return LuaItemStack|nil
--- @return LuaItemStack|nil
local function get_gun_ammo_name(player, gun_name)
    local gun_inv = player.get_inventory(defines.inventory.character_guns)
    local ammo_inv = player.get_inventory(defines.inventory.character_ammo)

    local gun ---@type LuaItemStack
    local ammo ---@type LuaItemStack

    if not player.mod_settings['nanobots-active-emitter-mode'].value then
        local index ---@type uint
        gun, index = gun_inv.find_item_stack(gun_name)
        ammo = gun and ammo_inv[index]
    else
        local index = player.character.selected_gun_index
        gun, ammo = gun_inv[index], ammo_inv[index]
    end

    if gun and gun.valid_for_read and ammo.valid_for_read then return gun, ammo end
    return nil, nil
end

--- Get an item with health data from the inventory
--- @param entity LuaEntity the entity object to search
--- @param item_stack ItemStackDefinition the item to look for
--- @param cheat? boolean cheat the item
--- @param at_least_one? boolean #return as long as count > 0
--- @return ItemStackDefinition|nil
local function get_items_from_inv(entity, item_stack, cheat, at_least_one)
    if cheat then
        return { name = item_stack.name, count = item_stack.count, health = 1 }
    else
        local sources
        if entity.vehicle and entity.vehicle.train then
            sources = entity.vehicle.train.cargo_wagons
            sources[#sources + 1] = entity
        elseif entity.vehicle then
            sources = { entity.vehicle, entity }
        else
            sources = { entity }
        end

        local new_item_stack = { name = item_stack.name, count = 0, health = 1 }

        local count = item_stack.count

        for _, source in pairs(sources) do
            for _, inv in pairs(main_inventories) do
                local inventory = source.get_inventory(inv)
                if inventory and inventory.valid and inventory.get_item_count(item_stack.name) > 0 then
                    local stack = inventory.find_item_stack(item_stack.name)
                    while stack do
                        local removed = math.min(stack.count, count)
                        new_item_stack.count = new_item_stack.count + removed
                        new_item_stack.health = new_item_stack.health * stack.health
                        stack.count = stack.count - removed
                        count = count - removed

                        if new_item_stack.count == item_stack.count then return new_item_stack end
                        stack = inventory.find_item_stack(item_stack.name)
                    end
                end
            end
        end
        if entity.is_player() then
            local stack = entity.cursor_stack
            if stack and stack.valid_for_read and stack.name == item_stack.name then
                local removed = math.min(stack.count, count)
                new_item_stack.count = new_item_stack.count + removed
                new_item_stack.health = new_item_stack.health * stack.health
                stack.count = stack.count - count
            end
        end
        if new_item_stack.count == item_stack.count then
            return new_item_stack
        elseif new_item_stack.count > 0 and at_least_one then
            return new_item_stack
        else
            return nil
        end
    end
end

--- Manually drain ammo, if it is the last bit of ammo in the stack pull in more ammo from inventory if available
--- @param player LuaPlayer the player object
--- @param ammo LuaItemStack the ammo itemstack
--- @param amount? uint
--- @return boolean #Ammo was fully drained
local function drain_ammo(player, ammo, amount)
    if player.cheat_mode then return true end

    amount = amount or 1
    local name = ammo.name
    ammo.drain_ammo(amount)
    if not ammo.valid_for_read then
        local new = player.get_main_inventory().find_item_stack(name)
        if new then
            ammo.set_stack(new)
            new.clear()
        end
        return true
    end
end

--- Get the radius to use based on tehnology and player defined radius
--- @param player LuaPlayer
--- @param nano_ammo LuaItemStack
local function get_ammo_radius(player, nano_ammo)
    local data = global.players[player.index]
    local max_radius = BOT_RADIUS[player.force.get_ammo_damage_modifier(nano_ammo.prototype.get_ammo_type().category)] or 7
    local custom_radius = data.ranges[nano_ammo.name] or max_radius
    return custom_radius <= max_radius and custom_radius or max_radius
end

--[[ Nano Emmitter --]]
-- Extension of the tick handler, This functions decide what to do with their
-- assigned robots and insert them into the queue accordingly.
-- TODO: replace table_find entity-match with hashed lookup

--- Nano Constructors
--- Queue the ghosts in range for building, heal stuff needing healed
--- @param player LuaPlayer
--- @param pos MapPosition
--- @param ammo LuaItemStack
local function queue_ghosts_in_range(player, pos, ammo)
    local pdata = global.players[player.index]
    local player_force = player.force --- @type LuaForce

    local next_nano_tick = (pdata._next_nano_tick and pdata._next_nano_tick < (game.tick + 2000) and pdata._next_nano_tick) or game.tick ---@type uint
    local tick_spacing = max(1, setting.ticks_between_actions - (QUEUE_SPEED[player_force.get_gun_speed_modifier('nano-ammo')] or QUEUE_SPEED[4]))
    local actions_per_group = setting.actions_per_group
    local get_next_tick = queue:get_counters(next_nano_tick, tick_spacing, actions_per_group)

    local area = Position.expand_to_area(pos, get_ammo_radius(player, ammo))
    local cheat_mode = player.cheat_mode

    for _, ghost in pairs(player.surface.find_entities(area)) do
        local ghost_force = ghost.force ---@type LuaForce
        local friendly_force = ghost_force.is_friend(player_force)
        local _, queued_this_cycle = get_next_tick(false, true)

        if not ammo.valid_for_read then return end
        if queued_this_cycle >= setting.entities_per_cycle then return end
        if not friendly_force then goto next_ghost end
        if queue:is_hashed(ghost) then goto next_ghost end
        if setting.network_limits and not is_outside_network(player.character, ghost) then goto next_ghost end

        local deconstruct = friendly_force and ghost.to_be_deconstructed()
        local upgrade = friendly_force and ghost.to_be_upgraded()
        local ghost_surface = ghost.surface

        --- @class Nanobots.action_data
        --- @field on_tick uint
        --- @field hash_id uint
        local data = {
            player_index = player.index, ---@type uint
            player = player, ---@type LuaPlayer
            ammo = ammo, ---@type LuaItemStack
            entity = ghost, ---@type LuaEntity
            position = ghost.position, ---@type MapPosition
            surface = ghost_surface, ---@type LuaSurface
            unit_number = ghost.unit_number, ---@type uint
            force = ghost_force ---@type LuaForce
        }

        if deconstruct then
            if ghost.type == 'cliff' then
                if player_force.technologies['nanobots-cliff'].researched then
                    local item_name = table_find(explosives, _find_item, player)
                    if item_name then
                        local explosive = get_items_from_inv(player, item_name, cheat_mode)
                        if explosive then
                            data.item_stack = explosive ---@type ItemStackDefinition
                            data.action = 'cliff_deconstruction'
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1)
                        end
                    end
                end
            elseif ghost.minable then
                data.action = 'deconstruction'
                queue:insert(data, get_next_tick())
                drain_ammo(player, ammo, 1)
            end
        elseif upgrade then
            local prototype = ghost.get_upgrade_target()
            if prototype then
                if prototype.name == ghost.name then
                    local dir = ghost.get_upgrade_direction()
                    if ghost.direction ~= dir then
                        data.action = 'upgrade_direction'
                        data.direction = dir ---@type defines.direction
                        queue:insert(data, get_next_tick())
                        drain_ammo(player, ammo, 1)
                    end
                else
                    local item_stack = table_find(prototype.items_to_place_this, _find_item, player)
                    if item_stack then
                        data.action = 'upgrade_ghost'
                        local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if place_item then
                            data.entity_name = prototype.name ---@type string
                            data.item_stack = place_item  ---@type ItemStackDefinition
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1)
                        end
                    end
                end
            end
        elseif ghost.name == 'entity-ghost' or (ghost.name == 'tile-ghost' and setting.build_tiles) then
            -- get first available item that places entity from inventory that is not in our hand.
            local prototype = ghost.ghost_prototype
            local item_stack = table_find(prototype.items_to_place_this, _find_item, player)
            if item_stack then
                if ghost.name == 'entity-ghost' then
                    local place_item = get_items_from_inv(player, item_stack, cheat_mode)
                    if place_item then
                        data.action = 'build_entity_ghost'
                        data.item_stack = place_item
                        queue:insert(data, get_next_tick())
                        drain_ammo(player, ammo, 1)
                    end
                elseif ghost.name == 'tile-ghost' then
                    -- Don't queue tile ghosts if entity ghost is on top of it.
                    if ghost_surface.count_entities_filtered { name = 'entity-ghost', area = ghost.selection_box, limit = 1 } == 0 then
                        local tile = ghost_surface.get_tile(ghost.position)
                        local place_item = get_items_from_inv(player, item_stack, cheat_mode)
                        if place_item then
                            data.action = 'build_tile_ghost'
                            data.tile = tile ---@type LuaTile
                            data.item_stack = place_item ---@type ItemStackDefinition
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1)
                        end
                    end
                end
            end
        elseif is_nanobot_repairable(ghost) then
            if ghost_surface.count_entities_filtered { name = 'nano-cloud-small-repair', position = data.position } == 0 then
                data.action = 'repair_entity'
                queue:insert(data, get_next_tick())
                drain_ammo(player, ammo, 1)
            end
        elseif ghost.name == 'item-request-proxy' and setting.do_proxies then
            local items = {}
            for item, count in pairs(ghost.item_requests) do items[#items + 1] = { name = item, count = count } end
            local item_stack = table_find(items, _find_item, player, true)
            if item_stack then
                local place_item = get_items_from_inv(player, item_stack, cheat_mode, true)
                if place_item then
                    data.action = 'item_requests'
                    data.item_stack = place_item ---@type ItemStackDefinition
                    queue:insert(data, get_next_tick())
                    drain_ammo(player, ammo, 1)
                end
            end
        end
        ::next_ghost::
    end
    pdata._next_nano_tick = get_next_tick(false, true)
end

--- Nano Termites
--- Kill the trees! Kill them dead
--- @param player LuaPlayer
--- @param pos MapPosition
--- @param ammo LuaItemStack
local function everyone_hates_trees(player, pos, ammo)
    local radius = get_ammo_radius(player, ammo)
    local force = player.force
    local surface = player.surface
    for _, stupid_tree in pairs(surface.find_entities_filtered { position = pos, radius = radius, type = 'tree', limit = 200 }) do
        if not ammo.valid_for_read then return end
        if not stupid_tree.to_be_deconstructed then
            local tree_area = Area.expand(stupid_tree.bounding_box, .5)
            if surface.count_entities_filtered { area = tree_area, name = 'nano-cloud-small-termites' } == 0 then
                surface.create_entity {
                    name = 'nano-projectile-termites',
                    source = player,
                    position = player.position,
                    force = force,
                    target = stupid_tree,
                    speed = .5
                }
                drain_ammo(player, ammo, 1)
            end
        end
    end
end

do
    --- The tick handler
    --- @param event on_tick
    local function poll_players(event)
        -- Execute events
        queue:execute(event)

        -- Default rate is 1 player ever 60 ticks, 2 players is 1 every 30 ticks.
        if event.tick % max(1, floor(setting.poll_rate / #game.connected_players)) == 0 then
            local player  ---@type LuaPlayer
            global._last_player, player = next(game.connected_players, global._last_player)
            if not (player and is_ready(player)) then return end
            local character = player.character
            if not character then return end

            if setting.equipment_auto then prepare_chips(player) end

            if not setting.nanobots_auto then return end

            if setting.network_limits and not is_outside_network(character) then return end

            local gun, ammo = get_gun_ammo_name(player, NANO_EMITTER)
            if not gun then return end

            local ammo_name = ammo.name ---@diagnostic disable-line: need-check-nil
            if ammo_name == 'ammo-nano-constructors' then
                queue_ghosts_in_range(player, player.position, ammo)
            elseif ammo_name == 'ammo-nano-termites' then
                everyone_hates_trees(player, player.position, ammo)
            end
        end
    end
    Event.register(defines.events.on_tick, poll_players)

    Event.register(Event.core_events.init, function()
        global.nano_queue = Queue()
        queue = global.nano_queue
        game.print('Nanobots are now ready to serve')
        setting.update_settings()
    end)

    Event.register(Event.core_events.load, function()
        queue = Queue(global.nano_queue)
        setting.update_settings()
    end)

    Event.register(defines.events.on_runtime_mod_setting_changed, setting.update_settings)

    Event.register({ defines.events.on_player_joined_game, defines.events.on_player_left_game }, function()
        global._last_player = nil
    end)

    Event.register(Event.generate_event_name('reset_nano_queue'), function()
        game.print('Resetting Nano Queue')

        global.nano_queue = Queue()
        queue = global.nano_queue
        global._last_player = nil
        for _, player in pairs(global.players) do player._next_nano_tick = 0 end
    end)
end
