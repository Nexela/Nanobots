-------------------------------------------------------------------------------
--[[Roboport Interface]]-- Logistic Network roboport interface module
-------------------------------------------------------------------------------
--Roboport with custom GFX no zones, no recharge, radar with nil gfx, cc with nil gfx - selectable

local recipe_ri = Proto.dupli_proto("recipe", "radar", "roboport-interface")
recipe_ri.energy_required = 30
recipe_ri.enabled = false
recipe_ri.ingredients = {
    {"constant-combinator", 1},
    {"roboport", 1},
    {"radar", 1},
}

--Frame 153, 131
local item_ri = Proto.dupli_proto("item", "radar", "roboport-interface")
local sort_order = data.raw["item"]["roboport"] and data.raw["item"]["roboport"].sort_order or ""
item_ri.subgroup = "logistic-network"
item_ri.sort_order = sort_order .. "-interface"

--Create entity
local ri = Proto.dupli_proto( "constant-combinator", "constant-combinator", "roboport-interface-cc", false )
ri.item_slot_count = 5
--ri.minable.result = "roboport-interface"
ri.minable = nil
--ri.selection_box = {{-1.5, -2.5}, {1.5, 0.5}}
ri.selection_box = {{-1.00, -0.05}, {0.5, 0.5}}
ri.order = "zzzzz"
ri.sprites.north=Proto.empty_sprite
ri.sprites.east=Proto.empty_sprite
ri.sprites.south=Proto.empty_sprite
ri.sprites.west=Proto.empty_sprite
--face direction south.

local ri_radar = Proto.dupli_proto("radar", "radar", "roboport-interface", "roboport-interface")
ri_radar.selection_box = {{-1, -1}, {1, 0.5}}
ri_radar.collision_box = {{-0.8, -0.8}, {0.8, 0.8}}
--ri_radar.selection_box = nil
--ri_radar.minable = nil
--ri_radar.selectable_in_game = false
ri_radar.pictures.filename = "__Nanobots__/graphics/entity/roboport-interface/roboport-interface.png"
ri_radar.pictures.shift = {0.55, -0.25}
ri_radar.pictures.scale = .666666
ri_radar.max_distance_of_sector_revealed = 0
ri_radar.max_distance_of_nearby_sector_revealed = 1
ri_radar.energy_per_sector = "3MJ"
ri_radar.energy_per_nearby_scan = "250kJ"
ri_radar.energy_usage = "300kW"

--Insert into technology
local tech = data.raw.technology["construction-robotics"]
tech.effects[#tech.effects+1] = {type = "unlock-recipe", recipe = "roboport-interface"}

data:extend{recipe_ri, item_ri, ri, ri_radar}
