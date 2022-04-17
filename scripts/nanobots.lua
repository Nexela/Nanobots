local Event = require('__stdlib__/stdlib/event/event').set_protected_mode(true)
local Area = require('__stdlib__/stdlib/area/area')
local Position = require('__stdlib__/stdlib/area/position')
local table = require('__stdlib__/stdlib/utils/table')

local Queue = require('scripts/hash_queue')
local Config = require('config')
local prepare_chips = require('scripts/armor-mods')

local queue
local setting

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
}

local function unique(tbl)
    return table.keys(table.invert(tbl))
end
local main_inventories = unique {
    defines.inventory.character_trash, defines.inventory.character_main, defines.inventory.god_main, defines.inventory.chest,
    defines.inventory.character_vehicle, defines.inventory.car_trunk, defines.inventory.cargo_wagon
}

--- Return the name of the item found for table.find if we found at least 1 item or cheat_mode is enabled.
--- Doesnt return items with inventory
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

--- Is the player AFK?
--- @param player LuaPlayer
--- @return boolean
local function is_player_afk(player)
    return setting.afk_time > 0 and player.afk_time > setting.afk_time
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
--- @param target LuaEntity
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

--- Attempt to insert an ItemStackDefinition or array of ItemStackDefinition into the entity
--- Spill to the ground at the entity anything that doesn't get inserted
--- @param entity LuaEntity
--- @param item_stacks ItemStackDefinition|ItemStackDefinition[]
--- @param is_return_cheat boolean
--- @return boolean #there was some items inserted or spilled
local function insert_or_spill_items(entity, item_stacks, is_return_cheat)
    if is_return_cheat then return end

    local new_stacks = {}
    if item_stacks then
        if item_stacks[1] and item_stacks[1].name then
            new_stacks = item_stacks
        elseif item_stacks and item_stacks.name then
            new_stacks = { item_stacks }
        end
        for _, stack in pairs(new_stacks) do
            local name, count, health = stack.name, stack.count, stack.health or 1
            if game.item_prototypes[name] and not game.item_prototypes[name].has_flag('hidden') then
                local inserted = entity.insert({ name = name, count = count, health = health })
                if inserted ~= count then
                    entity.surface.spill_item_stack(entity.position, { name = name, count = count - inserted, health = health }, true)
                end
            end
        end
        return new_stacks[1] and new_stacks[1].name and true
    end
end

