serpent = require ("serpent")
local function pixel_to_bounds(width, height, tile_size)
  tile_size = tile_size or 32
  --width, height = 171, 185
  local area ={top_left = {x = 0, y = 0}, bottom_right = {x = 0, y = 0}}

  area.top_left.x = -(width - (width/2)) / tile_size
  area.top_left.y = -(height - (height/2)) / tile_size
  area.bottom_right.x = (width - (width/2)) / tile_size
  area.bottom_right.y = (height - (height/2)) / tile_size
  return area
end

  --print(serpent.line(pixel_to_bounds(171,185), {comment=false}))
  print(serpent.line(pixel_to_bounds(153,153), {comment=false}))
