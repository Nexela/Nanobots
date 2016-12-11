local sound_nanobot_creators = {
  type = "explosion",
  name = "sound-nanobot-creators",
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
        filename = "__Nanobots__/sounds/robostep.ogg",
        volume = 0.75
      },
      {
        filename = "__Nanobots__/sounds/robostep.ogg",
        volume = 0.75
      }
    }
  }
}

data:extend({sound_nanobot_creators})
