---@meta
---@class LuaSurface
local LuaSurface = {
    ---Get the tile at a given position.
    ---
    ---**Note:** The input position params can also be a single tile position.
    ---
    ---[View documentation](https://lua-api.factorio.com/latest/LuaSurface.html#LuaSurface.get_tile)
    ---@param x int
    ---@param y int
    ---@return LuaTile
    ---@overload fun(position: TilePosition): LuaTile
    get_tile = function(x, y) end,
}
