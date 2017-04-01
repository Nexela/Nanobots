-------------------------------------------------------------------------------
--[[Roboport Interface]]-- Logistic Network roboport interface module
-------------------------------------------------------------------------------
--create recipe
local recipe_ri = Proto.dupli_proto("recipe", "constant-combinator", "roboport-interface")
recipe_ri.energy_required = 30
recipe_ri.enabled = false
recipe_ri.ingredients = {
  {"constant-combinator", 1},
  {"roboport", 1},
  {"radar", 1},
}

--Create item
local item_ri = Proto.dupli_proto("item", "constant-combinator", "roboport-interface")
local sort_order = data.raw["item"]["roboport"] and data.raw["item"]["roboport"].sort_order or ""
item_ri.subgroup = "logistic-network"
item_ri.sort_order = sort_order .. "-interface"

--Create entity
local ri = Proto.dupli_proto( "constant-combinator", "constant-combinator", "roboport-interface", "roboport-interface" )
ri.item_slot_count = 5

--Insert into technology
local tech = data.raw.technology["construction-robotics"]
tech.effects[#tech.effects+1] = {type = "unlock-recipe", recipe = "roboport-interface"}

data:extend{recipe_ri, item_ri, ri}
