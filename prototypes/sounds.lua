local sound_nanobot_creators = {
  type = "explosion",
  name = "nano-sound-build-tiles",
  flags = {"not-on-map"},
  animations =
  {
    Proto.empty_animation
  },
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
        filename = "__base__/sound/walking/grass-01.ogg",
        volume = 1.0
      },
      {
        filename = "__base__/sound/walking/grass-02.ogg",
        volume = 1.0
      },
      {
        filename = "__base__/sound/walking/grass-03.ogg",
        volume = 1.0
      },
      {
        filename = "__base__/sound/walking/grass-04.ogg",
        volume = 1.0
      },
    }
  }
}

data:extend({sound_nanobot_creators})
