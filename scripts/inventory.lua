--- @class Nanobots.Inventory
local Inventory = {}

local Position = require("__stdlib__/stdlib/area/position")
local Area = require("__stdlib__/stdlib/area/area")

local main_inventories = require("scripts/constants").MAIN_INVENTORIES

function Inventory.get_possible_from(entity, stacks, inventories, cheat_mode, at_least_one)
  for stack in pairs(stacks) do
    for inventory in pairs(inventories) do

    end
  end

end

--- Return the name of the item found for table.find if we found at least 1 item
--- or cheat_mode is enabled. Does not return items with inventory
--- @todo Cache vehicle and train
--- @param player LuaPlayer
--- @param simple_stacks ItemStackDefinition[]
--- @param cheat_mode? boolean
--- @param at_least_one? boolean
--- @return ItemStackDefinition?
function Inventory.find_item(player, simple_stacks, cheat_mode, at_least_one)
  for _, simple_stack in pairs(simple_stacks) do
    local item, count = simple_stack.name, simple_stack.count
    count = at_least_one and 1 or count
    local prototype = game.item_prototypes[item]
    if prototype.type ~= "item-with-inventory" then
      local item_stack = { name = item, count = count }
      if cheat_mode or player.get_item_count(item) >= count then
        return item_stack
      else
        local vehicle = player.vehicle
        local train = vehicle and vehicle.train
        return (vehicle and ((vehicle.get_item_count(item) >= count) or (train and train.get_item_count(item) >= count)) and item_stack) or nil
      end
    end
  end
  return nil
end

--- Get an item with health data from the inventory
--- @param entity LuaEntity|LuaPlayer the entity object to search
--- @param item_stack ItemStackDefinition the item to look for
--- @param cheat? boolean cheat the item
--- @param at_least_one? boolean #return as long as count > 0
--- @return ItemStackDefinition|nil
function Inventory.get_item_stack(entity, item_stack, cheat, at_least_one)
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
            local removed = math.min(stack.count, count) --[[@as uint]]
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

--- Attempt to insert an ItemStackDefinition or array of ItemStackDefinition into the entity
--- Spill to the ground at the entity anything that doesn't get inserted
--- @param entity LuaEntity|LuaPlayer
--- @param item_stacks ItemStackDefinition|ItemStackDefinition[]
--- @param is_return_cheat? boolean
--- @return boolean #there was some items inserted or spilled
function Inventory.insert_or_spill_items(entity, item_stacks, is_return_cheat)
  if is_return_cheat then return false end

  local new_stacks = {}
  if item_stacks then
    if item_stacks[1] and item_stacks[1].name then
      new_stacks = item_stacks
    elseif item_stacks and item_stacks.name then
      new_stacks = { item_stacks }
    end
    --- @cast new_stacks ItemStackDefinition[]
    for _, stack in pairs(new_stacks) do
      local name, count, health = stack.name, stack.count, stack.health or 1.0
      local prototype = game.item_prototypes[name]
      if prototype and not prototype.has_flag("hidden") then
        local inserted = entity.insert { name = name, count = count, health = health }
        if inserted ~= count then
          entity.surface.spill_item_stack(entity.position,
            { name = name, count = count - inserted, health = health }, true)
        end
      end
    end
    return new_stacks[1] and new_stacks[1].name and true
  end
  return false
end

--- Attempt to insert an arrary of items stacks into an entity
--- @param entity LuaEntity
--- @param item_stacks ItemStackDefinition|ItemStackDefinition[]
--- @return ItemStackDefinition[] #Items not inserted
function Inventory.insert_into_entity(entity, item_stacks)
  item_stacks = item_stacks or {} ---@type ItemStackDefinition
  if item_stacks and item_stacks.name then item_stacks = { item_stacks } end
  --- @cast item_stacks ItemStackDefinition[]
  local new_stacks = {} --- @type ItemStackDefinition[]
  for _, stack in pairs(item_stacks) do
    local name, count, health = stack.name, stack.count, stack.health or 1.0
    local inserted = entity.insert(stack)
    if inserted ~= count then new_stacks[#new_stacks + 1] = { name = name, count = count - inserted, health = health } end
  end
  return new_stacks
end

--- Scan the ground under a ghost entities collision box for items and return an array of ItemStackDefinition.
--- @param surface LuaSurface
--- @param box BoundingBox
--- @return ItemStackDefinition[]
function Inventory.get_all_items_on_ground(surface, box)
  local item_stacks = {} --- @type ItemStackDefinition[]
  for _, item_on_ground in pairs(surface.find_entities_filtered { name = "item-on-ground", area = box }) do
    item_stacks[#item_stacks + 1] = { name = item_on_ground.stack.name, count = item_on_ground.stack.count,
      health = item_on_ground.health or 1.0 }
    item_on_ground.destroy()
  end
  local inserter_area = Area.expand(box, 3)
  for _, inserter in pairs(surface.find_entities_filtered { area = inserter_area, type = "inserter" }) do
    local stack = inserter.held_stack
    if stack.valid_for_read and Position.inside(inserter.held_stack_position, box) then
      item_stacks[#item_stacks + 1] = { name = stack.name, count = stack.count, health = stack.health or 1 }
      stack.clear()
    end
  end
  return item_stacks
end

--- Attempt to satisfy module requests from player inventory
--- @param requests LuaEntity the item request proxy to get requests from
--- @param entity LuaEntity the entity to satisfy requests for
--- @param player LuaPlayer the player to get modules from
function Inventory.satisfy_requests(requests, entity, player)
  local p_inv = player.get_main_inventory() --[[@as LuaInventory]]
  local new_requests = {} ---@type { [string]: uint}
  for name, count in pairs(requests.item_requests) do
    if count > 0 and entity.can_insert(name) then
      local removed = player.cheat_mode and count or p_inv.remove { name = name, count = count }
      local inserted = removed > 0 and entity.insert { name = name, count = removed } or 0
      local balance = count - inserted
      new_requests[name] = balance > 0 and balance or nil
    else
      new_requests[name] = count
    end
  end
  requests.item_requests = new_requests
end

return Inventory
