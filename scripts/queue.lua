-------------------------------------------------------------------------------
--[[Queue]]
-------------------------------------------------------------------------------
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

Queue.get_hash = function(t, position)
    local hash_val = cantorPair_v7(position)
    return t._hash[hash_val], hash_val
end

Queue.insert = function (t, data, tick, count)
    t[tick] = t[tick] or {}
    t[tick][#t + 1] = data
    t._hash[cantorPair_v7(data.position)] = data.action or "error"
    return t, count
end

Queue.next = function (t, tick, tick_spacing, dont_combine)
    tick_spacing = tick_spacing or 1
    local count = 0
    return function()
        tick = tick + tick_spacing
        while dont_combine and t[tick] do
            tick = tick + 1
        end
        count = count + 1
        return tick, count
    end
end

--Tick handler, handles executing from the queue
Queue.execute = function(event, queue)
    if queue[event.tick] then
        for _, data in ipairs(queue[event.tick]) do
            queue._hash[cantorPair_v7(data.position)] = nil
            if Queue[data.action] then Queue[data.action](data) end
            Queue.execute(queue, data)
        end
        queue[event.tick] = nil
    end
end

return Queue
