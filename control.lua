--luacheck: globals List
local NANO = require("config")
require("stdlib/utils/utils")
local Position = require("stdlib/area/position")
local List = require("stdlib/utils/list")

--Is the player connected, not afk, and have an attached character
--player: the player object
--return: true or false
local function is_connected_player_ready(player)
  return (player.afk_time < NANO.TICK_MOD * 1.5 and player.character and player.force.technologies["automated-construction"].researched) or false
end

--Loop through armor and return a table of valid equipment names and counts
--player: the player object
--return: a table of valid equipment names.
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

--TODO: Checking for the gun just wastes time, we could check the ammo directly.
--Get the gun, ammo and ammo name for the named gun: will return nil
--for all returns if there is no ammo for the gun.
--player: the player object
--gun_name: the name of the gun to get
--Return: gun: table: the gun object or nil
--Return: ammo: table: the ammo object or nil
--return: ammo.name: string: the name of the ammo or nil
local function get_gun_ammo_name(player, gun_name)
  local index = player.character.selected_gun_index
  local gun = player.get_inventory(defines.inventory.player_guns)[index]
  local ammo = player.get_inventory(defines.inventory.player_ammo)[index]
  if gun.valid_for_read and gun.name == gun_name and ammo.valid and ammo.valid_for_read then
    return gun, ammo, ammo.name
  end
  return nil, nil, nil
end

--Does the character have a personal robort and construction robots
--character: the player character
--return: true or false
local function are_bots_ready(character)
  return (character.logistic_cell and character.logistic_cell.mobile
    and character.logistic_cell.stationed_construction_robot_count > 0) or false
end

-------------------------------------------------------------------------------
--[[Nano Emitter Queue Handler]]--
local queue = {}

--Nano Termites, Currently Unused!
-- function queue.termite(data)
--   local tree=data.entity
--   if tree and tree.valid then
--     --game.print("nom, nom, nom")
--     tree.health=tree.health-10
--     if tree.health > 0 then
--       List.push_right(global.queued, data)
--     else
--       tree.die()
--     end
--   end
-- end

function queue.deconstruction(data)
  if data.entity.valid then
    data.entity.surface.create_entity{name="nano-cloud-small-deconstructors", position=data.entity.position, force="neutral"}
    local player = game.players[data.player_index]
    --Start inserting items!
    for item, count in pairs(data.item_list) do
      local inserted = player.insert({name=item, count=count})
      if inserted ~= count then
        player.surface.spill_item_stack(player.position,{name=item, count=count-inserted},true)
      end
    end
    --raise the destory event?
    if data.entity.name ~= "deconstructible-tile-proxy" then
        game.raise_event(defines.events.on_preplayer_mined_item, {tick=game.tick, player_index=player.index, entity=data.entity})
        data.entity.destroy()
    else
        local surface = data.entity.surface
        local position = data.entity.position
        surface.set_tiles({{position=position, name = surface.get_hidden_tile(position)}} )
    end
  end
end

function queue.scrap(data)
  if data.entity.valid then
    data.entity.surface.create_entity{name="nano-cloud-small-scrappers", position=data.entity.position, force="neutral"}
    if data.entity.name ~= "deconstructible-tile-proxy" then
      game.raise_event(defines.events.on_entity_died, {tick=game.tick, force=game.players[data.player_index].force, entity=data.entity})
      data.entity.destroy()
    else
      local surface = data.entity.surface
      surface.set_tiles({{position=data.entity.position, name = surface.get_hidden_tile(data.entity.position)}})
    end
  end
end

--Builds the next item in the queue
function queue.build_ghosts(data)
  if data.entity.valid then
    local surface, position = data.entity.surface, data.entity.position
    local item_requests = data.entity.item_requests
    local temp_item_requests = item_requests
    local module_contents = {}
    data.entity.item_requests = {}
    if (data.entity.ghost_type == "assembling-machine" and data.entity.recipe) or data.entity.ghost_type ~= "assembling-machine" then
      for i,v in pairs(item_requests) do
        local removed_modules = game.players[data.player_index].remove_item({name=v.item, count=v.count})
        if removed_modules > 0 then
          table.insert(module_contents, {name=v.item, count=removed_modules})
        end
        if removed_modules < v.count then
          temp_item_requests[i].count = v.count - removed_modules
        else
          temp_item_requests[i] = nil
        end
      end
    end
    data.entity.item_requests = temp_item_requests
    local revived, entity = data.entity.revive()
    if revived then
      surface.create_entity{name="nano-cloud-small-constructors", position=position, force="neutral"}
      local module_inventory = entity.get_module_inventory()
      if module_inventory then
        for i,v in pairs(module_contents) do
          module_inventory.insert(v)
        end
      end
      if entity and entity.valid then --raise event if entity-ghost
        game.raise_event(defines.events.on_built_entity, {tick = game.tick, player_index=data.player_index, created_entity=entity})
      end
    else --Give the item back if the entity was not revived TODO: Need to check inserted count!
      game.players[data.player_index].insert({name=data.item, count=1})
    end
  else --Give the item back ghost isn't valid anymore.
    game.players[data.player_index].insert({name=data.item, count=1})
  end
