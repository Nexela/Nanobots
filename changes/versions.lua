local changes = {}

local interface = require('interface')

changes['1.8.2'] = function()
    interface.reset_queue('nano_queue')
end

changes['1.8.7'] = function()
    interface.reset_queue('cell_queue')
end

changes['3.2.20'] = function()
    for index in pairs(game.players) do --- @cast player LuaPlayer
        local pdata = global.players[index]
        pdata.next_nano_tick = pdata._next_nano_tick or game.tick
        pdata._next_nano_tick = nil
    end
end

return changes
