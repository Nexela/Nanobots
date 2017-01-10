MOD = {}
MOD.interface = "nanobots"
MOD.name = "Nanobots"
MOD.config = require("config")
MOD.logfile = require("stdlib/log/logger")

require("stdlib/config/config")
require("stdlib/event/event")
require("stdlib/utils/utils")
require("stdlib/gui/gui")

local Position = require("stdlib/area/position")
local Area = require("stdlib/area/area")
local List = require("stdlib/utils/list")

if _G.DEBUG then
  log(MOD.name .. " Debug mode enabled")
  MOD.quickstart = require("stdlib/utils/quickstart")
end

-- Is the player connected, not afk, and have an attached character
-- @param player: the player object
-- @return bool: player is connected and ready
local function is_connected_player_ready(player)
  --and player.force.technologies["automated-construction"].researched
  return (player.afk_time < 90 and player.character) or false
end

-- Loop through armor and return a table of valid equipment names and counts
-- @param player: the player object
-- @return table: a table of valid equipment, name as key, count as value .
local function get_valid_equipment_names(player)
  local armor = player.get_inventory(defines.inventory.player_armor)
  local list = {}
  if armor[1].valid_for_read and armor[1].grid and armor[1].grid.equipment then
    for _, equip in pairs(armor[1].grid.equipment) do
      if equip.energy > 0 then list[equip.name]=(list[equip.name] or 0) + 1 end
    end
  end
  return list
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

-- Does the character have a personal robort and construction robots
-- character: the player character
-- @return bool: true or false
local function are_bots_ready(character)
  return (character.logistic_cell and character.logistic_cell.mobile
    and character.logistic_cell.stationed_construction_robot_count > 0) or false
end

-- Attempt to insert an item_stack or array of item_stacks into the player
-- Spill to the ground at player anything that doesn't get inserted
-- @param player: the player object
-- @param item_stacks: a SimpleItemStack or array of SimpleItemStacks to insert
-- @return table : the items stacks inserted or spilled
local function insert_or_spill_items(player, item_stacks)
  local new_stacks = {}
  if item_stacks then
    if item_stacks[1] and item_stacks[1].name then
      new_stacks = item_stacks
    elseif item_stacks and item_stacks.name then
      new_stacks = {item_stacks}
    end
    for _, stack in pairs(new_stacks) do
      local name, count, health = stack.name, stack.count, stack.health or 1
      local inserted = player.insert{name=name, count=count, health=health}
      if inserted ~= count then
        player.surface.spill_item_stack(player.position, {name=name, count=count-inserted, health=health}, true)
      end
    end
    return (new_stacks[1] and item_stacks)
  end
end

