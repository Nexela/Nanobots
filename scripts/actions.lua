--[[Nano Emitter Queue Handler --]]
-- Queued items are handled one at a time, --check validity of all stored objects at this point, They could have become
-- invalidated between the time they were entered into the queue and now.
local Actions = {}

local Area = require("__stdlib__/stdlib/area/area")
local Position = require("__stdlib__/stdlib/area/position")

--- Attempt to insert an ItemStackDefinition or array of ItemStackDefinition into the entity
--- Spill to the ground at the entity anything that doesn't get inserted
--- @param entity LuaEntity|LuaPlayer
--- @param item_stacks ItemStackDefinition|ItemStackDefinition[]
--- @param is_return_cheat? boolean
--- @return boolean #there was some items inserted or spilled
local function insert_or_spill_items(entity, item_stacks, is_return_cheat)
    if is_return_cheat then return false end

    local new_stacks = {}
    if item_stacks then
        if item_stacks[1] and item_stacks[1].name then
            new_stacks = item_stacks
        elseif item_stacks and item_stacks.name then
            new_stacks = { item_stacks }
        end
        for _, stack in pairs(new_stacks) do
            local name, count, health = stack.name, stack.count, stack.health or 1.0
            local prototype = game.item_prototypes[name]
            if prototype and not prototype.has_flag("hidden") then
                local inserted = entity.insert { name = name, count = count, health = health }
                if inserted ~= count then
                    entity.surface.spill_item_stack(entity.position, { name = name, count = count - inserted, health = health }, true)
                end
            end
        end
        return new_stacks[1] and new_stacks[1].name and true
    end
    return false
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

--- Scan the ground under a ghost entities collision box for items and return an array of ItemStackDefinition.
--- @param surface LuaSurface
--- @param box BoundingBox
--- @return ItemStackDefinition[]
local function get_all_items_on_ground(surface, box)
    local item_stacks = {}
    for _, item_on_ground in pairs(surface.find_entities_filtered { name = "item-on-ground", area = box }) do
        item_stacks[#item_stacks + 1] = { name = item_on_ground.stack.name, count = item_on_ground.stack.count, health = item_on_ground.health or 1 }
        item_on_ground.destroy()
    end
    local inserter_area = Area.expand(box, 3)
    for _, inserter in pairs(surface.find_entities_filtered { area = inserter_area, type = "inserter" }) do
        local stack = inserter.held_stack
        if stack.valid_for_read and Position.inside(inserter.held_stack_position, box) then
            item_stacks[#item_stacks + 1] = { name = stack.name, count = stack.count, health = stack.health or 1 }
            stack.clear()
        end
    end
    return item_stacks
end

--- Attempt to satisfy module requests from player inventory
--- @param requests LuaEntity the item request proxy to get requests from
--- @param entity LuaEntity the entity to satisfy requests for
--- @param player LuaPlayer the player to get modules from
local function satisfy_requests(requests, entity, player)
    local p_inv = player.get_main_inventory()
    local new_requests = {}
    for name, count in pairs(requests.item_requests) do
        if count > 0 and entity.can_insert(name) then
            local removed = player.cheat_mode and count or p_inv.remove { name = name, count = count }
            local inserted = removed > 0 and entity.insert { name = name, count = removed } or 0
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
--- @param force ForceIdentification the force this projectile belongs too
--- @param source MapPosition|LuaEntity position table to start at
--- @param target MapPosition|LuaEntity position table to end at
local function create_projectile(name, surface, force, source, target, speed)
    speed = speed or 1
    force = force or "player"
    surface.create_entity {
        name = name,
        force = force,
        source = source,
        position = source --[[@as MapPosition]] ,
        target = target,
        speed = speed
    }
end

--- @param data Nanobots.action_data
function Actions.cliff_deconstruction(data)
    local player = data.player
    if not (player and player.valid) then return end

    local entity = data.entity
    if not (entity and entity.valid and entity.to_be_deconstructed()) then
        return insert_or_spill_items(player--[[@as LuaEntity]] , { data.item_stack })
    end

    create_projectile("nano-projectile-deconstructors", entity.surface, entity.force, player.position, entity.position)
    local exp_name = data.item_stack.name == "artillery-shell" and "big-artillery-explosion" or "big-explosion"
    entity.surface.create_entity { name = exp_name, position = entity.position }
    entity.destroy { do_cliff_correction = true, raise_destroy = true }
end

-- Handles all of the deconstruction and scrapper related tasks.
--- @param data Nanobots.action_data
function Actions.deconstruction(data)
    local player = data.player
    if not (player and player.valid) then return end

    local entity = data.entity
    if not (entity and entity.valid and entity.to_be_deconstructed()) then return end

    local surface = data.surface or entity.surface
    local force = entity.force
    local p_pos = player.position --[[@as MapPosition.0 Source Bug]]
    local e_pos = entity.position --[[@as MapPosition.0 Source bug]]

    create_projectile("nano-projectile-deconstructors", surface, force, p_pos, e_pos)
    create_projectile("nano-projectile-return", surface, force, e_pos, p_pos)

    if entity.name == "deconstructible-tile-proxy" then
        local tile = surface.get_tile(e_pos--[[@as TilePosition]] )
        if tile then
            player.mine_tile(tile)
            entity.destroy()
        end
    else
        player.mine_entity(entity)
    end
end

--- @param data Nanobots.action_data
function Actions.build_entity_ghost(data)
    local player = data.player
    if not (player and player.valid) then return end

    local ghost = data.entity
    if not (ghost and ghost.valid) then return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode) end

    local surface = data.surface
    local position = data.position
    local item_stacks = get_all_items_on_ground(surface, ghost.selection_box)
    if not surface.can_place_entity {
        name = ghost.ghost_name,
        position = position,
        direction = ghost.direction,
        force = data.force,
        build_check_type = defines.build_check_type.manual
    } then
        return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode)
    end

    local revived, entity, requests = ghost.revive { return_item_request_proxy = true, raise_revive = true }
    if not revived then return insert_or_spill_items(player, { data.item_stack }, player.cheat_mode) end

    if not entity then
        if insert_or_spill_items(player, item_stacks, player.cheat_mode) then
            create_projectile("nano-projectile-return", surface, player.force, position, player.position)
        end
        return
    end

    create_projectile("nano-projectile-constructors", entity.surface, entity.force, player.position, entity.position)
    entity.health = (entity.health and (data.item_stack.health or 1.0) * entity.prototype.max_health) or 0.0
    if insert_or_spill_items(player, insert_into_entity(entity, item_stacks)) then
        create_projectile("nano-projectile-return", surface, player.force, position, player.position)
    end
    if requests then satisfy_requests(requests, entity, player) end
