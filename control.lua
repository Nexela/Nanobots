--luacheck: globals List
local NANO = require("config")
require("stdlib/utils/utils")
local Position = require("stdlib/area/position")
local List = require("stdlib/utils/list")

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
  if gun.valid_for_read and gun.name == gun_name and ammo.valid_for_read then
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

--Is the player connected, not afk, and have an attached character
--player: the player object
--return: true or false
local function is_connected_player_ready(player)
  return (player.afk_time < NANO.TICK_MOD * 1.5 and player.character and player.force.technologies["automated-construction"].researched) or false
end

-------------------------------------------------------------------------------
--[[Nano Emitter Stuff]]--
--Builds the next item in the queue
local function build_queued(data)
  if data.entity.valid then
    local surface, position = data.entity.surface, data.entity.position
    local revived, entity = data.entity.revive()
    if revived and entity and entity.valid then --raise event if entity-ghost
      local event = {tick = game.tick, player_index=data.player_index, created_entity=entity}
      game.raise_event(defines.events.on_built_entity, event)
    elseif not revived then --Give the item back if the entity was not revived
      game.players[data.player_index].insert({name=data.item, count=1})
    end
    if revived then
      surface.create_entity{name="builder-cloud",position=position,force="neutral"}
    end
  else --Give the item back ghost isn't valid anymore.
    game.players[data.player_index].insert({name=data.item, count=1})
  end
end

-- local function find_item(_, k, player)
-- return player.get_item_count(k) > 0 and not (player.cursor_stack.valid_for_read and player.cursor_stack.name == k)
-- end
-- local function find_match(v, _, ghost)
-- if type(v) == "table" then return v.ghost == ghost end
-- end
--Optimize for table.find
local table_find = table.find
local find_item=function(_, k, p) return p.get_item_count(k) > 0 and not (p.cursor_stack.valid_for_read and p.cursor_stack.name == k) end
local find_match=function(v, _, entity) if type(v) == "table" then return v.entity == entity end end

--Build the ghosts in the range of the player
local function queue_ghosts_in_range(player, pos, nano_ammo, ghost_type)
  local area = Position.expand_to_area(pos, NANO.BUILD_RADIUS)

  --local main_inv = defines.inventory.player_main
  for index, ghost in pairs(player.surface.find_entities_filtered{area=area, name=ghost_type, force=player.force}) do
    if nano_ammo.valid_for_read then
      --Get first available item that places entity from inventory that is not in our hand.
      local _, item = table_find(ghost.ghost_prototype.items_to_place_this, find_item, player)
      --if wall: Have item, Not in logistic network, can we place entity or is it tile, is not already queued, can we remove 1 item.
      if item and not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force)
      and ((ghost_type == "entity-ghost" and player.surface.can_place_entity{name=ghost.ghost_name,position=ghost.position,direction=ghost.direction,force=ghost.force})
        or ghost_type == "tile-ghost") and not table_find(global.queued, find_match, ghost)
      and player.remove_item({name=item, count=1}) == 1 then
        if index == 1 then --if we have at least 1 item to build play sound.
          player.surface.create_entity{name="sound-nanobot-creators", position = player.position}
        end
        nano_ammo.drain_ammo(1)
        List.push_right(global.queued, {action = "build_queued", player_index=player.index, entity=ghost, item=item})
      end
    else -- We ran out of ammo break out!
      break
    end
    --end
  end
end

--Nano Termites
--local max = math.max
local function termite_queued(data)
  local tree=data.entity
  if tree and tree.valid then
    --game.print("nom, nom, nom")
    tree.health=tree.health-10
    if tree.health > 0 then
      List.push_right(global.queued, data)
    else
      tree.die()
    end
  end
end


local function everyone_hates_trees(player, pos, nano_ammo) --luacheck: ignore
  local area = Position.expand_to_area(pos, NANO.TERMITE_RADIUS)
  for index, stupid_tree in pairs(player.surface.find_entities_filtered{area=area, type="tree"}) do
    if nano_ammo.valid_for_read and not stupid_tree.surface.find_logistic_network_by_position(stupid_tree.position, player.force)
    and not table_find(global.queued, find_match, stupid_tree) then
    if index == 1 then player.surface.create_entity{name="sound-nanobot-creators", position = player.position} end
      stupid_tree.order_deconstruction(player.force) --Order deconstruction to show us that the tree is queued!
      nano_ammo.drain_ammo(1)
      List.push_right(global.queued, {action="termite_queued", entity=stupid_tree, player_index=player.index})
    end
  end
end

--Nano Scrappers
local function destroy_marked_items(player, pos, nano_ammo) --luacheck: ignore
end

local function handle_next(data)
  local actions={build_queued=build_queued, termite_queued=termite_queued}
  actions[data.action](data)
end
-- if data.action == build_queued then build_queued(data)
-- elseif data.action=

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
    handle_next(List.pop_left(global.queued))
  end
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.connected_players) do

      --Establish connected, non afk, player character
      if is_connected_player_ready(player) then
        if NANO.AUTO_NANO_BOTS and not player.character.logistic_network then
          local gun, nano_ammo, ammo_name = get_gun_ammo_name(player, "gun-nano-emitter")
          if gun then
            if ammo_name == "ammo-nano-constructors" then
              queue_ghosts_in_range(player, player.position, nano_ammo,"entity-ghost")
            elseif ammo_name == "ammo-nano-flooring" then
              queue_ghosts_in_range(player, player.position, nano_ammo, "tile-ghost")
            elseif ammo_name == "ammo-nano-termites" then
              everyone_hates_trees(player, player.position, nano_ammo)
            elseif ammo_name == "ammo-nano-scrappers" then
              destroy_marked_items(player, player.position, nano_ammo)
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
