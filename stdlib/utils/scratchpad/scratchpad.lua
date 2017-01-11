-- --/c
-- local entity = game.player.selected
-- for _, inv in pairs(defines.inventory) do
-- local inventory = entity.get_inventory(inv)
-- if inventory and inventory.valid then
-- if inventory.get_item_count() > 0 then
-- for i=1, #inventory do
-- if inventory[i].valid_for_read then
-- local stack = inventory[i]
-- stack.health = .1
-- end
-- end
-- end
-- end
-- end

--/c
local entity=game.player.selected
for _, inventory in pairs(defines.inventory) do
  local inv = entity.get_inventory(inventory)
  if inv and inv.valid then
    for item, _ in pairs(inv.get_contents()) do
      local stacks = {}
      local stack=inv.find_item_stack(item)
      while stack do
        stacks[#stacks+1] = {name=stack.health, count=stack.count, health=stack.health}
        stack.clear()
        stack=inv.find_item_stack(item)
      end
      --return stacks
    end
  end
end
