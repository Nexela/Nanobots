local recipe = {
  type = "recipe",
  name = "ammo-nano-constructors",
  enabled = false,
  energy_required = 5,
  ingredients =
  {
    {"copper-plate", 5},
    {"electronic-circuit", 1}
  },
  result = "ammo-nano-constructors"
}

local constructors = {
  type = "ammo",
  name = "ammo-nano-constructors",
  icon = "__Nanobots__/graphics/icons/nano-ammo-constructors.png",
  flags = {"goes-to-main-inventory"},
  magazine_size = 20,
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

local color = defines.colors.lightblue
color.a = .040

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

local cloud_beam = table.deepcopy(data.raw["beam"]["electric-beam"])
cloud_beam.name = "nano-cloud-beam-constructors"
cloud_beam.working_sound = nil
cloud_beam.action =
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
        trigger_created_entity=true
      },
    }
  }
}

local cloud_projectile = table.deepcopy(data.raw["projectile"]["poison-capsule"])
cloud_projectile.name = "nano-cloud-projectile-constructors"
cloud_projectile.smoke = nil
cloud_projectile.action =
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
        trigger_created_entity=true
      },
    }
  }
}
cloud_projectile.animation.scale = .40
cloud_projectile.shadow.scale = .40


local cloud_small=table.deepcopy(cloud_big)
--cloud_small.acceleration = 0.005
cloud_small.name = "nano-cloud-small-constructors"
cloud_small.action = nil
--cloud_small.animation =
cloud_small.animation.scale = 0.5

data:extend({recipe, constructors, cloud_big, cloud_small, cloud_beam, cloud_projectile})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-constructors"}
