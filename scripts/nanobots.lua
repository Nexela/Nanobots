local Table = require("__stdlib__/stdlib/utils/table")
local Config = require("config")
local Queue = require("scripts/hash-queue")
local prepare_chips = require("scripts/armor-mods")
local max, table_size, table_find = math.max, table_size, Table.find
local queue --- @type Nanobots.queue

local BOT_RADIUS = Config.BOT_RADIUS
local QUEUE_SPEED = Config.QUEUE_SPEED_BONUS
local NANO_EMITTER = Config.NANO_EMITTER
local AMMO_CONSTRUCTORS = Config.AMMO_CONSTRUCTORS
local AMMO_TERMITES = Config.AMMO_TERMITES
local moveable_types = Config.MOVEABLE_TYPES
local blockable_types = Config.BLOCKABLE_TYPES
local explosives = Config.EXPLOSIVES
local main_inventories = Config.MAIN_INVENTORIES

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
    if prototype.type ~= "item-with-inventory" then
        if player.cheat_mode or player.get_item_count(item) >= count then
            return true
        else
            local vehicle = player.vehicle
            local train = vehicle and vehicle.train
            return vehicle and ((vehicle.get_item_count(item) >= count) or (train and train.get_item_count(item) >= count)) or false
        end
    end
    return false
end

--- Is the player ready?
--- @param player LuaPlayer
--- @return boolean
local function is_ready(player)
    return Config.afk_time == 0 or player.afk_time <= (Config.afk_time * 60)
end

--- Is this equipment powered?
--- @param character LuaEntity
--- @param eq_name string
--- @return boolean
local function is_equipment_powered(character, eq_name)
    local grid = character.grid
    if grid and grid.get_contents()[eq_name] then
        ---@param v LuaEquipment
        return table_find(grid.equipment, function(v)
            return v.name == eq_name and v.energy > 0
        end) --[[@as boolean]]
    end
    return false
end

--- Is the target not in a construction network with robots?
--- @param character LuaEntity
--- @param target? LuaEntity
--- @return boolean
local function is_outside_network(character, target)
    if is_equipment_powered(character, "equipment-bot-chip-nanointerface") then
        return true
    else
        target = target or character
        local networks = target.surface.find_logistic_networks_by_construction_area(target.position, target.force)
        local has_network_bots = Table.any(networks, function(network)
            return network.all_construction_robots > 0
        end)
        return not has_network_bots
    end
end

--- Can nanobots repair this entity?
--- @param entity LuaEntity
--- @return boolean
local function is_nanobot_repairable(entity)
    if entity.has_flag("not-repairable") or entity.type:find("robot") then return false end
    if blockable_types[entity.type] and entity.minable == false then return false end
    if (entity.get_health_ratio() or 1) >= 1 then return false end
    if moveable_types[entity.type] and entity.speed > 0 then return false end
    return table_size(entity.prototype.collision_mask) > 0
end

--- Get both the gun and ammo that matches gun_name.
--- @param player LuaPlayer
--- @param gun_name string
--- @return LuaItemStack?
--- @return LuaItemStack?
local function get_gun_ammo_name(player, gun_name)
    local gun_inv = player.get_inventory(defines.inventory.character_guns) --[[@as LuaInventory]]
    local ammo_inv = player.get_inventory(defines.inventory.character_ammo) --[[@as LuaInventory]]

    local gun, ammo

    if not player.mod_settings["nanobots-active-emitter-mode"].value then
        local index
        gun, index = gun_inv.find_item_stack(gun_name)
        ammo = gun and ammo_inv[index]
    else
        local index = player.character.selected_gun_index
        gun, ammo = gun_inv[index], ammo_inv[index]
    end

    if gun and gun.valid_for_read and ammo and ammo.valid_for_read then return gun, ammo end
    return nil, nil
end

