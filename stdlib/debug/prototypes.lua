local debug_prototypes = {}
function debug_prototypes.make_chunk_markers(name)
    data:extend{
        {
            type = "simple-entity",
            name = "debug-chunk-marker",
            flags = {"placeable-off-grid"},
            selectable_in_game = false,
            collision_mask = {},
            --collision_box = {{-1.1, -1.1}, {1.1, 1.1}},
            --selection_box = {{-1.3, -1.3}, {1.3, 1.3}},
            render_layer = "light-effect",
            max_health = 200,
            pictures =
            {
                {
                    filename = "__"..name.."__/stdlib/debug/debug-chunk-marker.png",
                    priority = "extra-high-no-scale",
                    width = 64,
                    height = 64,
                    shift = {0, 0}
                },
                {
                    filename = "__"..name.."__/stdlib/debug/debug-chunk-marker-horizontal.png",
                    priority = "extra-high-no-scale",
                    width = 64,
                    height = 64,
                    shift = {0, 0}
                },
                {
                    filename = "__"..name.."__/stdlib/debug/debug-chunk-marker-vertical.png",
                    priority = "extra-high-no-scale",
                    width = 64,
                    height = 64,
                    shift = {0, 0}
                }
            }
        }
    }
end
return debug_prototypes

-- render layers
----"tile-transition", "resource", "decorative", "remnants", "floor", "transport-belt-endings", "corpse", "floor-mechanics", "item", "lower-object", "object", "higher-object-above",
----"higher-object-under", "wires", "lower-radius-visualization", "radius-visualization", "entity-info-icon", "explosion", "projectile", "smoke", "air-object", "air-entity-info-con",
----"light-effect", "selection-box", "arrow", "cursor"

-- collision masks
----"ground-tile", "water-tile", "resource-layer", "floor-layer", "item-layer", "object-layer", "player-layer", "ghost-layer", "doodad-layer", "not-colliding-with-itself"