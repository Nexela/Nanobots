-------------------------------------------------------------------------------
--[[Player]]
-------------------------------------------------------------------------------
require("stdlib/event/event")
local Player = {}

--Default data for the player
local function new(player_index)
    local obj = {
        index = player_index,
        name = game.players[player_index].name,
    }
    return obj
end

--Print any messages in the queue.
local function check_message_queue(player_index)
    if global._mess_queue then
        for _, msg in pairs(global._mess_queue) do
            game.players[player_index].print(msg)
        end
        global._mess_queue = nil
    end
end

--Get the game.player and global.player, create the global.player if not exists.
function Player.get(index)
    return game.players[index], global.players[index] or Player.init(index) and global.players[index]
end

--Add a copy of the passed data to all players
function Player.add_data_all(data)
    local pdata = global.players
    table.each(pdata, function(v) table.merge(v, table.deepcopy(data)) end)
end

function Player.init(event, overwrite)
    event = event and type(event) == "number" and {player_index = event} or event
    global.players = global.players or {}
    if event and event.player_index then
        if not game.players[event.player_index] then error("Invalid Player") end
        if not global.players[event.player_index] or (global.players[event.player_index] and overwrite) then
            global.players[event.player_index] = new(event.player_index)
            check_message_queue(event.player_index)
        end
    else
        for index in pairs(game.players) do
            if not global.players[index] or (global.players[index] and overwrite) then
                global.players[index] = new(index)
            end
        end
    end
end
Event.register(defines.events.on_player_created, Player.init)

return Player
