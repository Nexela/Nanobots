local recipe_chip = {
    type = "recipe",
    name = "belt-immunity-equipment",
    enabled = false,
    energy_required = 10,
    ingredients =
    {
        {"processing-unit", 1},
        {"battery", 1},
        --bobmods add construction brain
        {"fast-transport-belt", 10}
    },
    result = "belt-immunity-equipment"
}
data.raw.item["belt-immunity-equipment"].flags = {"goes-to-main-inventory"}
data.raw.item["belt-immunity-equipment"].order = "e[robotics]-al[personal-roboport-equipment]"
data.raw["belt-immunity-equipment"]["belt-immunity-equipment"].order = nil

data:extend{recipe_chip}

local effects = data.raw.technology["personal-roboport-equipment"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="belt-immunity-equipment"}
