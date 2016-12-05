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
  icon = "__Nanobots__/graphics/icons/nano-ammo.png",
  flags = {"goes-to-main-inventory"},
  magazine_size = 20,
  subgroup = "tool",
  order = "c[automated-construction]-g[gun-nano-emitter]-constructor",
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

data:extend({recipe, constructors})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-constructors"}
