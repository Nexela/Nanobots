local recipe = {
    type = "recipe",
    name = "ammo-nano-deconstructors",
    enabled = false,
    energy_required = 5,
    ingredients =
    {
      {"ammo-nano-constructors", 1},
      {"ammo-nano-scrappers", 1},
      {"advanced-circuit", 1}
    },
    result = "ammo-nano-deconstructors"
  }

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

data:extend({recipe, deconstructors})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-deconstructors"}
