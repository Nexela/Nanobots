require("stdlib/loader")

MOD = {}
MOD.name = "Nanobots"
MOD.interface = "nanobots"
MOD.config = require("config")
MOD.version = "1.5.0"

local Position = require("stdlib/area/position")
local Area = require("stdlib/area/area")
local List = require("stdlib/utils/list")
local Force = require("scripts/force")
local Player = require("scripts/player")

if DEBUG then --luacheck: ignore DEBUG
    log(MOD.name .. " Debug mode enabled")
    QS = MOD.config.quickstart --luacheck: ignore QS
    require("stdlib/debug/quickstart")
end

-------------------------------------------------------------------------------
--[[Helper Functions]]--
-------------------------------------------------------------------------------

-- Local constants from config
local bot_radius = MOD.config.BOT_RADIUS
local termite_radius = MOD.config.TERMITE_RADIUS
local queue_speed = MOD.config.QUEUE_SPEED_BONUS
local combat_robots = MOD.config.COMBAT_ROBOTS
local transport_types = MOD.config.TRANSPORT_TYPES
local healer_capsules = MOD.config.FOOD
local train_types = MOD.config.TRAIN_TYPES

-- Limited list of inventorys to search
local function cull_inventory_list(list)
    local temp , culled_list = {}, {}
    for _, value in pairs(list) do
        temp[value] = true
    end
    for ind in pairs(temp) do
        culled_list[#culled_list+1] = ind
    end
    return culled_list
end
local inv_list = cull_inventory_list{
    defines.inventory.player_main,
    defines.inventory.player_quickbar,
    defines.inventory.chest,
    defines.inventory.player_vehicle,
    defines.inventory.player_trash,
    defines.inventory.car_trunk,
    defines.inventory.cargo_wagon
}

-- Local functions for commonly used math functions
local min, random, max, floor, ceil, abs = math.min, math.random, math.max, math.floor, math.ceil, math.abs --luacheck: ignore

-- Is cheat mode active and are we syncing with cheat mode
-- @param p: the player object
-- @return bool: cheating
local function get_cheat_mode(p)
    return p.cheat_mode and global.config.sync_cheat_mode
end

--table.find functions
local table_find = table.find
-- return true for table.find if we found at least 1 item or cheat_mode is enabled.
local _find_item = function(_, k, p)
    return get_cheat_mode(p) or p.get_item_count(k) > 0 or
    (p.vehicle and (p.vehicle.get_item_count(k) > 0 or (train_types[p.vehicle.type] and p.vehicle.train.get_item_count(k) > 0)))
end
-- return true for table.find if entity equals stored entity
local _find_entity_match = function(v, _, entity)
    if type(v) == "table" then return v.entity == entity end
end

-- Is the player connected, not afk, and have an attached character
-- @param player: the player object
-- @return bool: player is connected and ready
local function is_connected_player_ready(player)
    --and player.force.technologies["automated-construction"].researched
    return (player.afk_time < 180 and player.character) or false
end

-- Loop through armor and return a table of valid equipment tables indexed by equipment name
-- @param player: the player object
-- @return table: a table of valid equipment, name as key, array of named equipment as value .
local function get_valid_equipment(player)
    local armor = player.get_inventory(defines.inventory.player_armor)
    local list = {}
    if armor and armor[1] and armor[1].valid_for_read and armor[1].grid and armor[1].grid.equipment then
        for _, equip in pairs(armor[1].grid.equipment) do
            if equip.energy > 0 then
                list[equip.name] = list[equip.name] or {}
                list[equip.name][#list[equip.name] + 1] = equip
            end
        end
    end
    return list
end

-- Is the player not in a logistic network or has a working nano-interface
-- @param player: the player object
-- @return bool: true if has chip or not in network
local function nano_network_check(player, entity)
    if entity then
        return get_valid_equipment(player)["equipment-bot-chip-nanointerface"] or not entity.surface.find_logistic_network_by_position(entity.position, entity.force)
    else
        return get_valid_equipment(player)["equipment-bot-chip-nanointerface"] or not player.character.logistic_network
    end
end

-- Increment the y position for flying text to keep text from overlapping
-- @param position: position table - start position
-- @return function: increments position all subsequent calls
local function increment_position(position)
    local x = position.x - 1
    local y = position.y - .5
    return function ()
        y=y+0.5
        return {x=x, y=y}
    end
end

-- Can nanobots repair this entity.
-- @param entity: the entity object
-- @return bool: repairable by nanobots
local function nano_repairable_entity(entity)
    return (entity.health and entity.health > 0 and entity.health < entity.prototype.max_health) and not
    (entity.has_flag("breaths-air") or ((entity.type == "car" or entity.type == "train") and entity.speed > 0) or entity.type:find("robot"))
end

-- TODO: Checking for the gun just wastes time, we could check the ammo directly. id:7
-- This is also horrendous
-- Get the gun, ammo and ammo name for the named gun: will return nil
-- for all returns if there is no ammo for the gun.
-- @param player: the player object
-- @param gun_name: the name of the gun to get
-- @return the gun object or nil
-- @return the ammo object or nil
-- @return string: the name of the ammo or nil
local function get_gun_ammo_name(player, gun_name)
    local index = player.character.selected_gun_index
    local gun = player.get_inventory(defines.inventory.player_guns)[index]
    local ammo = player.get_inventory(defines.inventory.player_ammo)[index]
    if gun.valid_for_read and gun.name == gun_name and ammo.valid and ammo.valid_for_read then
        return gun, ammo, ammo.name
    end
    return nil, nil, nil
end

-- Does the character have a personal robort and construction robots. Or is in range of a roboport with bots.
-- character: the player character
-- @return bool: true or false
local function are_bots_ready(c)
    if c.logistic_cell and c.logistic_cell.mobile and c.logistic_cell.construction_radius > 0 then
        if c.logistic_cell.stationed_construction_robot_count > 0 then
            return true
        else
            local port = c.surface.find_entities_filtered{
                type = "roboport",
                area=Position.expand_to_area(c.position, c.logistic_cell.construction_radius),
                limit = 1,
                force = c.force
            }[1]
            if port and port.logistic_network and port.logistic_network.all_construction_robots > 0 then
                return true
            end
        end
    end
end

-- Attempt to insert an item_stack or array of item_stacks into the entity
-- Spill to the ground at the entity/player anything that doesn't get inserted
-- @param entity: the entity or player object
-- @param item_stacks: a SimpleItemStack or array of SimpleItemStacks to insert
-- @return bool : there was some items inserted or spilled
local function insert_or_spill_items(entity, item_stacks)
    local new_stacks = {}
    if item_stacks then
        if item_stacks[1] and item_stacks[1].name then
            new_stacks = item_stacks
        elseif item_stacks and item_stacks.name then
            new_stacks = {item_stacks}
        end
        for _, stack in pairs(new_stacks) do
            local name, count, health = stack.name, stack.count, stack.health or 1
            local inserted = entity.insert({name=name, count=count, health=health})
            if inserted ~= count then
                entity.surface.spill_item_stack(entity.position, {name=name, count=count-inserted, health=health}, true)
            end
        end
        return new_stacks[1] and new_stacks[1].name and true
    end
end

-- Attempt to insert an arrary of items stacks into an entity
-- @param entity: the entity object
-- @param item_stacks: a SimpleItemStack or array of SimpleitemStacks to insert
-- @return table: an array of SimpleItemStacks not inserted
local function insert_into_entity(entity, item_stacks)
    item_stacks = item_stacks or {}
    if item_stacks and item_stacks.name then
        item_stacks = {item_stacks}
    end
    local new_stacks = {}
    for _, stack in pairs(item_stacks) do
        local name, count, health = stack.name, stack.count, stack.health or 1
        local inserted = entity.insert(stack)
        if inserted ~= count then
            new_stacks[#new_stacks + 1] = {name=name, count = count - inserted, health=health}
        end
    end
    return new_stacks
end

-- Remove all items inside an entity and return an array of SimpleItemStacks removed
-- @param entity: The entity object to remove items from
-- @return table: a table of SimpleItemStacks or nil if empty
local function get_all_items_inside(entity, existing_stacks)
    local item_stacks = existing_stacks or {}
    --Inserters need to check held_stack
    if entity.type == "inserter" then
        local stack = entity.held_stack
        if stack.valid_for_read then
            item_stacks[#item_stacks+1] = {name=stack.name, count=stack.count, health=stack.health}
            stack.clear()
        end
        --Entities with transport lines only need to check each line individually
    elseif transport_types[entity.type] then
        for i=1, transport_types[entity.type] do
            local lane = entity.get_transport_line(i)
            for name, count in pairs(lane.get_contents()) do
                local cur_stack = {name=name, count=count, health=1}
                item_stacks[#item_stacks+1] = cur_stack
                lane.remove_item(cur_stack)
            end
        end
    else
        --Loop through regular inventories
        for _, inv in pairs(defines.inventory) do
            local inventory = entity.get_inventory(inv)
            if inventory and inventory.valid then
                if inventory.get_item_count() > 0 then
                    for i=1, #inventory do
                        if inventory[i].valid_for_read then
                            local stack = inventory[i]
                            item_stacks[#item_stacks+1] = {name=stack.name, count=stack.count, health=stack.health or 1}
                            stack.clear()
                        end
                    end
                end
            end
        end
    end
    return (item_stacks[1] and item_stacks) or {}
end

-- Scan the ground under a ghost entities collision box for items and insert them into the player.
-- @param entity: the entity object to scan under
-- @return table: a table of SimpleItemStacks or nil if empty
local function get_all_items_on_ground(entity, existing_stacks)
    local item_stacks = existing_stacks or {}
    local surface, position, bouding_box = entity.surface, entity.position, entity.ghost_prototype.selection_box
    local area = Area.offset(bouding_box, position)
    for _, item_on_ground in pairs(surface.find_entities_filtered{name="item-on-ground", area=area}) do
        item_stacks[#item_stacks+1] = {name=item_on_ground.stack.name, count=item_on_ground.stack.count, health=item_on_ground.health or 1}
        item_on_ground.destroy()
    end
    local inserter_area = Area.expand(area, 3)
    for _ , inserter in pairs(surface.find_entities_filtered{area=inserter_area, type="inserter"}) do
        local stack = inserter.held_stack
        if stack.valid_for_read and Area.inside(area, inserter.held_stack_position) then
            item_stacks[#item_stacks+1] = {name=stack.name, count=stack.count, health=stack.health or 1}
            stack.clear()
        end
    end
    return (item_stacks[1] and item_stacks) or {}
end

-- Get one item with health data from the inventory
-- @param entity: the entity object to search
-- @param item: the item to look for
-- @return item_stack; SimpleItemStack
local function get_one_item_from_inv(entity, item, cheat)
    if not cheat then
        local sources
        if entity.vehicle and train_types[entity.vehicle.type] and entity.vehicle.train then
            sources = entity.vehicle.train.cargo_wagons
            sources[#sources+1] = entity
        elseif entity.vehicle then
            sources = {entity.vehicle, entity}
        else
            sources = {entity}
        end
        for _, source in pairs(sources) do
            for _, inv in pairs(inv_list) do
                local inventory = source.get_inventory(inv)
                if inventory and inventory.valid then
                    local stack=inventory.find_item_stack(item)
                    if stack then
                        local item_stack = {name=stack.name, count=1, health=stack.health or 1}
                        stack.count = stack.count - 1
                        return item_stack
                    end
                end
            end
        end
    else
        return {name=item, count=1, health=1}
    end
end

-- Manually drain ammo, if it is the last bit of ammo in the stack pull in more ammo from inventory if available
-- @param player: the player object
-- @param ammo: the ammo itemstack
-- @return bool: this was the last one to be drained
local function ammo_drain(player, ammo)
    local name = ammo.name
    ammo.drain_ammo(1)
    if not ammo.valid_for_read then
        local new = player.get_inventory(defines.inventory.player_main).find_item_stack(name)
        if new then
            ammo.set_stack(new)
            new.clear()
        end
        return true
    end
end

-- Get the stacks of modules not inserted and modules to insert
-- @param player: the entity to get modules from
-- @param entity: the ghost entity to get requests from (.15 can switch to item-proxy)
-- @return table: array of SimpleItemStacks missing modules
-- @return table: array of SimpleItemStacks to insert
local function get_insertable_module_requests(player, entity)
    if entity.name == "entity-ghost" and entity.item_requests then
        local item_requests = entity.item_requests
        local module_contents = {}
        if (entity.ghost_type == "assembling-machine" and entity.recipe) or entity.ghost_type ~= "assembling-machine" then
            item_requests = entity.item_requests
            for i, module_stack in pairs(item_requests) do
                local removed_modules = player.remove_item({name=module_stack.item, count=module_stack.count})
                if removed_modules > 0 then
                    --Modules removed from inventory that can be inserted
                    table.insert(module_contents, {name=module_stack.item, count=removed_modules})
                end
                if removed_modules < module_stack.count then
                    item_requests[i].count = module_stack.count - removed_modules
                else
                    item_requests[i] = nil
                end
            end
        end
        return item_requests, module_contents[1] and module_contents
    end
end

-- Create a beam if the player is present, create a proxy target if target doesn't have health
-- @param beam: string name of the beam to use
-- @param cloud: string name of the cloud to use if player isn't connected
-- @param player: the player object
-- @param target: the target entity object
local function create_beam_or_cloud(beam, cloud, player, target) --luacheck: ignore
    local connected_char = (player.connected and player.controller_type == defines.controllers.character) and player.character
    local surface = player.surface
    local speed, duration = .5, 20
    local new_target = surface.create_entity{name="nano-proxy-health", position=target.position, force="neutral"}
    --if there is a connected char use beam, otherwise just create cloud
    if connected_char and player.can_reach_entity(new_target) then
        surface.create_entity{
            name=beam,
            position=connected_char.position,
            force=player.force,
            target=new_target,
            source=connected_char,
            speed=speed,
            duration=duration
        }
    else
        surface.create_entity{name=cloud, position=target.position, force="neutral"}
    end
end

-- Create a projectile from source to target
-- @param name: the name of the projecticle
-- @param surface: the surface to create the projectile on
-- @param force: the force this projectile belongs too
-- @param source: position table to start at
-- @param target: position table to end at
local function create_projectile(name, surface, force, source, target, speed)
    speed = speed or 1
    force = force or "player"
    surface.create_entity{name=name, force=force, position=source, target=target, speed=speed}
end

-------------------------------------------------------------------------------
--[[Nano Emitter Queue Handler]]--
-------------------------------------------------------------------------------
--Queued items are handled one at a time,
--check validity of all stored objects at this point, They could have become
--invalidated between the time the where entered into the queue and now.

local queue = {}

--Handles all of the deconstruction and scrapper related tasks.
function queue.deconstruction(data)
    local entity, player = data.entity, game.players[data.player_index]
    if player and player.valid then
        if entity and entity.valid then
            local item_stacks, this_product = {}, {}

            --Get all items inside of the entity.
            if entity.has_items_inside() then
                item_stacks = get_all_items_inside(entity, item_stacks)
            end

            --Loop through the minable products and add the item(s) to the list
            local products
            if (entity.name ~= "deconstructible-tile-proxy"
                and entity.prototype.mineable_properties and entity.prototype.mineable_properties.minable) then
                products = entity.prototype.mineable_properties.products
            elseif entity.name == "deconstructible-tile-proxy" then
                local tile = entity.surface.get_tile(entity.position)
                if tile.prototype.mineable_properties and tile.prototype.mineable_properties.minable then
                    products = tile.prototype.mineable_properties.products
                else
                    --Can't mine the tile so destroy the proxy.
                    entity.destroy()
                    return
                end
            end

            if products then
                for _, item in pairs(products) do
                    local max_health = entity.health and entity.prototype.max_health
                    local health = 1
                    if entity.force == player.force then
                        health = (entity.health and entity.health/max_health) or 1
                    end
                    item_stacks[#item_stacks+1] = {name=item.name, count=item.amount or random(item.amount_min, item.amount_max), health=health}
                end
                this_product = item_stacks[#item_stacks]
            end

            --Get all of the items on ground.
            if entity.type == "item-entity" then
                item_stacks[#item_stacks+1] = {name=entity.stack.name, count=entity.stack.count, health=entity.stack.health or 1}
                if not this_product.name then this_product = item_stacks[#item_stacks] end
            end

            create_projectile("nano-projectile-deconstructors", entity.surface, entity.force, player.position, entity.position)
            --Start inserting items!
            if #item_stacks > 0 then
                insert_or_spill_items(player, item_stacks)
                create_projectile("nano-projectile-return", entity.surface, entity.force, entity.position, player.position)
            end

            --This shouldn't be needed but it won't hurt.
            if not this_product.name then
                this_product = {name=(entity.type == "item-entity" and entity.stack.name) or entity.name, count=1}
            end

            if entity.name ~= "deconstructible-tile-proxy" then -- Destroy Entities
                game.raise_event(defines.events.on_preplayer_mined_item, {player_index=player.index, entity=entity})
                game.raise_event(defines.events.on_player_mined_item, {player_index=player.index, item_stack=this_product})
                entity.destroy()
            else -- Destroy tiles
                local surface, position = entity.surface, entity.position
                game.raise_event(defines.events.on_preplayer_mined_item, {player_index=player.index, entity=entity})
                entity.destroy()
                surface.set_tiles({{name=surface.get_hidden_tile(position), position=position}})
                game.raise_event(defines.events.on_player_mined_item, {player_index=player.index, item_stack=this_product})
                game.raise_event(defines.events.on_player_mined_tile, {player_index=player.index, positions={position}})
            end
        end--Valid entity
    end--Valid player
end

function queue.build_entity_ghost(data)
    local ghost, player, ghost_surf, ghost_pos = data.entity, game.players[data.player_index], data.surface, data.position
    if (player and player.valid) then
        if ghost.valid then
            local item_stacks = get_all_items_on_ground(ghost)
            if player.surface.can_place_entity{name=ghost.ghost_name, position=ghost.position,direction=ghost.direction,force=ghost.force} then
                local module_stacks
                local old_item_requests = table.deepcopy(ghost.item_requests)
                ghost.item_requests, module_stacks = get_insertable_module_requests(player, ghost)

                local revived, entity = ghost.revive()
                if revived then
                    create_projectile("nano-projectile-constructors", entity.surface, entity.force, player.position, entity.position)
                    entity.health = (entity.health > 0) and ((data.place_item.health or 1) * entity.prototype.max_health)
                    --item_stacks = insert_into_entity(entity, item_stacks)
                    if insert_or_spill_items(player, insert_into_entity(entity, item_stacks)) then
                        create_projectile("nano-projectile-return", ghost_surf, player.force, ghost_pos, player.position)
                    end
                    local module_inventory = entity.get_module_inventory()
                    if module_inventory and module_stacks then
                        for _,v in pairs(module_stacks) do
                            module_inventory.insert(v)
                        end
                    end
                    game.raise_event(defines.events.on_built_entity, {player_index=player.index, created_entity=entity, revived=true})
                else --not revived, return item
                    if module_stacks then
                        insert_or_spill_items(player, module_stacks)
                        if ghost.valid then
                            ghost.item_requests = old_item_requests
                        end
                    end
                    insert_or_spill_items(player, {data.place_item})
                end --revived
            else --can't build
                insert_or_spill_items(player, {data.place_item})
            end --can build
        else --invalid player
            insert_or_spill_items(player, {data.place_item})
        end --valid ghost
    end --valid player
end

function queue.build_tile_ghost(data)
    local ghost, surface, position, player = data.entity, data.surface, data.position, game.players[data.player_index]
    if (player and player.valid) then
        if ghost.valid then
            local tile = surface.get_tile(position)
            if not tile.hidden_tile or not (tile.hidden_tile and tile.prototype.can_be_part_of_blueprint) then
                create_projectile("nano-projectile-constructors", surface, ghost.force, player.position, ghost.position)
                surface.create_entity{name="nano-sound-build-tiles",position=position}
                surface.set_tiles({{name=ghost.ghost_name, position=position}})
                game.raise_event(defines.events.on_player_built_tile, {player_index=player.index, positions={position}})
            else --Can't place entity
                insert_or_spill_items(player, {data.place_item})
            end
        else --Give the item back ghost isn't valid anymore.
            insert_or_spill_items(player, {data.place_item})
        end --valid ghost
    end --valid player
end

-------------------------------------------------------------------------------
--[[Nano Emmitter]]--
-------------------------------------------------------------------------------
--Extension of the tick handler, This functions decide what to do with their
--assigned robots and insert them intot the queue accordingly.

--Nano Constructors
--queue the ghosts in range for building, heal stuff needing healed
local function queue_ghosts_in_range(player, pos, nano_ammo)
    local queued = global.forces[player.force].queued
    local radius = bot_radius[player.force.get_ammo_damage_modifier(nano_ammo.prototype.ammo_type.category)] or 7.5
    local area = Position.expand_to_area(pos, radius)
    for _, ghost in pairs(player.surface.find_entities(area)) do
        if nano_ammo.valid and nano_ammo.valid_for_read then
            if (global.config.no_network_limits or nano_network_check(player, ghost)) then
                if (ghost.to_be_deconstructed(player.force) and ghost.minable and not table_find(global.queued, _find_entity_match, ghost)) then
                    ammo_drain(player, nano_ammo)
                    data = {player_index=player.index, action="deconstruction", deconstructors=true, entity=ghost}
                    List.push_right(queued, data)
                elseif (ghost.name == "entity-ghost" or ghost.name == "tile-ghost") and ghost.force == player.force then
                    --get first available item that places entity from inventory that is not in our hand.
                    local _, item_name = table_find(ghost.ghost_prototype.items_to_place_this, _find_item, player)
                    if item_name and not table_find(global.queued, _find_entity_match, ghost) then
                        local place_item = get_one_item_from_inv(player, item_name, get_cheat_mode(player))
                        local data = {action = "build_entity_ghost", player_index=player.index, entity=ghost, surface=ghost.surface, position=ghost.position}
                        if ghost.name == "entity-ghost" and place_item then
                            if player.surface.can_place_entity{name=ghost.ghost_name, position=ghost.position,direction=ghost.direction,force=ghost.force} then
                                data.place_item = place_item
                                List.push_right(queued, data)
                                ammo_drain(player, nano_ammo)
                            end
                        elseif ghost.name == "tile-ghost" then
                            if ghost.surface.count_entities_filtered{name="entity-ghost", position=ghost.position, limit=1} == 0 and place_item then
                                data.place_item = place_item
                                data.action="build_tile_ghost"
                                List.push_right(queued, data)
                                ammo_drain(player, nano_ammo)
                            end
                        end
                    end
                    -- Check if entity needs repair
                elseif nano_repairable_entity(ghost) and ghost.force == player.force then
                    local ghost_area = Area.offset(ghost.prototype.collision_box, ghost.position)
                    if ghost.surface.count_entities_filtered{name="nano-cloud-small-repair", area=ghost_area} == 0 then
                        ghost.surface.create_entity{
                            name="nano-projectile-repair",
                            position=player.position,
                            force=player.force,
                            target=ghost.position,
                            speed=0.5,
                        }
                        ghost.surface.create_entity{
                            name="nano-sound-repair",
                            position=ghost.position,
                        }
                        ammo_drain(player, nano_ammo)
                    end --repair
                end --deconstruct, ghost or heal
            end --network check
        else --not valid ammo
            break --we ran out of ammo break out! -- Possible to check on ammo changed before this and re-insert the ammo?
        end --valid ammo
    end --looping through entities
end

--Nano Termites
--Kill the trees! Kill them dead
local function everyone_hates_trees(player, pos, nano_ammo)
    local radius = termite_radius[player.force.get_ammo_damage_modifier(nano_ammo.prototype.ammo_type.category)] or 7.5
    local area = Position.expand_to_area(pos, radius)
    for _, stupid_tree in pairs(player.surface.find_entities_filtered{area=area, type="tree"}) do
        if nano_ammo.valid and nano_ammo.valid_for_read then
            local tree_area = Area.expand(Area.offset(stupid_tree.prototype.collision_box, stupid_tree.position), .5)
            if player.surface.count_entities_filtered{area=tree_area, name="nano-cloud-small-termites"} == 0 then
                player.surface.create_entity{
                    name="nano-projectile-termites",
                    position=player.position,
                    force=player.force,
                    target=stupid_tree,
                    speed= .5,
                }
                player.surface.create_entity{
                    name="nano-sound-termite",
                    position=stupid_tree.position,
                }
                --nano_ammo.drain_ammo(1)
                ammo_drain(player, nano_ammo)
            end
        else
            break
        end
    end
end

-------------------------------------------------------------------------------
--[[BOT CHIPS]]--
-------------------------------------------------------------------------------
--At this point player is valid, not afk and has a character

--Mark items for deconstruction if player has roboport
local function gobble_items(player, equipment)
    local rad = player.character.logistic_cell.construction_radius
    local area = Position.expand_to_area(player.position, rad)
    if not player.surface.find_nearest_enemy{position=player.position, max_distance=rad+20, force=player.force} then
        if equipment["equipment-bot-chip-items"] then

            local items = player.surface.find_entities_filtered{area=area, name="item-on-ground"}
            local num_items = #items
            local num_item_chips = #equipment["equipment-bot-chip-items"]

            while num_items > 0 and num_item_chips > 0 do
                local chip = equipment["equipment-bot-chip-items"][num_item_chips]
                while num_items > 0 and chip and chip.energy > 100 do
                    local item = items[num_items]
                    if item and not item.to_be_deconstructed(player.force) then
                        item.order_deconstruction(player.force)
                        chip.energy = chip.energy - 100
                    end
                    num_items = num_items - 1
                end
                num_item_chips = num_item_chips - 1
            end
        end
        if equipment["equipment-bot-chip-trees"] then

            local items = player.surface.find_entities_filtered{area=area, type="tree"}
            local num_items = #items
            local num_item_chips = #equipment["equipment-bot-chip-trees"]

            while num_items > 0 and num_item_chips > 0 do
                local chip = equipment["equipment-bot-chip-trees"][num_item_chips]
                while num_items > 0 and chip and chip.energy > 25 do
                    local item = items[num_items]
                    if item and not item.to_be_deconstructed(player.force) then
                        item.order_deconstruction(player.force)
                        chip.energy = chip.energy - 25
                    end
                    num_items = num_items - 1
                end
                num_item_chips = num_item_chips - 1
            end
        end
    end
end

local function get_best_follower_capsule(player)
    for capsule, robot in pairs(combat_robots) do
        local count = player.get_item_count(capsule)
        if count > 0 then return capsule, count, robot end
    end
end

local function launch_units(player, launchers)
    local rad = player.character.logistic_cell.construction_radius
    local num_launchers = #launchers
    local capsule, count, robot = get_best_follower_capsule(player)
    if capsule and player.surface.find_nearest_enemy{position=player.position, max_distance=rad, force=player.force} then
        local max_bots = player.force.maximum_following_robot_count + player.character_maximum_following_robot_count_bonus
        local range = Position.expand_to_area(player.position, rad)
        local existing = player.surface.count_entities_filtered{area=range, type="combat-robot", force=player.force}
        if existing < (max_bots - (num_launchers * 5)) then
            for i = 1, min(num_launchers, count) do
                local launcher = launchers[i]
                if launcher.energy >= 500 then
                    local removed = player.remove_item({name=capsule, count=1})
                    if removed then
                        player.surface.create_entity{name=robot, position=player.position, force = player.force, target=player.character}
                        launcher.energy = launcher.energy - 500
                    end
                end
            end
        end
    end
end

local function get_health_capsules(player)
    for name, health in pairs(healer_capsules) do
        if game.item_prototypes[name] and player.remove_item({name=name, count = 1}) > 0 then
            return max(health, 10), game.item_prototypes[name].localised_name or {"nanobots.free-food-unknown"}
        end
    end
    return 10, {"nanobots.free-food"}
end

local function emergency_heal(player, feeder)
    local count = #feeder
    local pos = increment_position(player.character.position)
    while (player.character.health < (player.character.prototype.max_health * .75)) and count > 0 do
        if feeder[count].energy >= 480 then
            local last_health = player.character.health
            local heal, locale = get_health_capsules(player)
            player.character.health = last_health + heal
            --local health_line = "+"..ceil(abs(player.character.health - last_health)).."hp from "..locale
            local health_line = {"nanobots.health_line", ceil(abs(player.character.health - last_health)), locale}
            feeder[count].energy = 0
            player.surface.create_entity{name="flying-text", text = health_line, color = defines.colors.green, position = pos()}
        end
        count = count - 1
    end
end

local function prepare_chips(player)
    if are_bots_ready(player.character) then
        local equipment = get_valid_equipment(player)
        if equipment["equipment-bot-chip-items"] or equipment["equipment-bot-chip-trees"] then
            gobble_items(player, equipment)
        end
        if equipment["equipment-bot-chip-launcher"] then
            launch_units(player, equipment["equipment-bot-chip-launcher"])
        end
        if equipment["equipment-bot-chip-feeder"] then
            emergency_heal(player, equipment["equipment-bot-chip-feeder"])
        end
    end
end

-------------------------------------------------------------------------------
--[[EVENTS]]--
-------------------------------------------------------------------------------
--The Tick Handler!
--Future improvments: 1 player per tick, move gun/ammo/equip checks to event handlers.

local function on_tick(event)
    local config = global.config
    --Handle building from the queue every x ticks.
    for _, force_name in ipairs(global.force_list) do
        local force, fdata = Force.get_object_and_data(force_name)
        local tick_modifier = max(1, config.ticks_per_queue - queue_speed[force.get_gun_speed_modifier("nano-ammo")])
        if event.tick % tick_modifier == 0 and List.count(fdata.queued) > 0 then
            local data = List.pop_left(fdata.queued)
            queue[data.action](data)
        end
    end
    if config.run_ticks and event.tick % config.tick_mod == 0 then
        for _, player in pairs(game.connected_players) do
            --Establish connected, non afk, player character
            if is_connected_player_ready(player) then
                if config.auto_nanobots and (config.no_network_limits or nano_network_check(player)) then
                    local gun, nano_ammo, ammo_name = get_gun_ammo_name(player, "gun-nano-emitter")
                    if gun then
                        if ammo_name == "ammo-nano-constructors" then
                            queue_ghosts_in_range(player, player.position, nano_ammo)
                        elseif ammo_name == "ammo-nano-termites" then
                            everyone_hates_trees(player, player.position, nano_ammo)
                        end
                    end --Gun and Ammo check
                end
                if config.auto_equipment then
                    prepare_chips(player)
                end --Auto Equipment
            end --Player Ready
        end --For Players
    end --NANO Automatic scripts
end
Event.register(defines.events.on_tick, on_tick)

Event.register(defines.events.on_player_created, Player.on_player_created)
Event.register(defines.events.on_force_created, function(event) Force.init(event.force.name) end)

-------------------------------------------------------------------------------
--[[INIT]]--
-------------------------------------------------------------------------------
local changes = require("changes")
Event.register(Event.core_events.configuration_changed, changes.on_configuration_changed)

function MOD.on_init()
    global = {}
    global._changes = changes.on_init(game.active_mods[MOD.name] or MOD.version)
    global.forces = Force.init()
    global.players = Player.init()
    global.current_index = 1
    global.config = table.deepcopy(MOD.config.control)
    changes.on_init(game.active_mods[MOD.name])
    game.print(MOD.name..": Init Complete")
end
Event.register(Event.core_events.init, MOD.on_init)

local interface = require("interface")
remote.add_interface(MOD.interface, interface)
