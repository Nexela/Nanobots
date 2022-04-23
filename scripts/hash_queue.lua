--- @param pos MapPosition
local function cantor_position(pos)
    local x, y = math.floor(pos.x), math.floor(pos.y)
    x, y = (x >= 0 and x or (-0.5 - x)), (y >= 0 and y or (-0.5 - y))
    local s = x + y
    local h = s * (s + 0.5) + x
    return h + h
end

--- @class Nanobots.queue
--- @field hash_count uint
--- @field hash_map {[uint]: Nanobots.action_data}
--- @field tick_count uint
--- @field tick_map table<uint, Nanobots.action_data[]>
local Queue = {}
local Actions = require('scripts/actions')

--- @param entity LuaEntity
--- @return uint, Nanobots.action_data
function Queue:get_hash(entity)
    local index = entity.unit_number or cantor_position(entity.position)
    local hashed = self.hash_map[index]
    return index, hashed
end

--- @param entity LuaEntity
--- @return boolean
function Queue:is_hashed(entity)
    return self.hash_map[self:get_hash(entity)] and true
end

--- @param data Nanobots.action_data
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

--- @param start_tick? uint
--- @param tick_spacing? uint
--- @param actions_per_group? uint
function Queue:get_counters(start_tick, tick_spacing, actions_per_group)
    start_tick = start_tick or 0
    tick_spacing = tick_spacing or 1
    actions_per_group = actions_per_group or 1

    local tick = ((start_tick >= game.tick and start_tick) or game.tick) + tick_spacing
    local last_tick = tick

    local count = 0
    local num_groups = 0
    local group_count = actions_per_group

    --- @param dont_combine? boolean
    --- @param get_last_tick? boolean
    --- @return uint, uint
    local get_next_tick = function(dont_combine, get_last_tick)
        if get_last_tick then return last_tick, count end

        last_tick = tick
        count = count + 1
        -- Find the next unused tick if we don't want to combine
        while dont_combine and self.tick_map[tick] do
            tick = tick + 1
            group_count = actions_per_group
        end

        if group_count > 0 then
            group_count = group_count - 1
            return tick, count
        end

        group_count = actions_per_group - 1
        num_groups = num_groups + 1
        tick = tick + tick_spacing
        return tick, count
    end

    return get_next_tick
end

--- @param event on_tick
function Queue:execute(event)
    local array = self.tick_map[event.tick]
    if array then
        for _, data in ipairs(array) do
            Actions[data.action](data)
            self.hash_map[data.hash_id] = nil
            self.hash_count = self.hash_count - 1
            self.tick_count = self.tick_count - 1
        end
        self.tick_map[event.tick] = nil
    end
    return self
end

local function __len(self)
    return self.hash_count
end
local queue_mt = { __index = Queue, __len = __len }

--- @param queue? Nanobots.queue
--- @return Nanobots.queue
local function new(queue)
    if not queue then
        queue = { tick_count = 0, hash_count = 0, tick_map = {}, hash_map = {} }
    else
        assert(queue.hash_count and queue.hash_map and queue.tick_map and queue.tick_count, 'Invalid queue object')
        if table_size(queue.tick_map) ~= queue.tick_count or table_size(queue.hash_map) ~= queue.hash_count then
            game.print('Nanobots has encountered a discrepency')
        end
    end
    return setmetatable(queue, queue_mt)
end

return new
