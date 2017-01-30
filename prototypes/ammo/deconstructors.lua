local constants = require("constants")

local recipe = {
    type = "recipe",
    name = "ammo-nano-deconstructors",
    enabled = false,
    energy_required = 5,
    ingredients =
    {
        {"ammo-nano-constructors", 1},
        {"ammo-nano-scrappers", 1},
        {"electronic-circuit", 1}
    },
    result = "ammo-nano-deconstructors"
}

-------------------------------------------------------------------------------
local deconstructors = {
    type = "ammo",
    name = "ammo-nano-deconstructors",
    icon = "__Nanobots__/graphics/icons/nano-ammo-deconstructors.png",
    flags = {"goes-to-main-inventory"},
    magazine_size = 20,
    subgroup = "tool",
    order = "c[automated-construction]-g[gun-nano-emitter]-deconstructors",
    stack_size = 100,
    ammo_type =
    {
        category = "nano-ammo",
        target_type = "position",
        action =
        {
            type = "direct",
            action_delivery =
            {
                type = "instant",
                target_effects =
                {
                    {
                        type = "create-entity",
                        entity_name = "nano-cloud-big-deconstructors",
                        trigger_created_entity=true
                    },
                }
            }
        }
    },
}

-------------------------------------------------------------------------------
local projectile_deconstructors ={
    type = "projectile",
    name = "nano-projectile-deconstructors",
    flags = {"not-on-map"},
    acceleration = -0.005,
    direction_only = false,
    animation = constants.projectile_animation,
    final_action =
    {
        type = "direct",
        action_delivery =
        {
            type = "instant",
            target_effects =
            {
                {
                    type = "create-entity",
                    entity_name = "nano-cloud-small-deconstructors",
                    check_buildability = false
                },
            }
        }
    },
}

local cloud_big_deconstructors = {
    type = "smoke-with-trigger",
    name = "nano-cloud-big-deconstructors",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    animation = constants.cloud_animation(4),
    slow_down_factor = 0,
    affected_by_wind = false,
    cyclic = true,
    duration = 60*2,
    fade_away_duration = 60,
    spread_duration = 10,
    color = Color.set(defines.colors.yellow, .35),
    action_frequency = 120,
    action = nil,
}

local cloud_small_deconstructors = {
    type = "smoke-with-trigger",
    name = "nano-cloud-small-deconstructors",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    animation = constants.cloud_animation(.4),
    slow_down_factor = 0,
    affected_by_wind = false,
    cyclic = true,
    duration = 60*2,
    fade_away_duration = 60,
    spread_duration = 10,
    color = Color.set(defines.colors.yellow, .35),
    action_frequency = 120,
    action = {
        type = "direct",
        action_delivery =
        {
            type = "instant",
            target_effects =
            {
                {
                    type = "create-explosion",
                    entity_name = "nano-sound-deconstruct",
                },
            }
        }
    },
}

-------------------------------------------------------------------------------
data:extend({recipe, deconstructors, projectile_deconstructors, cloud_big_deconstructors, cloud_small_deconstructors})

local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-deconstructors"}