--- Attempt to insert an arrary of items stacks into an entity
--- @param entity LuaEntity
--- @param item_stacks ItemStackDefinition|ItemStackDefinition[]
--- @return ItemStackDefinition[] #Items not inserted
local function insert_into_entity(entity, item_stacks)
    item_stacks = item_stacks or {}
    if item_stacks and item_stacks.name then item_stacks = { item_stacks } end
    local new_stacks = {}
    for _, stack in pairs(item_stacks) do
        local name, count, health = stack.name, stack.count, stack.health or 1
        local inserted = entity.insert(stack)
        if inserted ~= count then new_stacks[#new_stacks + 1] = { name = name, count = count - inserted, health = health } end
    end
    return new_stacks
end

--- Scan the ground under a ghost entities collision box for items and return an array of SimpleItemStack.
--- @param entity LuaEntity the entity object to scan under
--- @return ItemStackDefinition[] #array of ItemStackDefinition
local function get_all_items_on_ground(entity, existing_stacks)
    local item_stacks = existing_stacks or {}
    local surface, position, bouding_box = entity.surface, entity.position, entity.ghost_prototype.selection_box
    local area = Area.offset(bouding_box, position)
    for _, item_on_ground in pairs(surface.find_entities_filtered { name = 'item-on-ground', area = area }) do
        item_stacks[#item_stacks + 1] = { name = item_on_ground.stack.name, count = item_on_ground.stack.count, health = item_on_ground.health or 1 }
        item_on_ground.destroy()
    end
    local inserter_area = Area.expand(area, 3)
    for _, inserter in pairs(surface.find_entities_filtered { area = inserter_area, type = 'inserter' }) do
        local stack = inserter.held_stack
        if stack.valid_for_read and Position.inside(inserter.held_stack_position, area) then
            item_stacks[#item_stacks + 1] = { name = stack.name, count = stack.count, health = stack.health or 1 }
            stack.clear()
        end
    end
    return (item_stacks[1] and item_stacks) or {}
end

--- Get an item with health data from the inventory
--- @param entity LuaEntity the entity object to search
--- @param item_stack ItemStackDefinition the item to look for
--- @param cheat boolean cheat the item
--- @param at_least_one boolean #return as long as count > 0
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
        -- If we havn't returned here check the hand!
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
--- @param player LuaPlayer the player object --- Todo Character?
--- @param ammo LuaItemStack the ammo itemstack
--- @return boolean #Ammo was drained
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

--- Attempt to satisfy module requests from player inventory
--- @param requests LuaEntity the item request proxy to get requests from
--- @param entity LuaEntity the entity to satisfy requests for
--- @param player LuaEntity the entity to get modules from
local function satisfy_requests(requests, entity, player)
    local pinv = player.get_main_inventory()
    local new_requests = {}
    for name, count in pairs(requests.item_requests) do
        if count > 0 and entity.can_insert(name) then
            local removed = player.cheat_mode and count or pinv.remove({ name = name, count = count })
            local inserted = removed > 0 and entity.insert({ name = name, count = removed }) or 0
            local balance = count - inserted
            new_requests[name] = balance > 0 and balance or nil
        else
            new_requests[name] = count
        end
    end
    requests.item_requests = new_requests
end

--- Create a projectile from source to target
--- @param name string the name of the projecticle
--- @param surface LuaSurface the surface to create the projectile on
--- @param force LuaForce the force this projectile belongs too
--- @param source MapPosition|LuaEntity position table to start at
--- @param target MapPosition|LuaEntity position table to end at
local function create_projectile(name, surface, force, source, target, speed)
    speed = speed or 1
    force = force or 'player'
    surface.create_entity { name = name, force = force, source = source, position = source, target = target, speed = speed }
end

--[[Nano Emitter Queue Handler --]]
-- Queued items are handled one at a time, --check validity of all stored objects at this point, They could have become
-- invalidated between the time they were entered into the queue and now.

--- @param data Nanobots.data
function Queue.cliff_deconstruction(data)
    local entity, player = data.entity, game.get_player(data.player_index)
    if not (player and player.valid) then return end

    if not (entity and entity.valid and entity.to_be_deconstructed()) then return insert_or_spill_items(player, { data.item_stack }) end

    create_projectile('nano-projectile-deconstructors', entity.surface, entity.force, player.position, entity.position)
    local exp_name = data.item_stack.name == 'artillery-shell' and 'big-artillery-explosion' or 'big-explosion'
    entity.surface.create_entity { name = exp_name, position = entity.position }
    entity.destroy({ do_cliff_correction = true, raise_destroy = true })
end

-- Handles all of the deconstruction and scrapper related tasks.
--- @param data Nanobots.data
function Queue.deconstruction(data)
    local entity = data.entity
    local player = game.get_player(data.player_index)
    if not (player and player.valid) then return end

    if not (entity and entity.valid and entity.to_be_deconstructed()) then return end

    local surface = data.surface or entity.surface
    local force = entity.force
    local ppos = player.position
    local epos = entity.position

    create_projectile('nano-projectile-deconstructors', surface, force, ppos, epos)
    create_projectile('nano-projectile-return', surface, force, epos, ppos)

    if entity.name == 'deconstructible-tile-proxy' then
        local tile = surface.get_tile(epos)
        if tile then
            player.mine_tile(tile)
            entity.destroy()
        end
    else
        player.mine_entity(entity)
    end
end

--- @param data Nanobots.data
function Queue.build_entity_ghost(data)
    local ghost = data.entity
    local player = data.player
    local surface = data.surface
    local position = data.position
    if not (player and player.valid) then return end

    if not (ghost.valid and ghost.ghost_name == data.entity_name) then return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode) end

    local item_stacks = get_all_items_on_ground(ghost)
    if not surface.can_place_entity { name = ghost.ghost_name, position = ghost.position, direction = ghost.direction, force = data.force } then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end

    local revived, entity, requests = ghost.revive { return_item_request_proxy = true, raise_revive = true }

    if not revived then return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode) end

    if not entity then
        if insert_or_spill_items(player, item_stacks, player.cheat_mode) then
            create_projectile('nano-projectile-return', surface, player.force, position, player.position)
        end
        return
    end

    create_projectile('nano-projectile-constructors', entity.surface, entity.force, player.position, entity.position)
    entity.health = (entity.health > 0) and ((data.item_stack.health or 1) * entity.prototype.max_health)
    if insert_or_spill_items(player, insert_into_entity(entity, item_stacks)) then
        create_projectile('nano-projectile-return', surface, player.force, position, player.position)
    end
    if requests then satisfy_requests(requests, entity, player) end
end

--- @param data Nanobots.data
function Queue.build_tile_ghost(data)
    local ghost = data.entity
    local player = data.player
    local surface = data.surface
    local position = data.position
    if not (player and player.valid) then return end

    if not ghost.valid then return insert_or_spill_items(player, { data.item_stack }) end

    local tile, hidden_tile = surface.get_tile(position), surface.get_hidden_tile(position)
    local force = data.force
    local tile_was_mined = hidden_tile and tile.prototype.can_be_part_of_blueprint and player.mine_tile(tile)
    local ghost_was_revived = ghost.valid and ghost.revive({ raise_revive = true }) -- Mining tiles invalidates ghosts
    if not (tile_was_mined or ghost_was_revived) then return insert_or_spill_items(player, { data.item_stack }) end

    local item_ptype = data.item_stack and game.item_prototypes[data.item_stack.name]
    local tile_ptype = item_ptype and item_ptype.place_as_tile_result.result
    create_projectile('nano-projectile-constructors', surface, force, player.position, position)
    Position.floored(position)
    -- if the tile was mined, we need to manually place the tile.
    -- checking if the ghost was revived is likely unnecessary but felt safer.
    if tile_was_mined and not ghost_was_revived then
        create_projectile('nano-projectile-return', surface, force, position, player.position)
        surface.set_tiles({ { name = tile_ptype.name, position = position } }, true, true, false, true)
    end

    surface.play_sound { path = 'nano-sound-build-tiles', position = position }
end

--- @param data Nanobots.data
function Queue.upgrade_direction(data)
    local ghost = data.entity
    local player = data.player
    local surface = data.surface
    if not (player and player.valid) then return end

    if not ghost.valid and not ghost.to_be_upgraded() then return end

    ghost.direction = data.direction
    ghost.cancel_upgrade(player.force, player)
    create_projectile('nano-projectile-constructors', ghost.surface, data.force, player.position, ghost.position)
    surface.play_sound { path = 'utility/build_small', position = ghost.position }
end

--- @param data Nanobots.data
function Queue.upgrade_ghost(data)
    local ghost = data.entity
    local player = data.player
    local surface = data.surface
    local position = data.position
    if not (player and player.valid) then return end

    if not ghost.valid then return insert_or_spill_items(player, { data.item_stack }) end

    local entity = surface.create_entity {
        name = data.entity_name or data.item_stack.name,
        direction = ghost.direction,
        force = ghost.force,
        position = position,
        fast_replace = true,
        player = player,
        type = ghost.type == 'underground-belt' and ghost.belt_to_ground_type or nil,
        raise_built = true
    }
    if not entity then return insert_or_spill_items(player, { data.item_stack }) end

    create_projectile('nano-projectile-constructors', entity.surface, entity.force, player.position, entity.position)
    surface.play_sound { path = 'utility/build_small', position = entity.position }
    entity.health = (entity.health > 0) and ((data.item_stack.health or 1) * entity.prototype.max_health)
end

--- @param data Nanobots.data
function Queue.item_requests(data)
    local proxy = data.entity
    local player = game.get_player(data.player_index)
    local target = proxy.valid and proxy.proxy_target ---@type LuaEntity
    if not (player and player.valid) then return end

    if not (proxy.valid and target and target.valid) then return insert_or_spill_items(player, { data.item_stack }) end

    if not target.can_insert(data.item_stack) then return insert_or_spill_items(player, { data.item_stack }) end

    create_projectile('nano-projectile-constructors', proxy.surface, proxy.force, player.position, proxy.position)
    local item_stack = data.item_stack
    local requests = proxy.item_requests
    local inserted = target.insert(item_stack)
    item_stack.count = item_stack.count - inserted

    if item_stack.count > 0 then insert_or_spill_items(player, { item_stack }) end

    requests[item_stack.name] = requests[item_stack.name] - inserted
    for k, count in pairs(requests) do if count == 0 then requests[k] = nil end end

    if table_size(requests) > 0 then
        proxy.item_requests = requests
    else
        proxy.destroy()
    end
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
    local force = player.force
    local _next_nano_tick = (pdata._next_nano_tick and pdata._next_nano_tick < (game.tick + 2000) and pdata._next_nano_tick) or game.tick
    local tick_spacing = max(1, setting.queue_rate - (QUEUE_SPEED[force.get_gun_speed_modifier('nano-ammo')] or QUEUE_SPEED[4]))
    local next_tick, queue_count = queue:next(_next_nano_tick, tick_spacing)
    pdata._next_nano_tick = next_tick() or game.tick
    local radius = get_ammo_radius(player, ammo)
    local area = Position.expand_to_area(pos, radius)
    local cheat_mode = player.cheat_mode

    for _, ghost in pairs(player.surface.find_entities(area)) do
        local ghost_force = ghost.force

        local same_force = ghost_force == force
        local deconstruct = ghost.to_be_deconstructed()
        local upgrade = ghost.to_be_upgraded() and ghost_force == force

        if not ammo.valid_for_read then return end
        if queue_count() >= setting.queue_cycle then return end
        if not (deconstruct or upgrade or same_force) then goto next_ghost end
        if setting.network_limits and not is_outside_network(player.character, ghost) then goto next_ghost end
        if queue:get_hash(ghost) then goto next_ghost end

        local ghost_surface = ghost.surface

        --- @class Nanobots.data
        local data = {
            player_index = player.index,
            player = player,
            ammo = ammo,
            position = ghost.position,
            surface = ghost_surface,
            unit_number = ghost.unit_number,
            entity = ghost,
            force = ghost_force
        }

        if deconstruct then
            if ghost.type == 'cliff' then
                if force.technologies['nanobots-cliff'].researched then
                    local item_name = table_find(explosives, _find_item, player)
                    if item_name then
                        local explosive = get_items_from_inv(player, item_name, cheat_mode)
                        if explosive then
                            data.item_stack = explosive
                            data.action = 'cliff_deconstruction'
                            queue:insert(data, next_tick())
                            drain_ammo(player, ammo, 1)
                        end
                    end
                end
            elseif ghost.minable then
                data.action = 'deconstruction'
                queue:insert(data, next_tick())
                drain_ammo(player, ammo, 1)
            end
        elseif upgrade then
            local prototype = ghost.get_upgrade_target()
            if prototype then
                if prototype.name == ghost.name then
                    local dir = ghost.get_upgrade_direction()
                    if ghost.direction ~= dir then
                        data.action = 'upgrade_direction'
                        data.direction = dir
                        queue:insert(data, next_tick())
                        drain_ammo(player, ammo, 1)
                    end
                else
                    local item_stack = table_find(prototype.items_to_place_this, _find_item, player)
                    if item_stack then
                        data.action = 'upgrade_ghost'
                        local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if place_item then
                            data.entity_name = prototype.name
                            data.item_stack = place_item
                            queue:insert(data, next_tick())
                            drain_ammo(player, ammo, 1)
                        end
                    end
                end
            end
        elseif ghost.name == 'entity-ghost' or (ghost.name == 'tile-ghost' and setting.build_tiles) then
            -- get first available item that places entity from inventory that is not in our hand.
            local proto = ghost.ghost_prototype
            local item_stack = table_find(proto.items_to_place_this, _find_item, player)
            if item_stack then
                if ghost.name == 'entity-ghost' then
                    local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                    if place_item then
                        data.action = 'build_entity_ghost'
                        data.entity_name = proto.name
                        data.item_stack = place_item
                        queue:insert(data, next_tick())
                        drain_ammo(player, ammo, 1)
                    end
                elseif ghost.name == 'tile-ghost' then
                    -- Don't queue tile ghosts if entity ghost is on top of it.
                    if ghost_surface.count_entities_filtered { name = 'entity-ghost', area = Area(ghost.bounding_box):non_zero(), limit = 1 } == 0 then
                        local tile = ghost_surface.get_tile(ghost.position)
                        if tile then
                            local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                            if place_item then
                                data.item_stack = place_item
                                data.action = 'build_tile_ghost'
                                queue:insert(data, next_tick())
                                drain_ammo(player, ammo, 1)
                            end
                        end
                    end
                end
            end
        elseif is_nanobot_repairable(ghost) then
            -- Check if entity needs repair, TODO: Better logic for this?
            if ghost_surface.count_entities_filtered { name = 'nano-cloud-small-repair', position = ghost.position } == 0 then
                create_projectile('nano-projectile-repair', ghost_surface, force, player.position, ghost.position, .5)
                queue_count(1)
                drain_ammo(player, ammo, 1)
            end -- repair
        elseif ghost.name == 'item-request-proxy' and setting.do_proxies then
            local items = {}
            for item, count in pairs(ghost.item_requests) do items[#items + 1] = { name = item, count = count } end
            local item_stack = table_find(items, _find_item, player, true)
            if item_stack then
                local place_item = get_items_from_inv(player, item_stack, cheat_mode, true)
                if place_item and place_item.count > 0 then
                    data.action = 'item_requests'
                    data.item_stack = place_item
                    queue:insert(data, next_tick())
                    drain_ammo(player, ammo, 1)
                end
            end
        end
        ::next_ghost::
    end
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
                --- @type LuaSurface.create_entity_param
                local params =
                    { name = 'nano-projectile-termites', source = player, position = player.position, force = force, target = stupid_tree, speed = .5 }
                surface.create_entity(params)
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
            local player
            global._last_player, player = next(game.connected_players, global._last_player)
            if not (player and is_player_afk(player)) then return end

            local character = player.character
            if not character then return end

            if setting.equipment_auto then prepare_chips(player) end

            if not setting.nanobots_auto then return end

            if setting.network_limits and not is_outside_network(character) then return end

            local gun, ammo = get_gun_ammo_name(player, NANO_EMITTER)
            if not gun then return end

            local ammo_name = ammo.name
            if ammo_name == 'ammo-nano-constructors' then
                queue_ghosts_in_range(player, player.position, ammo)
            elseif ammo_name == 'ammo-nano-termites' then
                everyone_hates_trees(player, player.position, ammo)
            end
        end
    end
    Event.register(defines.events.on_tick, poll_players)

    local function update_settings()
        setting = {
            poll_rate = settings['global']['nanobots-nano-poll-rate'].value,
            queue_rate = settings['global']['nanobots-nano-queue-rate'].value,
            queue_cycle = settings['global']['nanobots-nano-queue-per-cycle'].value,
            build_tiles = settings['global']['nanobots-nano-build-tiles'].value,
            network_limits = settings['global']['nanobots-network-limits'].value,
            nanobots_auto = settings['global']['nanobots-nanobots-auto'].value,
            equipment_auto = settings['global']['nanobots-equipment-auto'].value,
            afk_time = settings['global']['nanobots-afk-time'].value,
            do_proxies = settings['global']['nanobots-nano-fullfill-requests'].value
        }
    end
    Event.register(defines.events.on_runtime_mod_setting_changed, update_settings)

    Event.register({ defines.events.on_player_joined_game, defines.events.on_player_left_game }, function()
        -- Reset last player when players join or leave
        global._last_player = nil
    end)

    Event.register(Event.core_events.init, function()
        global.nano_queue = Queue()
        queue = global.nano_queue
        game.print('Nanobots are now ready to serve')
        update_settings()
    end)

    Event.register(Event.core_events.load, function()
        queue = Queue(global.nano_queue)
        update_settings()
    end)

    Event.register(Event.generate_event_name('reset_nano_queue'), function()
        game.print('Resetting Nano Queue')
        global.nano_queue = Queue()
        queue = global.nano_queue
        for _, player in pairs(global.players) do player._next_nano_tick = 0 end
    end)
end
