--luacheck: globals List
local NANO = require("config")
require("stdlib/utils/utils")
local Position = require("stdlib/area/position")
local Area = require("stdlib/area/area")
local List = require("stdlib/utils/list")

-- Is the player connected, not afk, and have an attached character
-- @param player: the player object
-- @return bool: player is connected and ready
local function is_connected_player_ready(player)
  return (player.afk_time < NANO.TICK_MOD * 1.5 and player.character and player.force.technologies["automated-construction"].researched) or false
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

-- TODO: Checking for the gun just wastes time, we could check the ammo directly.
-- TODO: This is also horrendous
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
      local name, count = stack.name, stack.count
      local inserted = player.insert{name=name, count=count}
      if inserted ~= count then
        player.surface.spill_item_stack(player.position, {name=name, count=count-inserted}, true)
      end
    end
    return (new_stacks[1] and item_stacks)
  end
end

-- Remove all items inside an entity and return an array of SimpleItemStacks removed
-- @param entity: The entity object to remove items from
-- @return table: a table of SimpleItemStacks or nil if empty
local function get_all_items_inside(entity, existing_stacks)
  local item_stacks = existing_stacks or {}
  for _, inv in pairs(defines.inventory) do
    local inventory = entity.get_inventory(inv)
    if inventory and inventory.valid then
      for name, count in pairs(inventory.get_contents()) do
        item_stacks[#item_stacks+1] = {name=name, count=count}
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
    item_stacks[#item_stacks+1] = {name=item_on_ground.stack.name, count=item_on_ground.stack.count}
    item_on_ground.destroy()
  end
  return (item_stacks[1] and item_stacks)
end

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

-- local function create_effect(name, surface, force, position, target, source, speed, duration)
--   --surface.create_entity{name="nano-cloud-projectile-constructors", position=ghost.position, force="neutral", target=player.character.position, speed=.05}
--   --ghost.surface.create_entity{name="nano-beam-healers", position=player.position, force=player.force, target=ghost, source=player.character, speed= .5, duration=20}
--   surface.create_entity{name=name, surface=surface, force=force, position=position, target=target, source=source, speed=speed, duration=duration}
-- end

local function create_beam_or_cloud(beam, cloud, player, target)
  local connected_char = (player.connected and player.controller_type == defines.controllers.character) and player.character
  local surface = player.surface
  local force = player.force
  local speed = .5
  local duration = 20
  local newtarget
  if player.can_reach_entity(target) and not (target and (target.health or 0) > 0) then
    --game.print("Creating Proxy")
    newtarget = surface.create_entity{name="nano-target-proxy", position=target.position, force=force}
    global.kill_proxy[game.tick + 20] = newtarget
  else
    newtarget=target
  end
  if connected_char then
    surface.create_entity{name=beam, position=connected_char.position, force=force, target=newtarget, source=connected_char, speed=speed, duration=duration}
  else
    surface.create_entity{name=cloud, position=target.position, force=force}
  end
end

local function create_projectile(name, surface, force, source, target)
  local speed = .5
  force = force or "player"
  --local connected_char = player.connected and player.controller_type == defines.controllers.character and player.character
  surface.create_entity{name=name, force=force, position=source, target=target, speed=speed}
end

--table.find functions
local table_find = table.find
local _find_item=function(_, k, p)
  return p.get_item_count(k) > 0 and not (p.cursor_stack.valid_for_read and p.cursor_stack.name == k and p.cursor_stack.count <= p.get_item_count(k))
end

local _find_match=function(v, _, entity)
  if type(v) == "table" then return v.entity == entity end
end

-------------------------------------------------------------------------------
--[[Nano Emitter Queue Handler]]--
local queue = {}

function queue.deconstruction(data)
  if data.entity.valid then
    data.entity.surface.create_entity{name="nano-cloud-small-deconstructors", position=data.entity.position, force="neutral"}
    local player = game.players[data.player_index]
    --Start inserting items!
    insert_or_spill_items(player, data.item_stacks)

    if data.entity.name ~= "deconstructible-tile-proxy" then
      game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=data.entity})
      game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=data.item_stack})
      data.entity.destroy()
    else
      local surface = data.entity.surface
      local position = data.entity.position
      game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=data.entity})
      data.entity.destroy()
      surface.set_tiles({{position=position, name = surface.get_hidden_tile(position)}})

      game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=data.item_stack})
      game.raise_event(defines.events.on_robot_mined_tile, {robot=player, positions={position}})

    end
  end
end

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
    else  --tile proxy
      local surface, position = entity.surface, entity.position
      game.raise_event(defines.events.on_robot_pre_mined, {robot=player, entity=entity})
      surface.set_tiles({{position=entity.position, name = surface.get_hidden_tile(data.entity.position)}})
      game.raise_event(defines.events.on_robot_mined, {robot=player, item_stack=nil})
      game.raise_event(defines.events.on_robot_mined_tile, {robot=player, positions={position}})
    end
  end
end
end