--- Get an item with health data from the inventory
--- @param entity LuaEntity|LuaPlayer the entity object to search
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
            sources[#sources + 1] = entity --[[@as LuaEntity]]
        elseif entity.vehicle then
            sources = { entity.vehicle, entity }
        else
            sources = { entity }
        end

        local new_item_stack = { name = item_stack.name, count = 0, health = 1.0 } --- @type ItemStackDefinition

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
--- @param amount? float
--- @return boolean #Ammo was fully drained
local function drain_ammo(player, ammo, amount)
    if player.cheat_mode then return true end

    amount = amount or 1.0
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
    return false
end

--- Get the radius to use based on tehnology and player defined radius
--- @param pdata Nanobots.pdata
--- @param force LuaForce
--- @param nano_ammo LuaItemStack
local function get_ammo_radius(pdata, force, nano_ammo)
    local max_radius = BOT_RADIUS[force.get_ammo_damage_modifier(nano_ammo.prototype.get_ammo_type().category)] or 7
    local custom_radius = pdata.ranges[nano_ammo.name] or max_radius
    return custom_radius <= max_radius and custom_radius or max_radius
end

--[[ Nano Emmitter --]]
-- Extension of the tick handler, This functions decide what to do with their
-- assigned robots and insert them into the queue accordingly.

--- Nano Constructors
--- Queue the ghosts in range for building, heal stuff needing healed
--- @param player LuaPlayer
--- @param pos MapPosition
--- @param ammo LuaItemStack
--- @param tick uint
local function queue_ghosts_in_range(player, pos, ammo, tick)
    local pdata = global.players[player.index]
    pdata.next_nano_tick = pdata.next_nano_tick > tick and pdata.next_nano_tick or tick
    if pdata.next_nano_tick > (tick + 1800) then return end

    local player_force = player.force --[[@as LuaForce]]
    local surface = player.surface
    local tick_spacing = max(1, Config.ticks_between_actions - (QUEUE_SPEED[player_force.get_gun_speed_modifier("nano-ammo")] or QUEUE_SPEED[4]))
    local actions_per_group = Config.actions_per_group
    local get_next_tick = queue:get_counters(pdata.next_nano_tick, tick_spacing, actions_per_group)

    -- local area = Position.expand_to_area(pos, get_ammo_radius(pdata, player_force, ammo))
    local radius = get_ammo_radius(pdata, player_force, ammo)
    local cheat_mode = player.cheat_mode

    for _, ghost in pairs(player.surface.find_entities_filtered { position = pos, radius = radius }) do
        --- Check constraints for contiuned iteration
        local this_tick, queued_this_cycle = get_next_tick(false, true)
        pdata.next_nano_tick = this_tick
        if not ammo.valid_for_read then return end
        if queued_this_cycle >= Config.entities_per_cycle then return end

        --- Check constraints on this iteration.
        local ghost_force = ghost.force --[[@as LuaForce]]
        local friendly_force = ghost_force.is_friend(player_force)
        if not friendly_force then goto next_ghost end
        if queue:get_hash(ghost) then goto next_ghost end
        if Config.network_limits and not is_outside_network(player.character, ghost) then goto next_ghost end

        local deconstruct = friendly_force and ghost.to_be_deconstructed()
        local upgrade = friendly_force and ghost.to_be_upgraded()

        --- @class Nanobots.action_data
        --- @field on_tick uint
        --- @field tick_index uint
        --- @field hash_id uint|string
        local data = {
            player_index = player.index, ---@type uint
            player = player, ---@type LuaPlayer
            ammo = ammo, ---@type LuaItemStack
            entity = ghost, ---@type LuaEntity
            position = ghost.position, ---@type MapPosition
            surface = surface, ---@type LuaSurface
            unit_number = ghost.unit_number, ---@type uint
            force = ghost_force ---@type LuaForce
        }

        if deconstruct then
            if ghost.type == "cliff" then
                if player_force.technologies["nanobots-cliff"].researched then
                    local item_name = table_find(explosives, _find_item, player)
                    if item_name then
                        local explosive = get_items_from_inv(player, item_name, cheat_mode)
                        if explosive then
                            data.item_stack = explosive
                            data.action = "cliff_deconstruction"
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1.0)
                        end
                    end
                end
            elseif ghost.minable then
                data.action = "deconstruction"
                queue:insert(data, get_next_tick())
                drain_ammo(player, ammo, 1.0)
            end
        elseif upgrade then
            local prototype = ghost.get_upgrade_target()
            if prototype then
                if prototype.name == ghost.name then
                    local dir = ghost.get_upgrade_direction()
                    if ghost.direction ~= dir then
                        data.action = "upgrade_direction"
                        data.direction = dir
                        queue:insert(data, get_next_tick())
                        drain_ammo(player, ammo, 1.0)
                    end
                else
                    local item_stack = table_find(prototype.items_to_place_this, _find_item, player)
                    if item_stack then
                        data.action = "upgrade_ghost"
                        local place_item = get_items_from_inv(player, item_stack, player.cheat_mode)
                        if place_item then
                            data.entity_name = prototype.name
                            data.item_stack = place_item
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1.0)
                        end
                    end
                end
            end
        elseif ghost.name == "entity-ghost" or (ghost.name == "tile-ghost" and Config.build_tiles) then
            -- get first available item that places entity from inventory that is not in our hand.
            local prototype = ghost.ghost_prototype
            local item_stack = table_find(prototype.items_to_place_this, _find_item, player)
            if item_stack then
                if ghost.name == "entity-ghost" then
                    local place_item = get_items_from_inv(player, item_stack, cheat_mode)
                    if place_item then
                        data.action = "build_entity_ghost"
                        data.item_stack = place_item
                        queue:insert(data, get_next_tick())
                        drain_ammo(player, ammo, 1.0)
                    end
                elseif ghost.name == "tile-ghost" then
                    -- Don't queue tile ghosts if entity ghost is on top of it.
                    if surface.count_entities_filtered { name = "entity-ghost", area = ghost.selection_box, limit = 1 } == 0 then
                        local tile = surface.get_tile(ghost.position--[[@as TilePosition]] )
                        local place_item = get_items_from_inv(player, item_stack, cheat_mode)
                        if place_item then
                            data.action = "build_tile_ghost"
                            data.tile = tile
                            data.item_stack = place_item
                            queue:insert(data, get_next_tick())
                            drain_ammo(player, ammo, 1.0)
                        end
                    end
                end
            end
        elseif is_nanobot_repairable(ghost) then
            if surface.count_entities_filtered { name = "nano-cloud-small-repair", position = data.position } == 0 then
                data.action = "repair_entity"
                queue:insert(data, get_next_tick())
                drain_ammo(player, ammo, 1.0)
            end
        elseif ghost.name == "item-request-proxy" and Config.do_proxies then
            local items = {}
            for item, count in pairs(ghost.item_requests) do items[#items + 1] = { name = item, count = count } end
            local item_stack = table_find(items, _find_item, player, true)
            if item_stack then
                local place_item = get_items_from_inv(player, item_stack, cheat_mode, true)
                if place_item then
                    data.action = "item_requests"
                    data.item_stack = place_item
                    queue:insert(data, get_next_tick())
                    drain_ammo(player, ammo, 1.0)
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
    local force = player.force --[[@as LuaForce]]
    local surface = player.surface
    local radius = get_ammo_radius(global.players[player.index], force, ammo)
    for _, stupid_tree in pairs(surface.find_entities_filtered { position = pos, radius = radius, type = "tree", limit = 200 }) do
        if not ammo.valid_for_read then return end
        if not stupid_tree.to_be_deconstructed then
            -- local tree_area = Area.expand(stupid_tree.bounding_box, .5)
            if surface.count_entities_filtered { position = stupid_tree.position, radius = 0.5, name = "nano-cloud-small-termites" } == 0 then
                surface.create_entity {
                    name = "nano-projectile-termites",
                    source = player --[[@as LuaEntity]] ,
                    position = player.position,
                    force = force,
                    target = stupid_tree,
                    speed = .5
                }
                drain_ammo(player, ammo, 1.0)
            end
        end
    end
end

do
    local Events = {}
    --- The tick handler
    --- @param event on_tick
    function Events.on_nth_tick(event)
        -- Default rate is 1 player ever 60 ticks, 2 players is 1 every 30 ticks.
        local tick = event.tick
        local connected_players = game.connected_players
        -- if tick % max(1, floor(Config.poll_rate / #connected_players)) == 0 then
        local last_player, player = next(connected_players, global.last_player)
        global.last_player = last_player
        if not (player and is_ready(player)) then return end

        local character = player.character
        if not character then return end

        if Config.equipment_auto then prepare_chips(player) end

        if not Config.nanobots_auto then return end

        if Config.network_limits and not is_outside_network(character) then return end

        local gun, ammo = get_gun_ammo_name(player, NANO_EMITTER)
        if not gun then return end --- @cast ammo -?
        local ammo_name = ammo.name
        if ammo_name == AMMO_CONSTRUCTORS then
            queue_ghosts_in_range(player, player.position, ammo, tick)
        elseif ammo_name == AMMO_TERMITES then
            everyone_hates_trees(player, player.position, ammo)
        end
        -- end
    end

    function Events.on_tick(event)
        queue:execute(event)
    end

    function Events.on_init()
        global.nano_queue = Queue.new()
        queue = global.nano_queue
        game.print("Nanobots are now ready to serve")
    end

    function Events.on_load()
        queue = Queue.new(global.nano_queue)
    end

    function Events.on_players_changed()
        global.last_player = nil
    end

    function Events.reset_nano_queue()
        game.print("Resetting Nano Queue")
        global.nano_queue = Queue.new()
        queue = global.nano_queue
        global.last_player = nil
        for _, player in pairs(global.players) do player.next_nano_tick = game.tick end
    end

    return Events
end
