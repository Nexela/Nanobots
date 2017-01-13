local recipe = {
  type = "recipe",
  name = "ammo-nano-constructors",
  enabled = false,
  energy_required = 5,
  ingredients =
  {
    {"copper-plate", 5},
    {"electronic-circuit", 1},
    {"repair-pack", 1}
  },
  result = "ammo-nano-constructors"
}

-------------------------------------------------------------------------------
local constructors = {
  type = "ammo",
  name = "ammo-nano-constructors",
  icon="__Nanobots__/graphics/icons/nano-ammo-constructors.png",
  flags = {"goes-to-main-inventory"},
  magazine_size = 10,
  subgroup = "tool",
  order = "c[automated-construction]-g[gun-nano-emitter]-constructors",
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
            entity_name = "nano-cloud-big-constructors",
            trigger_created_entity=true
          },
        }
      }
    }
  },
}

-------------------------------------------------------------------------------
local color = defines.colors.lightblue
color.a = .025
--cloud-big is for the gun, cloud-small is for the individual item.

local cloud_big = {
  type = "smoke-with-trigger",
  name = "nano-cloud-big-constructors",
  flags = {"not-on-map"},
  show_when_smoke_off = true,
  animation =
  {
    filename = "__base__/graphics/entity/cloud/cloud-45-frames.png",
    flags = { "compressed" },
    priority = "low",
    width = 256,
    height = 256,
    frame_count = 45,
    animation_speed = 0.5,
    line_length = 7,
    scale = 4,
  },
  slow_down_factor = 0,
  affected_by_wind = false,
  cyclic = true,
  duration = 60*2,
  fade_away_duration = 60,
  spread_duration = 10,
  color = color,
  action = nil,
}

-------------------------------------------------------------------------------
local nano_beam_constructors = table.deepcopy(data.raw["beam"]["electric-beam"])
nano_beam_constructors.name = "nano-beam-constructors"
nano_beam_constructors.working_sound = nil
nano_beam_constructors.duration=10
nano_beam_constructors.action_frequency = 20
nano_beam_constructors.action =
{
  type = "direct",
  action_delivery =
  {
    type = "instant",
    target_effects =
    {
      {
        type = "create-entity",
        entity_name = "nano-cloud-small-constructors",
        trigger_created_entity=false
      },
    }
  }
}

-------------------------------------------------------------------------------
local nano_beam_healers = table.deepcopy(nano_beam_constructors)
nano_beam_healers.name = "nano-beam-healers"
nano_beam_healers.action =
{
  type = "direct",
  action_delivery =
  {
    type = "instant",
    target_effects =
    {
      {
        type = "create-entity",
        entity_name = "nano-cloud-small-repair",
        trigger_created_entity=false
      },
      -- {
      -- type = "create-entity",
      -- entity_name = "nano-target-proxy-ttl",
      -- },
    }
  }
}

-------------------------------------------------------------------------------
--return item projectiles
local cloud_projectile = table.deepcopy(data.raw["projectile"]["poison-capsule"])
cloud_projectile.name = "nano-projectile-constructors"
cloud_projectile.smoke = nil
cloud_projectile.action = nil
cloud_projectile.animation.scale = .30
cloud_projectile.shadow.scale = .30

-------------------------------------------------------------------------------
local cloud_small=table.deepcopy(cloud_big)
cloud_small.name = "nano-cloud-small-constructors"
cloud_small.action = nil
cloud_small.animation.scale = 0.4

-------------------------------------------------------------------------------
local repair_color = defines.colors.darkblue
repair_color.a = 0.25

local cloud_small_repair = table.deepcopy(cloud_small)
cloud_small_repair.name = "nano-cloud-small-repair"
cloud_small_repair.duration = 200
cloud_small_repair.fade_away_duration = 2*60
cloud_small_repair.spread_duration = 10
cloud_small_repair.color = repair_color
cloud_small_repair.action_frequency = 1
cloud_small_repair.action = {
  type = "direct",
  action_delivery =
  {
    type = "instant",
    target_effects =
    {
      type = "nested-result",
      action = {
        {
          type = "area",
          perimeter = 0.75,
          force="ally",
          entity_flags = {"player-creation"},
          action_delivery =
          {
            type = "instant",
            target_effects =
            {
              type = "damage",
              damage = { amount = -1, type = "physical"},
              --repeat_count = 1
            }
          }
        }
      }
    }
  }
}
--data.raw["furnace"]["stone-furnace"].max_health = 50000

-------------------------------------------------------------------------------
data:extend({recipe, constructors, cloud_big, cloud_small, cloud_small_repair, cloud_projectile, nano_beam_constructors, nano_beam_healers})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-constructors"}
