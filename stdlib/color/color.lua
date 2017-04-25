--- Color module
-- @module Color

require 'stdlib/color/defines'

local Color = {}

function Color.set(color, alpha)
    color = color or defines.colors.white
    color.a = alpha or 1
    return color
end

return Color
