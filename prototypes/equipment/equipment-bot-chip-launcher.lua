local Data = require("__stdlib__/stdlib/data/data")
local make_shortcut = require("prototypes/equipment/make_shortcut")

Data {
    type = "recipe",
    name = "equipment-bot-chip-launcher",
    enabled = false,
    energy_required = 10,
    ingredients = {
        { "processing-unit", 1 },
        { "battery", 1 }
        --bobmods add combat brain
    },
    result = "equipment-bot-chip-launcher"
}

Data {
    type = "item",
    name = "equipment-bot-chip-launcher",
    icon = "__Nanobots__/graphics/icons/equipment-bot-chip-launcher.png",
    icon_size = 64,
    placed_as_equipment_result = "equipment-bot-chip-launcher",
    subgroup = "equipment",
    order = "e[robotics]-ac[personal-roboport-equipment]",
    stack_size = 20
}

local equipment_chip =
Data {
    type = "active-defense-equipment",
    name = "equipment-bot-chip-launcher",
    take_result = "equipment-bot-chip-launcher",
    sprite = {
        filename = "__Nanobots__/graphics/equipment/equipment-bot-chip-launcher.png",
        width = 64,
        height = 64,
        priority = "medium",
        scale = 0.5
    },
    shape = {
        width = 1,
        height = 1,
        type = "full"
    },
    energy_source = {
        type = "electric",
        usage_priority = "secondary-input",
        buffer_capacity = "1kJ",
        input_flow_limit = "750W",
        drain = "50W"
    },
    attack_parameters = {
        type = "projectile",
        ammo_category = "nano-ammo",
        damage_modifier = 0,
        cooldown = 0,
        projectile_center = { 0, 0 },
        projectile_creation_distance = 0.6,
        range = 0,
        ammo_type = {
            type = "projectile",
            category = "electric",
            energy_consumption = "500W",
            action = {
                {
                    type = "area",
                    radius = 50,
                    force = "enemy",
                    action_delivery = nil
                }
            }
        }
    },
    automatic = false,
    categories = { "armor" }
}

make_shortcut(equipment_chip)

local effects = data.raw.technology["personal-roboport-equipment"].effects
effects[#effects + 1] = { type = "unlock-recipe", recipe = "equipment-bot-chip-launcher" }
