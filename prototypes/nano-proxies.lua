-- local target_proxy_ttl = table.deepcopy(data.raw.corpse["small-remnants"])
-- target_proxy_ttl.icon = "__core__/graphics/shoot.png"
-- target_proxy_ttl.name = "nano-target-proxy-ttl"
-- target_proxy_ttl.selection_box = nil
-- target_proxy_ttl.time_before_removed = 60
-- target_proxy_ttl.final_render_layer = "remnants"
-- target_proxy_ttl.animation = Proto.empty_animation
--
-- local target_proxy = {
--   icon = "__core__/graphics/shoot.png",
--   type = "simple-entity",
--   name = "nano-target-proxy",
--   flags = {"placeable-off-grid", "not-on-map"},
--   selectable_in_game = false,
--   order = "b[decorative]-k[stone-rock]-a[big]",
--   render_layer = "object",
--   max_health = 1,
--   picture = Proto.empty_sprite
-- }

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
