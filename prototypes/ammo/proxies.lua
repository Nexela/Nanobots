local Data = require("stdlib/data/data")
local constants = require("constants")
local TTL = 60 * 10

local proxy = {
    type = "combat-robot",
    name = "nano-proxy-health",
    icon = "__core__/graphics/shoot.png",
    icon_size = 32,
    selectable_in_game = false,
    max_health = 20,
    alert_when_damaged = false,
    distance_per_frame = 0.0,
    time_to_live = TTL,
    speed = 0,
    destroy_action = nil,
    resistances =
    {
        {
            type = "poison",
            percent = 100
        }
    },
    attack_parameters = {
        type = "beam",
        ammo_category = "combat-robot-beam",
        warmup = TTL,
        cooldown = TTL,
        range = 0,
        ammo_type =
        {
            category = "combat-robot-beam",
            action = nil,
        }
    },
    idle = Data.empty_animation(),
    shadow_idle = Data.empty_animation(),
    in_motion = Data.empty_animation(),
    shadow_in_motion = Data.empty_animation(),
}

local projectile_return = {
    type = "projectile",
    name = "nano-projectile-return",
    flags = {"not-on-map"},
    acceleration =0.005,
    direction_only = false,
    action = nil,
    final_action = nil,
    animation = constants.projectile_animation,
}

data:extend({proxy, projectile_return})
