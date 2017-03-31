-------------------------------------------------------------------------------
--[[Queue]]
-------------------------------------------------------------------------------

local max = math.max
local queue_speed = MOD.config.QUEUE_SPEED_BONUS

local Queue = {}

function Queue.insert(tick, data)
    local queued = global.queued[tick] or {}
    queued[#queued + 1] = data
    global.queued[tick] = queued
end

function Queue.next(tick, force_name)
    return function()
        tick = tick + max(1, global.config.ticks_per_queue - queue_speed[game.forces[force_name].get_gun_speed_modifier("nano-ammo")])
        return tick
    end
end

return Queue
