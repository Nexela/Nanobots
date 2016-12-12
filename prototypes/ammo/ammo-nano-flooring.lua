local recipe = {
    type = "recipe",
    name = "ammo-nano-flooring",
    enabled = false,
    energy_required = 5,
    ingredients =
    {
      {"iron-plate", 5},
      {"electronic-circuit", 1}
    },
    result = "ammo-nano-flooring"
  }

local flooring = {
  type = "ammo",
  name = "ammo-nano-flooring",
  icon = "__Nanobots__/graphics/icons/nano-ammo-flooring.png",
  flags = {"goes-to-main-inventory"},
  magazine_size = 20,
  subgroup = "tool",
  order = "c[automated-construction]-g[gun-nano-emitter]-flooring",
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

data:extend({recipe, flooring})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-flooring"}
