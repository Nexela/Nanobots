--/c
local entity = game.player.selected
for _, inv in pairs(defines.inventory) do
  local inventory = entity.get_inventory(inv)
  if inventory and inventory.valid then
    if inventory.get_item_count() > 0 then
      for i=1, #inventory do
        if inventory[i].valid_for_read then
          local stack = inventory[i]
          stack.health = .1
        end
      end
    end
  end
end
