local changes = {}

changes['3.2.20'] = function()
    for _, pdata in pairs(global.players) do
        pdata.next_nano_tick = pdata._next_nano_tick or game.tick
        pdata._next_nano_tick = nil
    end
    global.cell_queue = nil
    global._last_player = nil
end

return changes
