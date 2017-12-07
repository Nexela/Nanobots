local recipe_chip = {
    type = "recipe",
    name = "equipment-bot-chip-launcher",
    enabled = false,
    energy_required = 10,
    ingredients =
    {
        {"processing-unit", 1},
        {"battery", 1},
        --bobmods add combat brain
    },
    result = "equipment-bot-chip-launcher"
}

local item_chip = {
    type = "item",
    name = "equipment-bot-chip-launcher",
    icon = "__Nanobots__/graphics/icons/equipment-bot-chip-launcher.png",
    icon_size = 32,
    placed_as_equipment_result = "equipment-bot-chip-launcher",
    flags = {"goes-to-main-inventory"},
    subgroup = "equipment",
    order = "e[robotics]-ac[personal-roboport-equipment]",
    stack_size = 20
}

local equipment_chip = {
    type = "active-defense-equipment",
    name = "equipment-bot-chip-launcher",
    take_result = "equipment-bot-chip-launcher",
    ability_icon =
    {
        filename = "__base__/graphics/equipment/discharge-defense-equipment-ability.png",
        width = 32,
        height = 32,
        priority = "medium"
    },
    sprite =
    {
        filename = "__Nanobots__/graphics/equipment/equipment-bot-chip-launcher.png",
        width = 32,
        height = 32,
        priority = "medium"
    },
    shape =
    {
        width = 1,
        height = 1,
        type = "full"
    },
    energy_source =
    {
        type = "electric",
        usage_priority = "secondary-input",
        buffer_capacity = "1kJ",
        input_flow_limit = "750W",
        drain = "50W"
    },
    attack_parameters =
    {
        type = "projectile",
        ammo_category = "nano-ammo",
        damage_modifier = 0,
        cooldown = 0,
        projectile_center = {0, 0},
        projectile_creation_distance = 0.6,
        range = 0,
        ammo_type =
        {
            type = "projectile",
            category = "electric",
            energy_consumption = "500W",
            speed = 1,
            action =
            {
                {
                    type = "area",
                    radius = 50,
                    force = "enemy",
                    action_delivery = nil,
                }
            }
        },
    },
    automatic = false,
    categories = {"armor"}
}

local disabled = table.deepcopy(equipment_chip)
--Keep the same localised name if none is specified
disabled.localised_name = {"equipment-hotkeys.disabled-eq", disabled.localised_name or {"equipment-name."..disabled.name}}
disabled.name = "nano-disabled-" .. disabled.name

local effects = data.raw.technology["personal-roboport-equipment"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="equipment-bot-chip-launcher"}

data:extend({item_chip, recipe_chip, equipment_chip, disabled})
