local EAC = require("config")

--Quick to use empty sprite
local empty_sprite ={
  filename = "__core__/graphics/empty.png",
  priority = "extra-high",
  width = 1,
  height = 1
}

--Quick to use empty animation
local empty_animation = {
  filename = empty_sprite.filename,
  width = empty_sprite.width,
  height = empty_sprite.height,
  line_length = 1,
  frame_count = 1,
  shift = { -0.5, 0.5},
  animation_speed = 0
}

local recipe_builder = {
  type = "recipe",
  name = "blueprint-builder",
  enabled = false,
  ingredients =
  {
    {"electronic-circuit", 1}
  },
  result = "blueprint-builder",
  energy_required = 10
}

local item_builder = {
  type = "item",
  name = "blueprint-builder",
  icon = "__Nanobots__/graphics/icons/blueprint-builder.png",
  flags = {"goes-to-quickbar"},
  subgroup = "tool",
  order = "c[automated-construction]-a[blueprint-builder]",
  place_result = "blueprint-builder",
  --place_result = nil,
  stack_size = 1
}

local builder = {
  type = "roboport",
  name = "blueprint-builder",
  icon = "__Nanobots__/graphics/icons/blueprint-builder.png",
  flags = {"placeable-player", "player-creation"},
  minable = nil,
  max_health = 0,
  corpse = "big-remnants",
  --collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
  selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
  dying_explosion = "medium-explosion",
  energy_source =
  {
    type = "electric",
    usage_priority = "secondary-input",
    input_flow_limit = "1W",
    buffer_capacity = "1W"
  },
  recharge_minimum = "0W",
  energy_usage = "0W",
  -- per one charge slot
  charging_energy = "0MW",
  logistics_radius = 0,
  construction_radius = EAC.BUILD_RADIUS,
  charge_approach_distance = 0,
  robot_slots_count = 0,
  material_slots_count = 0,
  base =
  {
    filename = "__Nanobots__/graphics/entity/blueprint-builder.png",
    width = 32,
    height = 32,
    shift = {0.0, 0.0}
  },
  base_patch = empty_sprite,
  base_animation = empty_animation,
  door_animation_up = empty_animation,
  door_animation_down = empty_animation ,
  recharging_animation = empty_animation,
  vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.0 },
  working_sound =
  {
    sound = { filename = "__base__/sound/roboport-working.ogg", volume = 0.0 },
    max_sounds_per_type = 3,
    audible_distance_modifier = 0.5,
    probability = 1 / (5 * 60) -- average pause between the sound is 5 seconds
  },
  recharging_light = {intensity = 0.4, size = 5},
  request_to_open_door_timeout = 15,
  spawn_and_station_height = -0.1,

  draw_logistic_radius_visualization = false,
  draw_construction_radius_visualization = true,

  open_door_trigger_effect =
  {
    {
      type = "play-sound",
      sound = { filename = "__base__/sound/roboport-door.ogg", volume = 0.0 }
    },
  },
  close_door_trigger_effect =
  {
    {
      type = "play-sound",
      sound = { filename = "__base__/sound/roboport-door.ogg", volume = 0.0 }
    },
  },

}

if not EAC.AUTO_BUILD or EAC.TICK_MOD == 0 then
  data:extend({recipe_builder, item_builder, builder})
  local effects = data.raw.technology["automation"].effects
  effects[#effects + 1] = {type = "unlock-recipe", recipe="blueprint-builder"}
end
