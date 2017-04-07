--- Color module
-- @module Color

require 'stdlib/color/defines'

local Color = {}

function Color.set(color, alpha)
    color = color or defines.colors.white
    if alpha then
        color.a = alpha
    end
    return color
end

return Color
