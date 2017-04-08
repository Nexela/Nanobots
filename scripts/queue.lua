-------------------------------------------------------------------------------
--[[Queue]]
-------------------------------------------------------------------------------

local max = math.max
local queue_speed = MOD.config.QUEUE_SPEED_BONUS

local function NtoZ_c(x, y)
    return (x >= 0 and x or (-0.5 - x)), (y >= 0 and y or (-0.5 - y))
end

local function cantorPair_v7(pos)
    local x, y = NtoZ_c(pos.x, pos.y)
    local s = x + y
    local h = s * (s + 0.5) + x
    return h + h
end

local Queue = {}
Queue.new = function ()
    return {_hash={}}
end

Queue.has_hash = function(t, position)
    return t._hash[cantorPair_v7(position)]
end

Queue.insert = function (t, data, tick, count)
    local queue = global.nano_queue[tick] or {}
    queue[#queue + 1] = data
    t[tick] = queue
    t._hash[cantorPair_v7(data.position)] = true
    return t, count
end

Queue.next = function (tick, force_name)
    local tick_spacing = max(1, global.config.ticks_per_queue - queue_speed[game.forces[force_name].get_gun_speed_modifier("nano-ammo")])
    local count = 0
    return function()
        count = count + 1
        tick = tick + tick_spacing
        return tick, count
    end
end

--Tick handler, handles executing from the queue
Queue.execute = function(event, queue)
    if queue[event.tick] then
        for _, data in ipairs(queue[event.tick]) do
            queue._hash[cantorPair_v7(data.position)] = nil
            Queue[data.action](data)
            Queue.execute(queue, data)
        end
        queue[event.tick] = nil
    end
end

return Queue
