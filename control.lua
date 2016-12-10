local NANO = require("config")
-- local AC_RECIPES = {"ammo-nano-constructors", "ammo-nano-scrappers", "ammo-nano-termites", "gun-nano-emitter"}
-- local ROBO_RECIPES = {"equipment-bot-chip-items", "equipment-bot-chip-trees"}

--Expand a position to an area
--pos: full factorio position table
--rad: number: radius to expand to
--return: factorio area table
local function get_build_area(pos, rad)
  return {top_left={x=pos.x-rad, y=pos.y-rad}, bottom_right={x=pos.x+rad, y=pos.y+rad}}
end

--Get the named equipment in players first(only) armor slot
--player: the player object
--eq_name: string or table of strings: the name of the equipment to get
--return: a table of equipment
-- local function get_equipment(player, eq_name)
-- local armor = player.get_inventory(defines.inventory.player_armor)
-- if armor[1].valid_for_read and armor[1].grid and armor[1].grid.equipment then
-- for i=1, #armor[1].grid.equipment do
-- if armor[1].grid.equipment[i].name==eq_name then
-- return armor[1].grid.equipment[i]
-- end
-- end
-- end
-- return nil
-- end

--Loop through armor and return a true table of valid equipment names
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
local function is_player_ready(player)
  return (player.connected and player.afk_time < NANO.TICK_MOD * 1.5 and player.character) or false
end

-------------------------------------------------------------------------------
--[[Nano Emitter Stuff]]--
--Build the ghosts in the range of the player
local function build_ghosts_in_player_range(player, pos, nano_ammo)
  local area = get_build_area(pos, NANO.BUILD_RADIUS)
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, name="entity-ghost", force=player.force}) do
    if nano_ammo.valid_for_read then
      if not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force)
      and player.surface.can_place_entity{name=ghost.ghost_name,position=ghost.position,direction=ghost.direction,force=ghost.force}
      and player.remove_item({name=ghost.ghost_name, count=1}) == 1 then
        local _, entity = ghost.revive()
        local event = {tick = game.tick, player_index=player.index, created_entity=entity}
        --game.print(event.created_entity.name)
        game.raise_event(defines.events.on_built_entity, event)
        --Sideeffect Autofill will attempt to fill these :)
        nano_ammo.drain_ammo(1)
      end
    else -- We ran out of ammo break out!
      break
    end
  end
end

--Nano Termites
local function everyone_hates_trees(player, pos, nano_ammo) --luacheck: ignore
end

--Nano Scrappers
local function destroy_marked_items(player, pos, nano_ammo) --luacheck: ignore
end

-------------------------------------------------------------------------------
--[[Personal Roboport Stuff]]--
--Mark items for deconstruction if player has roboport
local function gobble_items(player, eq_names)
  local rad = player.character.logistic_cell.construction_radius
  local area = get_build_area(player.position, rad)
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
      local range = get_build_area(player.position, math.min(rad + 10000000, eq_names["equipment-bot-chip-trees"] * NANO.CHIP_RADIUS))
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
--Test for other things!
script.on_event(defines.events.on_trigger_created_entity, function(event)
    game.print("TRIGGER "..event.entity.name)
  end)

--The Tick Handler!
--Future improvments: 1 player per tick, move gun/ammo/equip checks to event handlers.
local function on_tick(event)
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.players) do
      --Establish connected, non afk, player character
      if is_player_ready(player) and player.force.technologies["automated-construction"].researched then
        if NANO.AUTO_NANO_BOTS and not player.character.logistic_network then
          local _, nano_ammo, ammo_name = get_gun_ammo_name(player, "gun-nano-emitter")
          if ammo_name == "ammo-nano-constructors" then
            build_ghosts_in_player_range(player, player.position, nano_ammo)
          elseif ammo_name == "ammo-nano-termites" then
            everyone_hates_trees(player, player.position, nano_ammo)
          elseif ammo_name == "ammo-nano-scrappers" then
            destroy_marked_items(player, player.position, nano_ammo)
          end
          --Do AutoDeconstructMarking
        elseif NANO.AUTO_EQUIPMENT and are_bots_ready(player.character) then
          local equipment=get_valid_equipment_names(player)
           if equipment["equipment-bot-chip-items"] or equipment["equipment-bot-chip-trees"] then
             gobble_items(player, equipment)
          end
        end
      end
    end
  end
end
script.on_event(defines.events.on_tick, on_tick)