-- Remove all items inside an entity and return an array of SimpleItemStacks removed
-- TODO using get_contents it is not possible to get the health. id:9 gh:21
-- @param entity: The entity object to remove items from
-- @return table: a table of SimpleItemStacks or nil if empty
local function get_all_items_inside(entity, existing_stacks)
  local item_stacks = existing_stacks or {}
  for _, inv in pairs(defines.inventory) do
    local inventory = entity.get_inventory(inv)
    if inventory and inventory.valid then
      for name, count in pairs(inventory.get_contents()) do
        local health = 1
        item_stacks[#item_stacks+1] = {name=name, count=count, health=health or 1}
        inventory.remove({name=name, count=count})
      end
    end
  end
  return (item_stacks[1] and item_stacks)
end

-- Scan the ground under an entities collision box for items and insert them into the player.
-- @param entity: the entity object to scan under
-- @return table: a table of SimpleItemStacks or nil if empty
local function get_all_items_on_ground(entity, existing_stacks)
  --local surface, position, collision_mask, items_on_ground = entity.surface, entity.position, entity.ghost_prototype.selection_box, {}
  local item_stacks = existing_stacks or {}
  local surface, position, collision_mask = entity.surface, entity.position, entity.ghost_prototype.selection_box
  for _, item_on_ground in pairs(surface.find_entities_filtered{name="item-on-ground", area=Area.offset(collision_mask, position)}) do
    item_stacks[#item_stacks+1] = {name=item_on_ground.stack.name, count=item_on_ground.stack.count, health=item_on_ground.health or 1}
    item_on_ground.destroy()
  end
  return (item_stacks[1] and item_stacks)
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
local function create_beam_or_cloud(beam, cloud, player, target)
  local connected_char = (player.connected and player.controller_type == defines.controllers.character) and player.character
  local surface = player.surface
  local force = player.force
  local speed = .5
  local duration = 20
  local newtarget
  --Create a proxy target if entity doesn't have health, destroy the proxy target after xx ticks
  if player.can_reach_entity(target) and not (target and (target.health or 0) > 0) then
    newtarget = surface.create_entity{name="nano-target-proxy", position=target.position, force=force}
    global.kill_proxy[game.tick + 20] = newtarget
  else
    newtarget=target
  end
  --if there is a connected char use beam, otherwise just create cloud
  if connected_char then
    surface.create_entity{name=beam, position=connected_char.position, force=force, target=newtarget, source=connected_char, speed=speed, duration=duration}
  else
    surface.create_entity{name=cloud, position=target.position, force=force}
  end
end

-- Create a projectile from source to target
-- @param name: the name of the projecticle
-- @param surface: the surface to create the projectile on
-- @param force: the force this projectile belongs too
-- @param source: position table to start at
-- @param target: position table to end at
local function create_projectile(name, surface, force, source, target)
  local speed = .5
  force = force or "player"
  surface.create_entity{name=name, force=force, position=source, target=target, speed=speed}
end

--table.find functions
local table_find = table.find

-- return the item name if found in inventory and we are not holding it.
local _find_item=function(_, k, p)
  return p.get_item_count(k) > 0 and not (p.cursor_stack.valid_for_read and p.cursor_stack.name == k and p.cursor_stack.count <= p.get_item_count(k))
end

-- return true? if entity exists in table.entity
local _find_match=function(v, _, entity)
  if type(v) == "table" then return v.entity == entity end
end

-------------------------------------------------------------------------------
--[[Nano Emitter Queue Handler]]--
--Queued items are handled one at a time
local queue = {}

--Handles all of the deconstruction related tasks.
function queue.deconstruction(data)
  local entity, player = data.entity, game.players[data.player_index]
  if player and player.valid then
    if data.entity.valid then
      create_beam_or_cloud("nano-beam-deconstructors", "nano-cloud-small-deconstructors", player, entity)
      --Start inserting items!
      insert_or_spill_items(player, data.item_stacks)

      if data.entity.name ~= "deconstructible-tile-proxy" then
        game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=data.entity})
        game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=data.place_item})
        data.entity.destroy()
      else
        local surface = data.entity.surface
        local position = data.entity.position
        game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=data.entity})
        data.entity.destroy()
        surface.set_tiles({{position=position, name = surface.get_hidden_tile(position)}})

        game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=data.place_item})
        game.raise_event(defines.events.on_robot_mined_tile, {robot=player, positions={position}})

      end
    end
  end
end

--Handles all of the scrap (destroy without returning items) related tasks
function queue.scrap(data)
  local entity, player = data.entity, game.players[data.player_index]
  if player and player.valid then
    if entity.valid then
      --entity.surface.create_entity{name="nano-cloud-small-scrappers", position=entity.position, force="neutral"}
      create_beam_or_cloud("nano-beam-scrappers", "nano-cloud-small-scrappers", player, entity)
      if entity.name ~= "deconstructible-tile-proxy" then
        game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=entity})
        entity.destroy()
        game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=nil})
      else --tile proxy
        local surface, position = entity.surface, entity.position
        game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=entity})
        entity.destroy()
        surface.set_tiles({{position=position, name=surface.get_hidden_tile(position)}})
        game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=nil})
        game.raise_event(defines.events.on_robot_mined_tile, {robot=player, positions={position}})
      end
    end
  end
end

