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

data:extend({recipe, scrappers})
local effects = data.raw.technology["automated-construction"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="ammo-nano-scrappers"}
