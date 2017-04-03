-------------------------------------------------------------------------------
--[[Roboport Interface]]-- Logistic Network roboport interface module
-------------------------------------------------------------------------------
--create recipe
-- local recipe_ri = Proto.dupli_proto("recipe", "constant-combinator", "roboport-interface-cc")
-- recipe_ri.energy_required = 30
-- recipe_ri.enabled = false
-- recipe_ri.ingredients = {
-- {"constant-combinator", 1},
-- {"roboport", 1},
-- {"radar", 1},
-- }
--
-- --Create item
-- local item_ri = Proto.dupli_proto("item", "constant-combinator", "roboport-interface-cc")
-- local sort_order = data.raw["item"]["roboport"] and data.raw["item"]["roboport"].sort_order or ""
-- item_ri.subgroup = "logistic-network"
-- item_ri.sort_order = sort_order .. "-interface"

--Create entity
local ri = Proto.dupli_proto( "constant-combinator", "constant-combinator", "roboport-interface-cc", false )
ri.item_slot_count = 5
ri.minable = nil
--ri.collision_box = nil
ri.order = "zzzzz"
ri.sprites.north=Proto.empty_sprite
ri.sprites.east=Proto.empty_sprite
ri.sprites.south=Proto.empty_sprite
ri.sprites.west=Proto.empty_sprite
--face direction south.

local recipe_radar = Proto.dupli_proto("recipe", "radar", "roboport-interface")
recipe_radar.energy_required = 30
recipe_radar.enabled = false
recipe_radar.ingredients = {
    {"constant-combinator", 1},
    {"roboport", 1},
    {"radar", 1},
}

--Frame 153, 131
local item_radar = Proto.dupli_proto("item", "radar", "roboport-interface")
local sort_order = data.raw["item"]["roboport"] and data.raw["item"]["roboport"].sort_order or ""
item_radar.subgroup = "logistic-network"
item_radar.sort_order = sort_order .. "-interface"

local entity_radar = Proto.dupli_proto("radar", "radar", "roboport-interface", "roboport-interface")
entity_radar.selection_box = {{-1.5, -1.5}, {1.5, 1.0}}
entity_radar.pictures.filename = "__Nanobots__/graphics/entity/roboport-interface/roboport-interface.png"
entity_radar.max_distance_of_sector_revealed = 0
entity_radar.max_distance_of_nearby_sector_revealed = 0

--Insert into technology
local tech = data.raw.technology["construction-robotics"]
tech.effects[#tech.effects+1] = {type = "unlock-recipe", recipe = "roboport-interface"}

data:extend{recipe_radar, item_radar, ri, entity_radar}
