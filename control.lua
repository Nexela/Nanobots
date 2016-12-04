local NANO = require("config")

local function get_build_area(pos, rad)
  return {top_left={x=pos.x-rad, y=pos.y-rad}, bottom_right={x=pos.x+rad, y=pos.y+rad}}
end

local function get_equipment(player, eq_name)
  local armor = player.get_inventory(defines.inventory.player_armor)
  if armor[1].valid_for_read and armor[1].grid and armor[1].grid.equipment then
    for i=1, #armor[1].grid.equipment do
      if armor[1].grid.equipment[i].name==eq_name then
        return armor[1].grid.equipment[i]
      end
    end
  end
  return nil
end

local function build_ghosts_in_player_range(player, pos, nano_ammo)
  local area = get_build_area(pos, NANO.BUILD_RADIUS)
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, name="entity-ghost", force=player.force}) do
    if nano_ammo.valid_for_read and not ghost.surface.find_logistic_network_by_position(ghost.position, ghost.force) then
      if player.surface.can_place_entity{name=ghost.ghost_name,position=ghost.position,direction=ghost.direction,force=ghost.force}
      and player.remove_item({name=ghost.ghost_name, count=1}) == 1 then
        ghost.revive()
        nano_ammo.drain_ammo(1)
      end
    else -- We ran out of ammo!
      break
    end
  end
end

local function everyone_hates_trees(player, pos, nano_ammo) --luacheck: ignore
end

local function destroy_marked_items(player, pos, nano_ammo) --luacheck: ignore
end

local function gobble_items_on_ground(player, equipment) --luacheck: ignore
  local rad = player.character.logistic_cell.construction_radius
  local area = get_build_area(player.position, rad)
  if not player.surface.find_nearest_enemy{position=player.position ,max_distance=rad+20,force=player.force} then
    for _, item in pairs(player.surface.find_entities_filtered{area=area, name="item-on-ground"}) do
      if not item.to_be_deconstructed(player.force) then
        item.order_deconstruction(player.force)
      end
    end
  end
end

local function on_tick(event)
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.players) do
      --Establish connected, non afk, player character
      if player.connected and player.afk_time < NANO.TICK_MOD * 1.5 and player.character and player.force.technologies["automation"].researched then
        local gun_slot = player.get_inventory(defines.inventory.player_guns)[player.character.selected_gun_index]
        --Nano Gun selected and we are not in a logistic network.
        if gun_slot.valid_for_read and gun_slot.name == "nano-gun" and not player.character.logistic_network then
          local nano_ammo = player.get_inventory(defines.inventory.player_ammo)[player.character.selected_gun_index]
          --Nano Ammo name defines what we do!
          if nano_ammo.valid_for_read then
            if nano_ammo.name == "nano-constructor-ammo" then
              build_ghosts_in_player_range(player, player.position, nano_ammo)
            elseif nano_ammo.name == "nano-termite-ammo" then
              everyone_hates_trees(player, player.position, nano_ammo)
            elseif nano_ammo.name == "nano-metal-termite-ammo" then
              destroy_marked_items(player, player.position, nano_ammo)
            end
          end
          --Do AutoDeconstructMarking
        elseif player.character.logistic_cell and player.character.logistic_cell.mobile
          and player.character.logistic_cell.stationed_construction_robot_count > 0 then
            local equipment=get_equipment(player, "bot-reprogrammer-ground")
            if equipment then
              --if reprogrammer installed
              gobble_items_on_ground(player, equipment)
            end
          end
        end
      end
    end
  end
  script.on_event(defines.events.on_tick, on_tick)
