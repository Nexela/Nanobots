local recipe = {
  type = "recipe",
  name = "ammo-nano-scrappers",
  enabled = false,
  energy_required = 5,
  ingredients =
  {
    {"steel-axe", 1},
    {"electronic-circuit", 1}
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
local color = defines.colors.lightred
color.a = .025

--cloud-big is for the gun, cloud-small is for the individual item.
local cloud_big = {
  type = "smoke-with-trigger",
  name = "nano-cloud-big-scrappers",
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
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      source_effects = {
        {
          type = "play-sound",
          sound = {
            filename = "__Nanobots__/sounds/robostep.ogg",
            volume = 0.25
          },
        },
      },
    }
  },
  action_frequency = 120
}

-------------------------------------------------------------------------------
local cloud_small=table.deepcopy(cloud_big)
cloud_small.name = "nano-cloud-small-scrappers"
cloud_small.animation.scale = 0.4
cloud_small.action = nil

-------------------------------------------------------------------------------
local nano_beam = table.deepcopy(data.raw["beam"]["electric-beam"])
nano_beam.name = "nano-beam-scrappers"
nano_beam.working_sound = nil
nano_beam.duration=10
nano_beam.action_frequency = 20
nano_beam.action =
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
        trigger_created_entity=false
      },
    }
  }
}

-------------------------------------------------------------------------------
data:extend({recipe, scrappers, cloud_big, cloud_small, nano_beam})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-scrappers"}
