local Config = require('config')
require('__stdlib__/stdlib/utils/string')

local function commands(event)
    local player = game.players[event.player_index]
    if player.admin then
        local params = event.parameter and event.parameter:split(' ') or {}
        if params[1] == 'reset' then
            script.raise_event(Config.reset_nano_queue, event)
        end
    end
end

return commands
