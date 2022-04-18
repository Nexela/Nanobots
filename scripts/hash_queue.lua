--- @param pos MapPosition
local function cantor_position(pos)
    local x, y = math.floor(pos.x), math.floor(pos.y)
    x, y = (x >= 0 and x or (-0.5 - x)), (y >= 0 and y or (-0.5 - y))
    local s = x + y
    local h = s * (s + 0.5) + x
    return h + h
end

local Queue = {}
local Actions = require('scripts/actions')

--- @param entity LuaEntity
function Queue:get_hash(entity)
    local index = entity.unit_number or cantor_position(entity.position)
    local hashed = self.hash_map[index]
    return index, hashed
end

--- @param entity LuaEntity
function Queue:is_hashed(entity)
    return self.hash_map[self:get_hash(entity)] and true
end

--- @param data Nanobots.data
--- @param tick uint
function Queue:insert(data, tick)
    data.on_tick = tick or (game.tick + 1)

    self.tick_map[tick] = self.tick_map[tick] or {}
    self.tick_map[tick][#self.tick_map[tick] + 1] = data
    self.tick_count = self.tick_count + 1

    data.hash_id = self:get_hash(data.entity)
    self.hash_map[data.hash_id] = data
    self.hash_count = self.hash_count + 1
    return self
end

--- @param next_tick? uint
--- @param tick_spacing? uint
--- @param dont_combine? boolean
--- @return fun(dont_combine: boolean):uint, uint
--- @return fun(num:uint):uint
function Queue:get_counters(next_tick, tick_spacing, dont_combine)
    local tick = (next_tick and next_tick >= game.tick and next_tick) or game.tick
    tick_spacing = tick_spacing or 1
    local count = 0

    --- @param really_dont_combine boolean
    --- @return uint, uint
    local get_next_tick = function(really_dont_combine)
        tick = tick + tick_spacing
        while (dont_combine or really_dont_combine) and self.tick_map[tick] do tick = tick + 1 end
        count = count + 1
        return tick, count
    end

    --- @param num uint
    --- @return uint
    local queue_counter = function(num)
        count = count + (num or 0)
        return count
    end

    return get_next_tick, queue_counter
end

--- @param event on_tick
function Queue:execute(event)
    if self.tick_map[event.tick] then
        for _, data in ipairs(self.tick_map[event.tick]) do
            Actions[data.action](data)
            self.hash_map[data.hash_id] = nil
            self.hash_count = self.hash_count - 1
            self.tick_count = self.tick_count - 1
        end
        self.tick_map[event.tick] = nil
    end
    return self
end

--- @class Nanobots.data
--- @field on_tick uint
--- @field action string
--- @field hash_id uint
--- @field entity LuaEntity

--- @class Nanobots.queue
--- @field hash_count int
--- @field hash_map {[uint]: Nanobots.action_data}
--- @field tick_count int
--- @field tick_map {[uint]: Nanobots.action_data[]}

local function __len(self)
    return self.hash_count
end
local queue_mt = { __index = Queue, __len = __len }

--- @param queue Nanobots.queue
local function new(queue)
    if not queue then
        queue = { tick_count = 0, hash_count = 0, tick_map = {}, hash_map = {} }
    else
        assert(queue.hash_count and queue.hash_map and queue.tick_map and queue.tick_count, 'Invalid queue object')
        if table_size(queue.tick_map) ~= queue.tick_count or table_size(queue.hash_map) ~= queue.hash_count then
            game.print('Nanotbots have encountered a discrepency')
        end
    end
    return setmetatable(queue, queue_mt)
end

return new
