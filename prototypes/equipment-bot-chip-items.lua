local recipe_chip = {
    type = "recipe",
    name = "equipment-bot-chip-items",
    enabled = true,
    energy_required = 10,
    ingredients =
    {
      {"processing-unit", 5},
      {"steel-plate", 20},
      {"laser-turret", 10}
    },
    result = "equipment-bot-chip-items"
  }

local item_chip =   {
    type = "item",
    name = "equipment-bot-chip-items",
    icon = "__base__/graphics/icons/discharge-defense-equipment.png",
    placed_as_equipment_result = "equipment-bot-chip-items",
    flags = {"goes-to-main-inventory"},
    subgroup = "equipment",
    order = "d[active-defense]-b[discharge-defense-equipment]",
    stack_size = 20
  }

local equipment_chip =   {
    type = "active-defense-equipment",
    name = "equipment-bot-chip-items",
    ability_icon =
    {
      filename = "__base__/graphics/equipment/discharge-defense-equipment-ability.png",
      width = 32,
      height = 32,
      priority = "medium"
    },
    sprite =
    {
      filename = "__base__/graphics/equipment/discharge-defense-equipment.png",
      width = 96,
      height = 96,
      priority = "medium"
    },
    shape =
    {
      width = 3,
      height = 3,
      type = "full"
    },
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
      buffer_capacity = "1kJ"
    },
    attack_parameters =
    {
      type = "projectile",
      ammo_category = "electric",
      damage_modifier = 0,
      cooldown = 0,
      projectile_center = {0, 0},
      projectile_creation_distance = 0.6,
      range = 0,
      --sound = _G.make_laser_sounds(),
      ammo_type =
      {
        type = "projectile",
        category = "electric",
        energy_consumption = "500W",
        speed = 1,
        action =
        {
          {
            type = "area",
            perimeter = 10,
            force = "enemy",
            action_delivery =
            {
              {
                type = "projectile",
                projectile = "blue-laser",
                starting_speed = 0.28
              }
            }
          }
        }
      },
    },
    automatic = false,
    categories = {"armor"}
  }

  data:extend({item_chip, recipe_chip, equipment_chip})
