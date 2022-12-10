--- @class Nanobots.Player
local Player = {}
local Table = require("scripts/table")

--- @param player LuaPlayer
--- @return Nanobots.pdata
local function create_player_data(player)
  global.players = global.players or {}

  local pdata = {}
  global.players[player.index] = pdata
  return pdata
end

--- @return LuaPlayer, Nanobots.pdata
function Player.get(index)
  local player = game.get_player(index)
  if player then return player, global.players and global.players[index] or create_player_data(player) end
  error("No Player found with index " .. index)
end

function Player.on_init()
  global.players = global.players or {}
  for _, player in pairs(game.players) do
    create_player_data(player)
  end
end

function Player.on_load()
end

function Player.on_player_created(event)
  create_player_data(game.get_player(event.player_index)--[[@as LuaPlayer]] )
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
