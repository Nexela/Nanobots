local EAC = require("config")

-- local function build_ghosts_in_range(player)
-- local pos = player.position
-- local area = {top_left={x=pos.x-EAC.BUILD_RADIUS, y=pos.y-EAC.BUILD_RADIUS}, bottom_right={x=pos.x+EAC.BUILD_RADIUS, y=pos.y+EAC.BUILD_RADIUS}}
-- for ind, ghost in pairs(player.surface.find_entities_filtered{area=area, name="entity-ghost", force=player.force}) do
-- if EAC.IGNORE_NETWORKS or not ghost.surface.find_logistic_network_by_position(ghost.position,ghost.force) then
-- game.print(ghost.ghost_name .." ".. ind)
-- ghost.revive()
-- end
-- end
-- end

local function build_ghosts_in_builder_range(player, pos)
  local area = {top_left={x=pos.x-EAC.BUILD_RADIUS, y=pos.y-EAC.BUILD_RADIUS}, bottom_right={x=pos.x+EAC.BUILD_RADIUS, y=pos.y+EAC.BUILD_RADIUS}}
  for _, ghost in pairs(player.surface.find_entities_filtered{area=area, name="entity-ghost", force=player.force}) do
    if (EAC.IGNORE_NETWORKS or not ghost.surface.find_logistic_network_by_position(ghost.position,ghost.force))
    and player.remove_item({name=ghost.ghost_name, count=1}) == 1 then
      ghost.revive()
    end
  end
end

local function gobble_items_on_ground(player)
  local pos = player.position
  local rad = player.character.logistic_cell.construction_radius
  local area = {top_left={x=pos.x-rad, y=pos.y-rad}, bottom_right={x=pos.x+rad, y=pos.y+rad}}
  if not player.surface.find_nearest_enemy{position=pos,max_distance=rad+20,force=player.force} then
    for _, item in pairs(player.surface.find_entities_filtered{area=area, name="item-on-ground"}) do
      item.order_deconstruction(player.force)
    end
  end
end

local function on_tick(event)
  if EAC.TICK_MOD > 0 and event.tick % EAC.TICK_MOD == 0 then
    for _, player in pairs(game.players) do
      if player.connected and player.afk_time < EAC.TICK_MOD * 1.5 and player.character and player.force.technologies["automation"].researched then
        if EAC.AUTO_BUILD and not player.character.logistic_network then
          build_ghosts_in_builder_range(player, player.position)
        elseif EAC.AUTO_GOBBLE and player.character.logistic_cell and player.character.logistic_cell.mobile
          and player.character.logistic_cell.stationed_construction_robot_count > 0 then
            gobble_items_on_ground(player)
          end
        end
      end
    end
  end
  script.on_event(defines.events.on_tick, on_tick)

  local function on_built_entity(event)
    local entity=event.created_entity
    if entity.name == "blueprint-builder" or (entity.name == "entity-ghost" and entity.ghost_name == "blueprint-builder") then
      local pos=entity.position
      entity.destroy()
      local player = game.players[event.player_index]
      if EAC.KEEP_BUILDER then player.insert({name="blueprint-builder", count=1}) end
      build_ghosts_in_builder_range(player, pos)
    end

  end
  script.on_event(defines.events.on_built_entity, on_built_entity)
