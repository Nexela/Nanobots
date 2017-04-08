-------------------------------------------------------------------------------
--[[Player]]
-------------------------------------------------------------------------------
local Player = {}

Player.get_object_and_data = function (index)
    if game.players[index] then
        return game.players[index], global.players[index]
    end
end

Player.new = function(player_index)
    local obj = {
        index = player_index,
        name = game.players[player_index].name,
        ranges = {}
    }
    return obj
end

Player.init = function(player_index, overwrite)
    local pdata = global.players or {}
    if player_index then
        if not game.players[player_index] then error("Invalid Player") end
        if not pdata[player_index] or (pdata[player_index] and overwrite) then
            pdata[player_index] = Player.new(player_index)
            if global._mess_queue then
                for _, msg in pairs(global._mess_queue) do
                    game.print(msg)
                end
            end
            global._mess_queue = nil
        end
    else
        for index in pairs(game.players) do
            if not pdata[index] or (pdata[index] and overwrite) then
                pdata[index] = Player.new(index)
            end
        end
    end
    return pdata
end

Player.on_player_created = function(event)
    Player.init(event.player_index)
    if global._mess_queue then
        for _, msg in pairs(global._mess_queue) do
            game.print(msg)
        end
    end
    global._mess_queue = nil
end

return Player
