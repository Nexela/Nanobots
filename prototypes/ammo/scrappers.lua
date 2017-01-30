local constants = require("constants")

local recipe = {
    type = "recipe",
    name = "ammo-nano-scrappers",
    enabled = false,
    energy_required = 5,
    ingredients =
    {
        {"iron-axe", 1},
        {"electronic-circuit", 1},
        {"copper-wire", 2}
    },
    result = "ammo-nano-scrappers"
}

-------------------------------------------------------------------------------
local scrappers = {
    type = "ammo",
    name = "ammo-nano-scrappers",
    icon = "__Nanobots__/graphics/icons/nano-ammo-scrappers.png",
    flags = {"goes-to-main-inventory"},
    magazine_size = 20,
    subgroup = "tool",
    order = "c[automated-construction]-g[gun-nano-emitter]-scrappers",
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
                        entity_name = "nano-cloud-big-scrappers",
                        trigger_created_entity=true
                    },
                }
            }
        }
    },
}

-------------------------------------------------------------------------------
local projectile_scrappers ={
    type = "projectile",
    name = "nano-projectile-scrappers",
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
                    entity_name = "nano-cloud-small-scrappers",
                    check_buildability = false
                },
            }
        }
    },
}

local cloud_big_scrappers = {
    type = "smoke-with-trigger",
    name = "nano-cloud-big-scrappers",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    animation = constants.cloud_animation(4),
    slow_down_factor = 0,
    affected_by_wind = false,
    cyclic = true,
    duration = 60*2,
    fade_away_duration = 60,
    spread_duration = 10,
    color = Color.set(defines.colors.lightred, .35),
    action_frequency = 120,
    action = nil,
}

local cloud_small_scrappers = {
    type = "smoke-with-trigger",
    name = "nano-cloud-small-scrappers",
    flags = {"not-on-map"},
    show_when_smoke_off = true,
    animation = constants.cloud_animation(.4),
    slow_down_factor = 0,
    affected_by_wind = false,
    cyclic = true,
    duration = 60*2,
    fade_away_duration = 60,
    spread_duration = 10,
    color = Color.set(defines.colors.lightred, .35),
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
data:extend({recipe, scrappers, cloud_big_scrappers, cloud_small_scrappers, projectile_scrappers})

local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-scrappers"}