function queue.build_entity_ghost(data)
  local ghost, player, ghost_surf, ghost_pos = data.entity, game.players[data.player_index], data.surface, data.position
  if (player and player.valid) then
    --local connected_char = player.connected and player.controller_type == defines.controllers.character and player.character
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
          insert_or_spill_items(player, {name=data.item, count=1})
        end
      else --Can't place entity
        insert_or_spill_items(player, {{name=data.item, count=1}})
      end
    else --Give the item back ghost isn't valid anymore.
      insert_or_spill_items(player, {{name=data.item, count=1}})
    end
  end --valid player
end

function queue.build_tile_ghost(data)
  local ghost, surface, position, player = data.entity, data.surface, data.position, game.players[data.player_index]
  if (player and player.valid) then
    if ghost.valid then
      --if not surface.get_hidden_tile(position) then
        create_beam_or_cloud("nano-beam-constructors", "nano-cloud-small-constructors", player, ghost)
        surface.set_tiles({{name=ghost.ghost_name, position=position}})
        game.raise_event(defines.events.on_robot_built_tile, {robot=player, positions={position}})

      -- else --Can't place entity
      --   insert_or_spill_items(player, {{name=data.item, count=1}})
      -- end
    else --Give the item back ghost isn't valid anymore.
      insert_or_spill_items(player, {{name=data.item, count=1}})
    end
  end --valid player
end

-------------------------------------------------------------------------------
--[[Nano Emitter - Functions]]--

--Build the ghosts in the range of the player
local function queue_ghosts_in_range(player, pos, nano_ammo)
  local area = Position.expand_to_area(pos, NANO.BUILD_RADIUS)
  local inserters = {}
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, force=player.force}) do
    if nano_ammo.valid and nano_ammo.valid_for_read then
      if (NANO.NO_NETWORK_LIMITS or not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force)) then
        if (ghost.name == "entity-ghost" or ghost.name == "tile-ghost") then
          --Get first available item that places entity from inventory that is not in our hand.
          local _, item = table_find(ghost.ghost_prototype.items_to_place_this, _find_item, player)
          if item and not table_find(global.queued, _find_match, ghost) and player.remove_item({name=item, count=1}) == 1 then
            local data = {action = "build_entity_ghost", player_index=player.index, entity=ghost, item=item, surface=ghost.surface, position=ghost.position}
            if ghost.ghost_type=="inserter" then -- Add inserters to the end of the build queue.
              inserters[#inserters+1] = data
            elseif ghost.name == "entity-ghost" then
              List.push_right(global.queued, data)
            elseif ghost.name == "tile-ghost" --[[and not ghost.surface.get_hidden_tile(ghost.position)]] then
              data.action="build_tile_ghost"
              List.push_right(global.queued, data)
              nano_ammo.drain_ammo(1)
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
  local area = Position.expand_to_area(pos, NANO.TERMITE_RADIUS)
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
  local area = Position.expand_to_area(pos, NANO.BUILD_RADIUS)
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
          this_product = products[1]
          for _, item in pairs(products) do
            item_stacks[#item_stacks+1] = {name=item.name, count=item.amount or math.random(item.amount_min, item.amount_max)}
          end
        end

        --Get all of the items on ground.
        if entity.type == "item-entity" then
          item_stacks[#item_stacks+1] = {name=entity.stack.name, count=entity.stack.count}
        end

        --Queue Data
        local data = {player_index=player.index, action="deconstruction", item_stacks=item_stacks, item_stack=this_product, entity=entity}
        List.push_right(global.queued, data)
      elseif not entity.has_flag("breaths-air") then -- Scrappers
        --entity.surface.create_entity{name="nano-cloud-small-scrappers", position=entity.position, force="neutral"}
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
      --local range = get_build_area(player.position, eq_names["equipment-bot-chip-items"] * NANO.CHIP_RADIUS)
      for _, item in pairs(player.surface.find_entities_filtered{area=area, name="item-on-ground"}) do
        if not item.to_be_deconstructed(player.force) then
          item.order_deconstruction(player.force)
        end
      end
    end
    if eq_names["equipment-bot-chip-trees"] then
      local range = Position.expand_to_area(player.position, math.min(rad + 100, eq_names["equipment-bot-chip-trees"] * NANO.CHIP_RADIUS))
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
  --Destroy Proxies
  local proxy = global.kill_proxy[event.tick]
  if proxy and proxy.valid and proxy.destroy() then
    global.kill_proxy[event.tick] = nil
  end

  --Handle building from the queue every x ticks.
  if event.tick % NANO.TICKS_PER_QUEUE == 0 and List.count(global.queued) > 0 then
    local data = List.pop_left(global.queued)
    queue[data.action](data)
    --game.print(serpent.block(data, {comment=false}))
  end
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.connected_players) do

      --Establish connected, non afk, player character
      if is_connected_player_ready(player) then
        if NANO.AUTO_NANO_BOTS and (NANO.NO_NETWORK_LIMITS or not player.character.logistic_network) then
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
        elseif NANO.AUTO_EQUIPMENT and are_bots_ready(player.character) then
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
local function on_init(update)
  if not update then
    global = {}
    global.queued = List.new()
    global.current_index = 1
    global.kill_proxy = {}
  else
    global.queued = global.queued or List.new()
    global.current_index = global.current_index or 1
    global.kill_proxy = global.kill_proxy or {}
  end
end
script.on_init(on_init)

local function on_configuration_changed()
  on_init(true)
end
script.on_configuration_changed(on_configuration_changed)
