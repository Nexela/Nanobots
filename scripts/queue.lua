-------------------------------------------------------------------------------
--[[Queue]]
-------------------------------------------------------------------------------
local function NtoZ_c(x, y)
    return (x >= 0 and x or (-0.5 - x)), (y >= 0 and y or (-0.5 - y))
end

local function cantorPair_v7(pos)
    local x, y = NtoZ_c(math.floor(pos.x), math.floor(pos.y))
    local s = x + y
    local h = s * (s + 0.5) + x
    return h + h
end

local Queue = {}

Queue.new = function ()
    return {_hash={}}
end

Queue.set_hash = function(t, index, position, action)
    if not index then
        index=cantorPair_v7(position)
    end
    local hash = t._hash
    hash[index] = hash[index] or {}
    hash[index][action] = action
end

Queue.get_hash = function(t, index, position)
    if not index then
        index = cantorPair_v7(position)
    end
    local hash = t._hash
    return hash[index], hash
end

Queue.insert = function (t, data, tick, count)
    t[tick] = t[tick] or {}
    t[tick][#t + 1] = data
    Queue.set_hash(t, data.unit_number, data.position, data.action)
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
        local index
        for _, data in ipairs(queue[event.tick]) do
            if queue._hash[data.unit_number] then
                index = data.unit_number or cantorPair_v7(data.position)
                queue._hash[index][data.action] = nil
            end
            if Queue[data.action] then
                Queue[data.action](data)
            end
        end
        if index then queue._hash[index] = nil end
        queue[event.tick] = nil
    end
end

return Queue
