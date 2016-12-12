local recipe = {
    type = "recipe",
    name = "ammo-nano-termites",
    enabled = false,
    energy_required = 5,
    ingredients =
    {
      {"iron-axe", 1},
      {"electronic-circuit", 1}
    },
    result = "ammo-nano-termites"
  }

local termites = {
  type = "ammo",
  name = "ammo-nano-termites",
  icon = "__Nanobots__/graphics/icons/nano-ammo-termites.png",
  flags = {"goes-to-main-inventory"},
  magazine_size = 20,
  subgroup = "tool",
  order = "c[automated-construction]-g[gun-nano-emitter]-termites",
  stack_size = 100,
  ammo_type =
  {
    category = "nano-ammo",
    action =
    {
      type = "direct",
      action_delivery =
      {
        type = "instant",
        source_effects =
        {
          type = "create-explosion",
          entity_name = "explosion-gunshot"
        },
        target_effects =
        {
          {
            type = "damage",
            damage = { amount = 0 , type = "physical"}
          }
        }
      }
    }
  },

}

data:extend({recipe, termites})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-termites"}
