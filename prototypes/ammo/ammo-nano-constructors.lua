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
        source_effects = nil,
        target_effects =
        {
          {
            type = "create-entity",
            entity_name = "builder-cloud",
            trigger_created_entity=true
          },
          -- {
          --   type = "create-entity",
          --   entity_name = "stone-furnace"
          -- },
        }
      }
    }
  },
}

local color = defines.colors.blue
color.a = .05
local cloud = {
  type = "smoke-with-trigger",
  name = "builder-cloud",
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
    scale = 0.5,
  },
  slow_down_factor = 0,
  affected_by_wind = false,
  cyclic = true,
  duration = 60*2,
  fade_away_duration = 60,
  spread_duration = 10,
  color = color,
  action =
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
            volume = 0.75
          },
        },
      },
      target_effects =
      {
        type = "nested-result",
        action =
        {
          type = "area",
          perimeter = 11,
          entity_flags = {"breaths-air"},
          action_delivery =
          {
            type = "instant",
            target_effects = nil,
          }
        }
      }
    }
  },
  action_frequency = 60
}

data:extend({recipe, constructors, cloud})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-constructors"}
