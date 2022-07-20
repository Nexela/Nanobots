local bag = {
    name = "nanobots-loot-bag",
    type = "character-corpse",
    icon = "__Nanobots__/graphics/icons/loot-bag.png",
    icon_mipmaps = 1,
    icon_size = 64,
    selection_priority = 100,
    flags = { "placeable-off-grid", "not-rotatable" },
    time_to_live = 4294967295,
    minable = { mining_time = 2 },
    picture = {
        layers = {
            {

                filename = "__Nanobots__/graphics/entity/loot-bag/loot-bag.png",
                height = 64, width = 64, frame_count = 1, scale = 0.5,
            },
            {
                filename = "__Nanobots__/graphics/entity/loot-bag/loot-bag-mask.png",
                height = 64, width = 64, scale = 0.5, apply_runtime_tint = true, frame_count = 1,
                shift = { 0, 2 / 32 }
            },
            {
                filename = "__Nanobots__/graphics/entity/loot-bag/loot-bag-shadow.png",
                height = 64, width = 64, frame_count = 1, draw_as_shadow = true, scale = 0.5,
            }
        }
    },
    selection_box = { { -0.35, -0.35 }, { 0.35, 0.35 } },
    armor_picture_mapping = nil,
    open_sound = { volume = 0.5, filename = "__base__/sound/character-corpse-open.ogg" },
    close_sound = { volume = 0.5, filename = "__base__/sound/character-corpse-close.ogg" }
}

data:extend { bag }
