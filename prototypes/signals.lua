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
    order = "[nano-signal]-a"
}
local signal2 = {
    type = "virtual-signal",
    name = "nano-signal-item-on-ground",
    special_signal = false,
    icon = "__Nanobots__/graphics/icons/signals/item-on-ground.png",
    subgroup = "nanobot-signals",
    order = "[nano-signal]-b"
}
local signal3 = {
    type = "virtual-signal",
    name = "nano-signal-remove-tiles",
    special_signal = false,
    icon = "__Nanobots__/graphics/icons/signals/item-on-ground.png",
    subgroup = "nanobot-signals",
    order = "[nano-signal]-c"
}
local signal4 = {
    type = "virtual-signal",
    name = "nano-signal-landfill-the-world",
    special_signal = false,
    icon = "__Nanobots__/graphics/icons/signals/item-on-ground.png",
    subgroup = "nanobot-signals",
    order = "[nano-signal]-d"
}
local signal5 = {
    type = "virtual-signal",
    name = "nano-signal-deconstruct-finished-miners",
    special_signal = false,
    icon = "__Nanobots__/graphics/icons/signals/item-on-ground.png",
    subgroup = "nanobot-signals",
    order = "[nano-signal]-e"
}
local signal99 = {
    type = "virtual-signal",
    name = "nano-signal-closest-roboport",
    special_signal = false,
    icon = "__Nanobots__/graphics/icons/signals/closest-roboport.png",
    subgroup = "nanobot-signals",
    order = "[nano-signal]-z"
}


data:extend{group, signal1, signal2, signal3, signal4, signal5, signal99}