function queue.build_entity_ghost(data)
  local ghost, player, ghost_surf, ghost_pos = data.entity, game.players[data.player_index], data.surface, data.position
  if (player and player.valid) then
    if ghost.valid then
      if insert_or_spill_items(player, get_all_items_on_ground(ghost)) then
        create_projectile("nano-projectile-constructors", ghost_surf, player.force, ghost_pos, player.position)
      end

      if player.surface.can_place_entity{name=ghost.ghost_name, position=ghost.position,direction=ghost.direction,force=ghost.force} then
        local module_stacks
        local old_item_requests = table.deepcopy(ghost.item_requests)
        ghost.item_requests, module_stacks = get_insertable_module_requests(player, ghost)

        local revived, entity = ghost.revive()
        if revived then
          create_beam_or_cloud("nano-beam-constructors", "nano-cloud-small-constructors", player, entity)
          local module_inventory = entity.get_module_inventory()
          if module_inventory and module_stacks then
            for _,v in pairs(module_stacks) do
              module_inventory.insert(v)
            end
          end
          game.raise_event(defines.events.on_robot_built_entity, {robot=player, created_entity=entity})
        else --Not revived, return item
          if module_stacks then
            insert_or_spill_items(player, module_stacks)
            if ghost.valid then
              ghost.item_requests = old_item_requests
            end
          end
          insert_or_spill_items(player, {data.place_item})
        end
      else --Can't place entity
        insert_or_spill_items(player, {data.place_item})
      end
    else --Give the item back ghost isn't valid anymore.
      insert_or_spill_items(player, {data.place_item})
    end
  end --valid player
end

function queue.build_tile_ghost(data)
  local ghost, surface, position, player = data.entity, data.surface, data.position, game.players[data.player_index]
  if (player and player.valid) then
    if ghost.valid then
      --logic behind surface.get_hidden_tile is broken, possible related to more_floors mod
      --if not surface.get_hidden_tile(position) then
      create_beam_or_cloud("nano-beam-constructors", "nano-cloud-small-constructors", player, ghost)
      surface.set_tiles({{name=ghost.ghost_name, position=position}})
      game.raise_event(defines.events.on_robot_built_tile, {robot=player, positions={position}})
      -- else --Can't place entity
      -- insert_or_spill_items(player, {{name=data.place_item, count=1}})
      -- end
    else --Give the item back ghost isn't valid anymore.
      insert_or_spill_items(player, {{name=data.place_item, count=1}})
    end
  end --valid player
end

-------------------------------------------------------------------------------
--[[Nano Emitter - Functions]]--

