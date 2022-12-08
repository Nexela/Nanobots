local Player = {}

--- @return Nanobots.pdata
local function create_player_data(index)
  global.players = global.players or {}
  if not index then
    for _, player in pairs(game.players) do
      global.players[player.index] = {}
    end
  else
    global.players[index] = {}
  end
  return global.players[index]
end

--- @return LuaPlayer, Nanobots.pdata
function Player.get(index)
  local player = game.get_player(index)
  if player then return Player, global.players and global.players[index] or create_player_data(index) end
  error("No Player found with index " .. index)
end

function Player.on_init()
  create_player_data()
end

function Player.on_load()
end

function Player.on_player_created(event)
  create_player_data(event.player_index)
end

function Player.on_player_joined_game(event)
  global.last_player = nil
end

function Player.on_player_left_game(event)
  global.last_player = nil
end

function Player.on_player_removed(event)
  global.last_player = nil
end

return Player
