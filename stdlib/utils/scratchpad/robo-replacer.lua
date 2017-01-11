--------------------------------------------------------------------
--local Inventory = require("stdlib/entity/inventory")
--local Position = require ("stdlib/area/position")
local Entity = require ("stdlib/entity/entity")
---------------------------------------------------------------------
--[[roboport force robots to search for newly place charge locations]]
--from STDLIB
local function expand_to_area(pos, radius)
    if #pos == 2 then
        return { left_top = { x = pos[1] - radius, y = pos[2] - radius }, right_bottom = { x = pos[1] + radius, y = pos[2] + radius } }
    end
    return { left_top = { x = pos.x - radius, y = pos.y - radius}, right_bottom = { x = pos.x + radius, y = pos.y + radius } }
end
local function copy_inventory(src, dest)
    local left_over = {}
    for i = 1, #src do
        local stack = src[i]
        if stack and stack.valid_for_read then
            local cur_stack = {name=stack.name, count=stack.count, health=stack.health or 1}
            cur_stack.ammo = Entity.has(stack, "ammo") and stack.ammo or nil
            cur_stack.durability = Entity.has(stack, "durability") and stack.durability or nil
            local inserted = dest.insert(cur_stack)
            local amt_not_inserted = stack.count - inserted
            if amt_not_inserted > 0 then
              left_over[#left_over+1] = cur_stack
            end
        end
    end
    return left_over
end

local roboport = {}
function roboport.on_built_roboport(event)
  local entity = event.created_entity
  if entity.type == "roboport" and not event.ignore then
    local cell = entity.logistic_cell
    local area = expand_to_area(entity.position, 75)
    for _, old_roboport in pairs(entity.surface.find_entities_filtered{area=area, type="roboport", force=entity.force, limit= 20}) do
      if old_roboport ~= entity then
        local old_cell = old_roboport.logistic_cell
        if cell and old_cell and cell.is_neighbour_with(old_cell) and old_cell.to_charge_robot_count >= 0 then
          local new_roboport = old_roboport.surface.create_entity{name=old_roboport.name, position=old_roboport.position, direction=old_roboport.direction, force=old_roboport.force}
          new_roboport.last_user = old_roboport.last_user
          new_roboport.energy = old_roboport.energy
          game.raise_event(defines.events.on_built_entity,{created_entity=new_roboport, player_index = event.player_index, ignore=true})
          for _, inv in pairs(defines.inventory) do
            local old_inventory = old_roboport.get_inventory(inv)
            local new_inventory = new_roboport.get_inventory(inv)
            if old_inventory and old_inventory.valid and old_inventory.get_item_count() > 0 then
              copy_inventory(old_inventory, new_inventory)
              old_inventory.clear()
            end
          end
          game.raise_event(defines.events.on_entity_died, {entity=old_roboport})
          old_roboport.destroy()
        end
      end
    end
  end
end
--script.on_event(defines.events.on_built_entity, roboport.on_built_roboport)
Event.register(defines.events.on_built_entity, roboport.on_built_roboport)
return roboport

-------------------------------------------------------------------------------
