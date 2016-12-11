--luacheck: globals Position Tile
--aubergine18
_G.cursor = {}

--[[ INTERFACE ]]

function _G.cursor.latch( player, itemName, onCancel, data )
  global.cursor = global.cursor or {}
  global.cursor[player.name] = { itemName = itemName, onCancel = onCancel, data = data }
end

function _G.cursor.state( player )
  global.cursor = global.cursor or {}
  return global.cursor[player.name]
end

function _G.cursor.unlatch( player )
  global.cursor = global.cursor or {}
  global.cursor[player.name] = nil
end

function _G.cursor.pickUp( player, itemName, cursor )
  player.clean_cursor()

  cursor = cursor or player.cursor_stack

  local stack = type(itemName) == 'table' and itemName or { name = itemName }

  if cursor.can_set_stack( stack ) then
    cursor.set_stack( stack )
    game.print('picked up '..itemName)
    return true
  else
    game.print('failed to pick up '..itemName)
    return false
  end
end

--[[ HELPERS ]]--

-- is itemName inside target?
local function isInside( target, itemName )
  if not target then return end
  if target.get_item_count( itemName ) > 0 then
    target.remove_item( itemName )
    game.print 'found in an entity'
    return true
  end
end

-- is itemName on floor near player?
local function dropNear( player, itemName )
  -- doesn't search belts: https://forums.factorio.com/viewtopic.php?p=213509#p213509
  local found = player.surface.find_entities_filtered {
    type = 'item-entity';
    name = 'item-on-ground';
    area = Position.expand_to_area( Tile.from_position( player.position ), 32 );
  }
  for _,item in pairs(found) do
    if item.stack.valid_for_read and item.stack.name == itemName then
      item.destroy()
      game.print 'found on floor'
      return true
    end
  end
end

--[[ EVENTS ]]-- events.lua

function _G.cursor.onChange( player )

  local monitor = global.cursor and global.cursor[player.name]

  if monitor then

    local itemName = monitor.itemName
    local cursor   = player.cursor_stack

    if cursor.valid_for_read and cursor.name == itemName then
      return -- these are not the droids you are looking for...
    end

    local selected = player.selected
    local opened   = player.opened

    -- construction cancelled?
    if isInside( player, itemName ) then
      game.print 'player cancelled construction'
      -- unlatch cursor
      _G.cursor.unlatch( player )

      -- trigger cancel event?
      if monitor.onCancel then
        game.print 'trigger cancel event'
        monitor.onCancel( player, itemName, monitor.data )
      end

      return
    end

    -- find item and pick it up
    -- TODO: vehicle?
    if isInside( selected, itemName )
    or isInside( opened  , itemName )
    or dropNear( player  , itemName ) then
      _G.cursor.pickUp( player, itemName )
    else
      game.print 'could not find monitored item'
    end
  end
end

-- cursor stack change
script.on_event( defines.events.on_player_cursor_stack_changed, function( data )
  local player = game.players[data.player_index]
  _G.cursor.onChange( player )
end )

--tweaks
-- local function isInside( target, itemName )
--   return target and target.remove_item( itemName ) > 0
-- end
-- if player.selected.type = "transport-belt" then
--   player.selected.get_transport_line(1).remove_items(blah)
--   player.selected.get_transport_line(2).remove_items(blah)
-- end
