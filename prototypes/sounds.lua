local sound_nanobot_creators = {
  type = "explosion",
  name = "sound-nanobot-creators",
  flags = {"not-on-map"},
  animations =
  {
    Proto.empty_animation
  },
  --light = {intensity = 0, size = 0},
  -- smoke = "smoke-fast",
  -- smoke_count = 2,
  -- smoke_slow_down_factor = 1,
  sound =
  {
    aggregation =
    {
      max_count = 1,
      remove = true
    },
    variations =
    {
      {
        filename = "__core__/sound/alert-construction.ogg",
        volume = 0.75
      },
      {
        filename = "__core__/sound/alert-construction.ogg",
        volume = 0.75
      }
    }
  }
}

data:extend({sound_nanobot_creators})
