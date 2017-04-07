--- Time module
-- @module Time

local Time = {}

--- @field the number of factorio ticks in a second
Time.SECOND = 60

--- @field the number of factorio ticks in a minute
Time.MINUTE = Time.SECOND * 60

--- @field the number of factorio ticks in an hour
Time.HOUR = Time.MINUTE * 60

--- @field the number of factorio ticks in a day
Time.DAY = Time.MINUTE * 60

--- @field the number of factorio ticks in a week
Time.WEEK = Time.DAY * 7

function Time.FormatTicksToTime( ticks )
    local seconds = ticks / 60
    local minutes = seconds / 60
    local hours = minutes / 60
    return string.format("%02d:%02d:%02d",
        math.floor(hours + 0.5),
        math.floor(minutes + 0.5) % 60,
        math.floor(seconds + 0.5) % 60)
end

return Time
