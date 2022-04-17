local Event = require('__stdlib__/stdlib/event/event')
local Queue = require('scripts/hash_queue')
local interface = {}

function interface.reset_mod(are_you_sure)
    local player_name = game.player and game.player.name or 'script'
    if are_you_sure then
        global = {}
        Event.dispatch({name = Event.core_events.init})
        game.print('Full Reset Completed by ' .. player_name)
    else
        game.print('Full reset attempted but ' .. player_name .. ' was not sure')
    end
end

function interface.reset_queue(queue_name)
    queue_name = queue_name or 'nano_queue'
    local name = 'reset_' .. queue_name
    local id = Event.get_event_name(name)
    if global[queue_name] and id then
        Event.dispatch({name = id})
    end
end

function interface.count_queue(queue_name)
    queue_name = queue_name or 'nano_queue'
    local queue = global[queue_name]
    if queue then
        local a, b = Queue.count(queue)
        game.print('Queued:' .. a .. ' Hashed:' .. b)
    end
end

return interface
