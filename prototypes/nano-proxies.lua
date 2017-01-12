local nano_proxy = {
  type = "combat-robot",
  name = "nano-proxy-health",
  icon = "__core__/graphics/shoot.png",
  selectable_in_game = false,
  max_health = 20,
  alert_when_damaged = false,
  distance_per_frame = 0.0,
  time_to_live = 60,
  speed = 0,
  destroy_action = nil,
  attack_parameters = {
    type = "beam",
    ammo_category = "combat-robot-beam",
    warmup = 200,
    cooldown = 200,
    range = 0,
    ammo_type =
    {
      category = "combat-robot-beam",
      action = nil,
    }
  },
  idle = Proto.empty_animation,
  shadow_idle = Proto.empty_animation,
  in_motion = Proto.empty_animation,
  shadow_in_motion = Proto.empty_animation,

}

data:extend({nano_proxy})
