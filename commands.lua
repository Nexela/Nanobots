local function commands(event)
    local player = game.players[event.player_index]
    if player.admin then
        local params = event.parameter and event.parameter:split(" ") or {}
        if params[1] == "reset" then
            if params[2] == "mod" then
                MOD.interface.reset_mod(true)
            elseif params[2] == "cell_queue" then
                MOD.interface.reset_queue("cell_queue")
            elseif params[2] == "nano_queue" then
                MOD.interface.reset_queue("nano_queue")
            end
        elseif params[1] == "count" then
            MOD.interface.count_queue(params[2])
        end
    end
end

return commands