end

--- @param data Nanobots.action_data
function Actions.build_tile_ghost(data)
    local player = data.player
    if not (player and player.valid) then return end

    local ghost = data.entity
    local tile = data.tile
    if not (ghost.valid and tile.valid) then return insert_or_spill_items(player, { data.item_stack }) end

    local position = data.position
    local surface = data.surface
    local force = data.force
    local tile_was_mined = tile.hidden_tile and tile.prototype.can_be_part_of_blueprint and player.mine_tile(tile)
    local ghost_was_revived = ghost.valid and ghost.revive { raise_revive = true } -- Mining tiles invalidates ghosts
    if not (tile_was_mined or ghost_was_revived) then return insert_or_spill_items(player, { data.item_stack }) end

    local item_stack = data.item_stack
    local item_prototype = item_stack and game.item_prototypes[item_stack.name]
    local tile_prototype = item_prototype and item_prototype.place_as_tile_result.result
    create_projectile("nano-projectile-constructors", surface, force, player.position, position)
    Position.floored(position)
    -- if the tile was mined, we need to manually place the tile.
    -- checking if the ghost was revived is likely unnecessary but felt safer.
    if tile_was_mined and not ghost_was_revived then
        create_projectile("nano-projectile-return", surface, force, position, player.position)
        surface.set_tiles({
            { name = tile_prototype.name, position = position --[[@as TilePosition]] }
        }, true, true, false, true)
    end

    surface.play_sound { path = "nano-sound-build-tiles", position = position }
end

--- @param data Nanobots.action_data
function Actions.upgrade_direction(data)
    local player = data.player
    if not (player and player.valid) then return end

    local ghost = data.entity
    if not (ghost.valid and ghost.to_be_upgraded()) then return end

    local surface = data.surface
    ghost.direction = data.direction
    ghost.cancel_upgrade(player.force, player)
    create_projectile("nano-projectile-constructors", ghost.surface, data.force, player.position, ghost.position)
    surface.play_sound { path = "utility/build_small", position = ghost.position }
end

--- @param data Nanobots.action_data
function Actions.upgrade_ghost(data)
    local player = data.player
    if not (player and player.valid) then return end

    local ghost = data.entity
    if not (ghost.valid and ghost.to_be_upgraded()) then return insert_or_spill_items(player, { data.item_stack }) end

    local surface = data.surface
    local position = data.position
    local entity = surface.create_entity {
        name = data.entity_name or data.item_stack.name,
        direction = ghost.direction,
        force = ghost.force,
        position = position,
        fast_replace = true,
        player = player,
        type = ghost.type == "underground-belt" and ghost.belt_to_ground_type or nil,
        raise_built = true
    }
    if not entity then return insert_or_spill_items(player, { data.item_stack }) end

    create_projectile("nano-projectile-constructors", entity.surface, entity.force, player.position, entity.position)
    surface.play_sound { path = "utility/build_small", position = entity.position }
    entity.health = (entity.health > 0.0) and ((data.item_stack.health or 1.0) * entity.prototype.max_health) --[[@as float]]
end

--- @param data Nanobots.action_data
function Actions.repair_entity(data)
    local player = data.player
    if not (player and player.valid) then return end

    local surface = data.surface
    local force = data.force
    if surface.count_entities_filtered { name = "nano-cloud-small-repair", position = data.position } > 0 then return end
    create_projectile("nano-projectile-repair", surface, force, player.position, data.position, .5)
end

--- @param data Nanobots.action_data
function Actions.item_requests(data)
    local player = data.player
    if not (player and player.valid) then return end

    local proxy = data.entity
    local target = proxy.valid and proxy.proxy_target
    if not (proxy.valid and target and target.valid) then return insert_or_spill_items(player, { data.item_stack }) end

    if not target.can_insert(data.item_stack) then return insert_or_spill_items(player, { data.item_stack }) end

    create_projectile("nano-projectile-constructors", proxy.surface, proxy.force, player.position, proxy.position)
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

return Actions
