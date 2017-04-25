-------------------------------------------------------------------------------
--[[Player]]
-------------------------------------------------------------------------------
require("stdlib/event/event")
local Player = {}

function Player.get_object_and_data(index)
    if game.players[index] then
        return game.players[index], global.players[index]
    end
end

function Player.new(player_index)
    local obj = {
        index = player_index,
        name = game.players[player_index].name,
    }
    return obj
end

function Player.add_data_all(data)
    local pdata = global.players
    table.each(pdata, function(v) table.merge(v, table.deepcopy(data)) end)
end

function Player.init(event, overwrite)
    global.players = global.players or {}
    local pdata = global.players or {}
    if event and event.player_index then
        if not game.players[event.player_index] then error("Invalid Player") end
        if not pdata[event.player_index] or (pdata[event.player_index] and overwrite) then
            pdata[event.player_index] = Player.new(event.player_index)
        end
    else
        for index in pairs(game.players) do
            if not pdata[index] or (pdata[index] and overwrite) then
                pdata[index] = Player.new(index)
            end
        end
    end
    if global._mess_queue then
        for _, msg in pairs(global._mess_queue) do
            game.print(msg)
        end
    end
    global._mess_queue = nil
end
Event.register(defines.events.on_player_created, Player.init)

return Player
