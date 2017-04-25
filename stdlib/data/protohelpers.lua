-------------------------------------------------------------------------------
--[[Helper Proto Functions]]--
local Proto = {}

--Quickly duplicate an existing prototype into a new one.
function Proto.dupli_proto( type, name1, name2, adaptMiningResult )
    if data.raw[type][name1] then
        local proto = table.deepcopy(data.raw[type][name1])
        proto.name = name2
        if adaptMiningResult then
            if proto.minable and proto.minable.result then proto.minable.result = name2 end
        end
        if proto.place_result then proto.place_result = name2 end
        if proto.result then proto.result = name2 end
        return(proto)
    else
        error("prototype unknown " .. name1 )
        return(nil)
    end
end

--------------------------------------------------------------------------------------
--Prettier monolith extracting
function Proto.extract_monolith(filename, x, y, w, h)
    return {
        type = "monolith",

        top_monolith_border = 0,
        right_monolith_border = 0,
        bottom_monolith_border = 0,
        left_monolith_border = 0,

        monolith_image = {
            filename = filename,
            priority = "extra-high-no-scale",
            width = w,
            height = h,
            x = x,
            y = y,
        },
    }
end

--Define pipe connection pipe pictures, not all entities use these. This function needs some work though.
Proto.pipes = function (pictures, shift_north, shift_south, shift_west, shift_east)
    if pictures == "turret" then
        shift_north = shift_north or {0, 0}
        shift_south = shift_south or {0, 0}
        shift_west = shift_west or {0, 0}
        shift_east = shift_east or {0, 0}

        return {
            north =
            {
                filename = "__base__/graphics/entity/pipe/pipe-straight-vertical.png",
                priority = "extra-high",
                width = 44,
                height = 42,
                shift = shift_north
            },
            south =
            {
                filename = "__base__/graphics/entity/pipe/pipe-straight-vertical.png",
                priority = "extra-high",
                width = 44,
                height = 42,
                shift = shift_south
            },
            west =
            {
                filename = "__base__/graphics/entity/pipe/pipe-straight-horizontal.png",
                priority = "extra-high",
                width = 32,
                height = 42,
                shift = shift_west
            },
            east =
            {
                filename = "__base__/graphics/entity/pipe/pipe-straight-horizontal.png",
                priority = "extra-high",
                width = 32,
                height = 42,
                shift = shift_east
            },
        }
    else
        shift_north = shift_north or {0, 0}
        shift_south = shift_south or {0, 0}
        shift_west = shift_west or {0, 0}
        shift_east = shift_east or {0, 0}
        return
        {
            north =
            {
                filename = "__base__/graphics/entity/assembling-machine-2/pipe-north.png",
                priority = "extra-high",
                width = 40,
                height = 45,
                shift = shift_north
            },
            south =
            {
                filename = "__base__/graphics/entity/assembling-machine-2/pipe-south.png",
                priority = "extra-high",
                width = 40,
                height = 45,
                shift = shift_south
            },
            west =
            {
                filename = "__base__/graphics/entity/assembling-machine-2/pipe-west.png",
                priority = "extra-high",
                width = 40,
                height = 45,
                shift = shift_west
            },
            east =
            {
                filename = "__base__/graphics/entity/assembling-machine-2/pipe-east.png",
                priority = "extra-high",
                width = 40,
                height = 45,
                shift = shift_east
            },
        }
    end
end

--Quick to use empty sprite
Proto.empty_sprite ={
    filename = "__core__/graphics/empty.png",
    priority = "extra-high",
    width = 1,
    height = 1
}

--Quick to use empty animation
Proto.empty_animation = {
    filename = Proto.empty_sprite.filename,
    width = Proto.empty_sprite.width,
    height = Proto.empty_sprite.height,
    line_length = 1,
    frame_count = 1,
    shift = { 0, 0},
    animation_speed = 1,
    direction_count=1
}

--return pipe covers for true directions.
Proto.pipe_covers = function(n, s, e, w)
    if (n == nil and s == nil and e == nil and w == nil) then
        n, s, e, w = true, true, true, true
    end
    if n == true then n = {
            filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
            priority = "extra-high",
            width = 44,
            height = 32
        }
    else
        n = Proto.empty_sprite
    end
    if e == true then
        e = {
            filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
            priority = "extra-high",
            width = 32,
            height = 32
        }
    else
        e = Proto.empty_sprite
    end
    if s == true then
        s =
        {
            filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
            priority = "extra-high",
            width = 46,
            height = 52
        }
    else
        s = Proto.empty_sprite
    end
    if w == true then
        w =
        {
            filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
            priority = "extra-high",
            width = 32,
            height = 32
        }
    else
        w = Proto.empty_sprite
    end

    return {north = n, south = s, east = e, west = w}
end

return Proto
