local NANO = require("config")

local function build_ghosts_in_builder_range(player, pos)
  local area = {top_left={x=pos.x-NANO.BUILD_RADIUS, y=pos.y-NANO.BUILD_RADIUS}, bottom_right={x=pos.x+NANO.BUILD_RADIUS, y=pos.y+NANO.BUILD_RADIUS}}
  local nano_ammo = player.get_inventory(defines.inventory.player_ammo)[player.character.selected_gun_index]
  if nano_ammo.valid_for_read then
    for _, ghost in pairs(player.surface.find_entities_filtered{area=area, name="entity-ghost", force=player.force}) do
      if (nano_ammo.valid_for_read)
      and player.surface.can_place_entity{name=ghost.ghost_name,position=ghost.position,direction=ghost.direction,force=ghost.force}
      and player.remove_item({name=ghost.ghost_name, count=1}) == 1 then
        ghost.revive()
        nano_ammo.drain_ammo(1)
      end
    end
  end
end

local function on_tick(event)
  if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
    for _, player in pairs(game.players) do
      --Establish connected, non afk, player character
      if player.connected and player.afk_time < NANO.TICK_MOD * 1.5 and player.force.technologies["automation"].researched and player.character then
        local gun_slot = player.get_inventory(defines.inventory.player_guns)[player.character.selected_gun_index]
        if gun_slot.valid_for_read and gun_slot.name == "nano-gun" and not player.character.logistic_network then
          build_ghosts_in_builder_range(player, player.position, gun_slot)
        end
      end
    end
  end
end
script.on_event(defines.events.on_tick, on_tick)

--
-- local function gobble_items_on_ground(player)
-- local pos = player.position
-- local rad = player.character.logistic_cell.construction_radius
-- local area = {top_left={x=pos.x-rad, y=pos.y-rad}, bottom_right={x=pos.x+rad, y=pos.y+rad}}
-- if not player.surface.find_nearest_enemy{position=pos,max_distance=rad+20,force=player.force} then
-- for _, item in pairs(player.surface.find_entities_filtered{area=area, name="item-on-ground"}) do
-- item.order_deconstruction(player.force)
-- end
-- end
-- end
--
-- local function on_tick(event)
-- if NANO.TICK_MOD > 0 and event.tick % NANO.TICK_MOD == 0 then
-- for _, player in pairs(game.players) do
-- if player.connected and player.afk_time < NANO.TICK_MOD * 1.5 and player.character and player.force.technologies["automation"].researched then
-- if NANO.AUTO_BUILD and not player.character.logistic_network then
-- build_ghosts_in_builder_range(player, player.position)
-- elseif NANO.AUTO_GOBBLE and player.character.logistic_cell and player.character.logistic_cell.mobile
-- and player.character.logistic_cell.stationed_construction_robot_count > 0 then
-- gobble_items_on_ground(player)
-- end
-- end
-- end
-- end
-- end
-- script.on_event(defines.events.on_tick, on_tick)
--
-- local function on_built_entity(event)
-- local entity=event.created_entity
-- if entity.name == "blueprint-builder" or (entity.name == "entity-ghost" and entity.ghost_name == "blueprint-builder") then
-- local pos=entity.position
-- entity.destroy()
-- local player = game.players[event.player_index]
-- if NANO.KEEP_BUILDER then player.insert({name="blueprint-builder", count=1}) end
-- build_ghosts_in_builder_range(player, pos)
-- end
--
-- end
-- script.on_event(defines.events.on_built_entity, on_built_entity)
