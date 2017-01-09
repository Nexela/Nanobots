local target_proxy_ttl = table.deepcopy(data.raw.corpse["small-remnants"])
target_proxy_ttl.name = "nano-target-proxy-ttl"
target_proxy_ttl.selection_box = nil
target_proxy_ttl.time_before_removed = 200
target_proxy_ttl.final_render_layer = "remnants"
target_proxy_ttl.animation = Proto.empty_animation

local target_proxy = {
  type="simple-entity",
  name = "nano-target-proxy",
  flags = {"placeable-off-grid", "not-on-map"},
  selectable_in_game = false,
  order = "b[decorative]-k[stone-rock]-a[big]",
  render_layer = "object",
  max_health = 1,
  picture = Proto.empty_sprite
}

data:extend({target_proxy_ttl, target_proxy})
