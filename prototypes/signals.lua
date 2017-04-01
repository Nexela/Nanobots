local group = {
  type = "item-subgroup",
  name = "nanobot-signals",
  group = "signals",
  order = "zzzzzz"
}

local signal1 = {
  type = "virtual-signal",
  name = "nano-signal-chop-trees",
  special_signal = false,
  icon = "__Nanobots__/graphics/icons/signals/chop-trees.png",
  subgroup = "nanobot-signals",
  order = "a"
}
local signal2 = {
  type = "virtual-signal",
  name = "nano-signal-item-on-ground",
  special_signal = false,
  icon = "__Nanobots__/graphics/icons/signals/item-on-ground.png",
  subgroup = "nanobot-signals",
  order = "b"
}
local signal3 = {
  type = "virtual-signal",
  name = "nano-signal-network-neighboors",
  special_signal = false,
  icon = "__Nanobots__/graphics/icons/signals/network-neighboors.png",
  subgroup = "nanobot-signals",
  order = "c"
}

data:extend{group, signal1, signal2, signal3}