--Build the ghosts in the range of the player
local function queue_ghosts_in_range(player, pos, nano_ammo)
  local area = Position.expand_to_area(pos, MOD.config.BUILD_RADIUS)
  local inserters = {}
  --local tiles = {}
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, force=player.force}) do
    if nano_ammo.valid and nano_ammo.valid_for_read then
      if (global.config.no_network_limits or not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force)) then
        if (ghost.name == "entity-ghost" or ghost.name == "tile-ghost") then
          --Get first available item that places entity from inventory that is not in our hand.
          local _, item = table_find(ghost.ghost_prototype.items_to_place_this, _find_item, player)
          if item and not table_find(global.queued, _find_match, ghost) then
            item = {name=item, count=1, health=1}
            local data = {action = "build_entity_ghost", player_index=player.index, entity=ghost, place_item=item, surface=ghost.surface, position=ghost.position}
            if ghost.ghost_type=="inserter" and player.remove_item(item) == 1 then -- Add inserters to the end of the build queue.
              inserters[#inserters+1] = data
              nano_ammo.drain_ammo(1)
            elseif ghost.name == "entity-ghost" and player.remove_item(item) == 1 then
              List.push_right(global.queued, data)
              nano_ammo.drain_ammo(1)
            elseif ghost.name == "tile-ghost" then
              if ghost.surface.count_entities_filtered{name="entity-ghost", position=ghost.position, limit=1} == 0 and player.remove_item(item) == 1 then
                data.action="build_tile_ghost"
                List.push_right(global.queued, data)
                nano_ammo.drain_ammo(1)
              end
            end
          end
          -- Check if entity needs repair (robots don't correctly heal so they are excluded.)
        elseif ghost.health and ghost.health > 0 and ghost.health < ghost.prototype.max_health and not ghost.type:find("robot") then
          if ghost.surface.count_entities_filtered{name="nano-cloud-small-repair", area=Position.expand_to_area(ghost.position, .75)} == 0 then
            ghost.surface.create_entity{name="nano-beam-healers", position=player.position, force=player.force, target=ghost, source=player.character, speed= .5, duration=20}
            nano_ammo.drain_ammo(1)
          end -- END ghost or repair
        end
      end --END network check
    else --ELSE not valid ammo
      break --We ran out of ammo break out!
    end --END valid ammo
  end --END looping through entities
  --Insert the inserters at the end of the queue, probably not needed anymore
  for _, data in ipairs(inserters) do
    List.push_right(global.queued, data)
  end
end

--Kill the trees! Kill them dead
local function everyone_hates_trees(player, pos, nano_ammo)
  local area = Position.expand_to_area(pos, MOD.config.TERMITE_RADIUS)
  for _, stupid_tree in pairs(player.surface.find_entities_filtered{area=area, type="tree"}) do
    if nano_ammo.valid and nano_ammo.valid_for_read then
      local tree_area = Position.expand_to_area(stupid_tree.position, .5)
      if player.surface.count_entities_filtered{area=tree_area, name="nano-cloud-small-termites"} == 0 then
        player.surface.create_entity{name="nano-beam-termites", position=player.position, force=player.force, target=stupid_tree, source=player.character, speed= .5, duration=20}
        --player.surface.create_entity{name="nano-cloud-small-termites", position=stupid_tree.position, force=player.force}
        nano_ammo.drain_ammo(1)
      end
    else
      break
    end
  end
end

--Nano Scrappers and deconstructors
local function destroy_marked_items(player, pos, nano_ammo, deconstructors)
  local area = Position.expand_to_area(pos, MOD.config.BUILD_RADIUS)
  for _, entity in pairs(player.surface.find_entities(area)) do
    if entity.to_be_deconstructed(player.force) and (nano_ammo.valid and nano_ammo.valid_for_read) and not table_find(global.queued, _find_match, entity) then
      if deconstructors then
        local item_stacks = {}
        --entity.surface.create_entity{name="nano-cloud-small-deconstructors", position=entity.position, force="neutral"}
        nano_ammo.drain_ammo(1)

        --Get all items inside of the entity.
        if entity.has_items_inside() then
          item_stacks = get_all_items_inside(entity, item_stacks)
        end

        --Loop through the minable products and add the item(s) to the list
        local products, this_product
        if entity.prototype.mineable_properties and entity.prototype.mineable_properties.minable then
          products = entity.prototype.mineable_properties.products
        elseif entity.name == "deconstructible-tile-proxy" then
          local tile = entity.surface.get_tile(entity.position)
          if tile.prototype.mineable_properties and tile.prototype.mineable_properties.minable then
            products = tile.prototype.mineable_properties.products
          end
        end
        if products then
          this_product = #item_stacks + 1
          for _, item in pairs(products) do
            local max = entity.health and entity.prototype.max_health
            local health = (entity.health and entity.health/max) or 1
            item_stacks[#item_stacks+1] = {name=item.name, count=item.amount or math.random(item.amount_min, item.amount_max), health=health}
          end
          this_product = item_stacks[this_product]
        end

        --Get all of the items on ground.
        if entity.type == "item-entity" then
          item_stacks[#item_stacks+1] = {name=entity.stack.name, count=entity.stack.count, health=entity.stack.health or 1}
        end

        --Queue Data
        local data = {player_index=player.index, action="deconstruction", item_stacks=item_stacks, place_item=this_product, entity=entity}
        List.push_right(global.queued, data)
      elseif not entity.has_flag("breaths-air") then -- Scrappers
        nano_ammo.drain_ammo(1)
        local data = {player_index=player.index, action="scrap", entity=entity}
        List.push_right(global.queued, data)
      end
    end
  end
end

-------------------------------------------------------------------------------
--[[Personal Roboport Stuff]]--
--Mark items for deconstruction if player has roboport
local function gobble_items(player, eq_names)
  local rad = player.character.logistic_cell.construction_radius
  local area = Position.expand_to_area(player.position, rad)
  if not player.surface.find_nearest_enemy{position=player.position ,max_distance=rad+20,force=player.force} then
    if eq_names["equipment-bot-chip-items"] then
      --local range = get_build_area(player.position, eq_names["equipment-bot-chip-items"] * MOD.config.CHIP_RADIUS)
      for _, item in pairs(player.surface.find_entities_filtered{area=area, name="item-on-ground"}) do
        if not item.to_be_deconstructed(player.force) then
          item.order_deconstruction(player.force)
        end
      end
    end
    if eq_names["equipment-bot-chip-trees"] then
      local range = Position.expand_to_area(player.position, math.min(rad + 100, eq_names["equipment-bot-chip-trees"] * MOD.config.CHIP_RADIUS))
      for _, item in pairs(player.surface.find_entities_filtered{area=range, type="tree"}) do
        if not item.to_be_deconstructed(player.force) then
          item.order_deconstruction(player.force)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
--[[Events]]--

--The Tick Handler!
--Future improvments: 1 player per tick, move gun/ammo/equip checks to event handlers.
local function on_tick(event)
  local config = global.config
  --Destroy Proxies
  local proxy = global.kill_proxy[event.tick]
  if proxy and proxy.valid and proxy.destroy() then
    global.kill_proxy[event.tick] = nil
  end

  --Handle building from the queue every x ticks.
  if event.tick % config.ticks_per_queue == 0 and List.count(global.queued) > 0 then
    local data = List.pop_left(global.queued)
    queue[data.action](data)
    --game.print(serpent.block(data, {comment=false}))
  end
  if config.run_ticks and event.tick % config.tick_mod == 0 then

    for _, player in pairs(game.connected_players) do

      --Establish connected, non afk, player character
      if is_connected_player_ready(player) then
        if config.auto_nanobots and (config.no_network_limits or not player.character.logistic_network) then
          local gun, nano_ammo, ammo_name = get_gun_ammo_name(player, "gun-nano-emitter")
          if gun then
            if ammo_name == "ammo-nano-constructors" then
              queue_ghosts_in_range(player, player.position, nano_ammo)
            elseif ammo_name == "ammo-nano-termites" then
              everyone_hates_trees(player, player.position, nano_ammo)
            elseif ammo_name == "ammo-nano-scrappers" then
              destroy_marked_items(player, player.position, nano_ammo, false)
            elseif ammo_name == "ammo-nano-deconstructors" then
              destroy_marked_items(player, player.position, nano_ammo, true)
            end
          end --Auto Nano Bots
          --Do AutoDeconstructMarking
        elseif config.auto_equipment and are_bots_ready(player.character) then
          local equipment=get_valid_equipment_names(player)
          if equipment["equipment-bot-chip-items"] or equipment["equipment-bot-chip-trees"] then
            gobble_items(player, equipment)
          end
        end --Auto Equipoment
      end --Player Ready
    end --For Players
  end --NANO Automatic scripts
end
script.on_event(defines.events.on_tick, on_tick)

-------------------------------------------------------------------------------
--[[Init]]--
function _G.on_init(update)
  if not update then
    global = {}
    global.queued = List.new()
    global.current_index = 1
    global.kill_proxy = {}
    global.config = table.deepcopy(MOD.config.control)
    game.print(MOD.name..": Init Complete")
  else
    global.queued = global.queued or List.new()
    global.current_index = global.current_index or 1
    global.kill_proxy = global.kill_proxy or {}
    global.config = global.config or table.deepcopy(MOD.config.control)
    game.print(MOD.name..": Upgrade complete.")
  end
end
script.on_init(_G.on_init)

local function on_configuration_changed()
  _G.on_init(true)
end
script.on_configuration_changed(on_configuration_changed)

local interface = require("interface")
remote.add_interface(MOD.interface, interface)