end


function queue.repair(data)
  if data.entity.valid then
    data.entity.surface.create_entity{name="nano-cloud-small-repair", position=data.entity.position, force="neutral"}
  end
end

-------------------------------------------------------------------------------
--[[Nano Emitter - Functions]]--

--Optimize for table.find
--local table_merge=table.merge
local table_find = table.find
local find_item=function(_, k, p)
  return p.get_item_count(k) > 0 and not (p.cursor_stack.valid_for_read and p.cursor_stack.name == k and p.cursor_stack.count <= p.get_item_count(k))
end
local find_match=function(v, _, entity)
  if type(v) == "table" then return v.entity == entity end
end

--Build the ghosts in the range of the player
--rewrite to include tiles regardless of type.
local function queue_ghosts_in_range(player, pos, nano_ammo)
  local area = Position.expand_to_area(pos, NANO.BUILD_RADIUS)
  local inserters = {}
  --local main_inv = defines.inventory.player_main
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, force=player.force}) do
    if (ghost.name == "entity-ghost" or ghost.name == "tile-ghost") then
      if nano_ammo.valid and nano_ammo.valid_for_read then
        --Get first available item that places entity from inventory that is not in our hand.
        local _, item = table_find(ghost.ghost_prototype.items_to_place_this, find_item, player)
        --if wall: Have item, Not in logistic network, can we place entity or is it tile, is not already queued, can we remove 1 item.
        if item
        and ((ghost.name == "entity-ghost" and pickup_items_on_ground(ghost, player) and player.surface.can_place_entity{name=ghost.ghost_name,position=ghost.position,direction=ghost.direction,force=ghost.force})
          or ghost.name == "tile-ghost") and not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force)
          and not table_find(global.queued, find_match, ghost) and player.remove_item({name=item, count=1}) == 1 then
          if ghost.ghost_type=="inserter" then -- Add inserters to the end of the build queue.
            inserters[#inserters+1] = {action = "build_ghosts", player_index=player.index, entity=ghost, item=item}
          else
            List.push_right(global.queued, {action = "build_ghosts", player_index=player.index, entity=ghost, item=item})
          end
          nano_ammo.drain_ammo(1)
        end
      else -- We ran out of ammo break out!
        break
      end
      -- Check if entity needs repair (robots don't correctly heal so they are excluded.)
      if #ghost.surface.find_entities_filtered{name="nano-cloud-small-repair", area={{ghost.position.x-0.75, ghost.position.y-0.75}, {ghost.position.x+0.75, ghost.position.y+0.75}}} == 0 then
        ghost.surface.create_entity{name="nano-cloud-small-repair", position=ghost.position, force="neutral"}
        nano_ammo.drain_ammo(1)
      end
    end -- not an actual ghost and doesn't need repair!
  end --Done looping through ghosts
  for _, data in ipairs(inserters) do
    List.push_right(global.queued, data)
  end
end

local function everyone_hates_trees(player, pos, nano_ammo)
  local area = Position.expand_to_area(pos, NANO.TERMITE_RADIUS)
  for _, stupid_tree in pairs(player.surface.find_entities_filtered{area=area, type="tree"}) do
    if nano_ammo.valid and nano_ammo.valid_for_read then
      local tree_area = Position.expand_to_area(stupid_tree.position, .5)

      if player.surface.count_entities_filtered{area=tree_area, name="nano-cloud-small-termites"} < 1 then
        player.surface.create_entity{name="nano-cloud-small-termites", position=stupid_tree.position, force=player.force}
        nano_ammo.drain_ammo(1)
      end
    else
      break
    end
  end
end

--Gets and removes all the items inside an entity.
local function get_all_items_inside(entity)
  local item_list = {}
  for _, inv in pairs(defines.inventory) do
    local inventory = entity.get_inventory(inv)
    if inventory and inventory.valid then
      for item_name, count in pairs(inventory.get_contents()) do
        --item_list[item_name] = (item_list[item_name] or 0) + count
        table.add_values(item_list, item_name, count)
        inventory.remove({name=item_name, count=count})
      end
    end
  end
  return item_list
end

function pickup_items_on_ground(entity, player)
    local surface, position = entity.surface, entity.position
    local items_on_ground = {}
    local collision_mask = entity.ghost_prototype.selection_box
      for _, item_on_ground in pairs(surface.find_entities_filtered{name="item-on-ground", area={{position.x + collision_mask.left_top.x, position.y + collision_mask.left_top.y}, {position.x + collision_mask.right_bottom.x, position.y + collision_mask.right_bottom.y}}}) do
        items_on_ground[item_on_ground.stack.name] = items_on_ground[item_on_ground.stack.name] and items_on_ground[item_on_ground.stack.name] + item_on_ground.stack.count or item_on_ground.stack.count
        item_on_ground.destroy()
    end
    for name, count in pairs(items_on_ground) do
        player.insert{name=name, count=count}
    end
    return true
end

--Nano Scrappers
local function destroy_marked_items(player, pos, nano_ammo, deconstructors)
  local area = Position.expand_to_area(pos, NANO.BUILD_RADIUS)
  for _, entity in pairs(player.surface.find_entities(area)) do
    if entity.to_be_deconstructed(player.force) and (nano_ammo.valid and nano_ammo.valid_for_read) and not table_find(global.queued, find_match, entity) then
      if deconstructors then
        local item_list = {}
        entity.surface.create_entity{name="nano-cloud-small-deconstructors", position=entity.position, force="neutral"}
        nano_ammo.drain_ammo(1)

        --Get all the damn items and clear the inventories
        if entity.has_items_inside() then
            for item_name, count in pairs(get_all_items_inside(entity)) do
              table.add_values(item_list, item_name, count)
            end
        end
        local products

        --Loop through the minable products and add the item(s) to the list
        if entity.prototype.mineable_properties and entity.prototype.mineable_properties.minable then
          products = entity.prototype.mineable_properties.products
        elseif entity.name == "deconstructible-tile-proxy" then
          local tile = entity.surface.get_tile(entity.position)
          if tile.prototype.mineable_properties and tile.prototype.mineable_properties.minable then
            products = tile.prototype.mineable_properties.products
          end
        end
        if products then
          for _, item in pairs(products) do
            table.add_values(item_list, item.name, item.amount or math.random(item.amount_min, item.amount_max))
          end
        end
        --Add to the list if this is an item-entity
        if entity.type == "item-entity" then
          table.add_values(item_list, entity.stack.name, entity.stack.count)
        end

        --Queue Data
        local data = {player_index=player.index, action="deconstruction", item_list=item_list, entity=entity}
        List.push_right(global.queued, data)
      elseif not entity.has_flag("breaths-air") then
        entity.surface.create_entity{name="nano-cloud-small-scrappers", position=entity.position, force="neutral"}
        nano_ammo.drain_ammo(1)
        local data = {player_index=player.index, action="scrap", entity=entity}
        List.push_right(global.queued, data)
      end
    end
  end
end

local function nano_trigger_cloud(event) --luacheck: ignore
  local area = Position.expand_to_area(event.entity.position, game.item_prototypes["gun-nano-emitter"].attack_parameters.range + 5)
  for _, character in pairs(event.entity.surface.find_entities_filtered{area=area, type="player"}) do
    local player = (character.player and character.player.valid) and character.player -- Make sure there is a player and it is valid
    if player and is_connected_player_ready(player) and not player.character.logistic_network then
      local gun, nano_ammo, ammo_name = get_gun_ammo_name(player, "gun-nano-emitter")
      if gun then
        if ammo_name == "ammo-nano-constructors" and event.entity.name == "nano-cloud-big-constructors" then
          queue_ghosts_in_range(player, event.entity.position, nano_ammo)

        elseif ammo_name == "ammo-nano-termites" and event.entity.name == "nano-cloud-big-termites" then
          everyone_hates_trees(player, event.entity.position, nano_ammo)

        elseif ammo_name == "ammo-nano-scrappers" and event.entity.name == "nano-cloud-big-scrappers" then
          destroy_marked_items(player, event.entity.position, nano_ammo, false)

        elseif ammo_name == "ammo-nano-deconstructors" and event.entity.name == "nano-cloud-big-deconstructors" then
          destroy_marked_items(player, event.entity.position, nano_ammo, true)

        end
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
  --Handle building from the queue every x ticks.
  if event.tick % NANO.TICKS_PER_QUEUE == 0 and List.count(global.queued) > 0 then
    local data = List.pop_left(global.queued)
    queue[data.action](data)
  end
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.connected_players) do

      --Establish connected, non afk, player character
      if is_connected_player_ready(player) then
        if NANO.AUTO_NANO_BOTS and not player.character.logistic_network then
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

--Scripts to run through on trigger created entity
--Possible movement to stdlib events in the future.
--Due to a hard crash bug the shooting event will be disabled until a solution is found.
-- local function triggered_entity(event)
--   if string.contains(event.entity.name,"nano%-cloud%-big%-") then
--     nano_trigger_cloud(event)
--   end
-- end
-- script.on_event(defines.events.on_trigger_created_entity, triggered_entity)

-------------------------------------------------------------------------------
--[[Init]]--
local function on_init(update)
  if not update then
    global = {}
    global.queued = List.new()
    global.current_index = 1
  else
    global.queued = global.queued or List.new()
    global.current_index = global.current_index or 1
  end
end
script.on_init(on_init)

local function on_configuration_changed()
  on_init(true)
end
script.on_configuration_changed(on_configuration_changed)
