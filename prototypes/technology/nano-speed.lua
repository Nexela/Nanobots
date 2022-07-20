local function technology_icon_constant_movement_speed()
    local icons = {
        { icon = "__Nanobots__/graphics/technology/tech-nano-speed.png", icon_size = 256, icon_mipmaps = 1 },
        {
            icon = "__core__/graphics/icons/technology/constants/constant-movement-speed.png",
            icon_size = 128,
            icon_mipmaps = 3,
            shift = { 100, 100 }
        }
    }
    return icons
end

local tech1 = {
    type = "technology",
    name = "nano-speed-1",
    icons = technology_icon_constant_movement_speed(),
    effects = { { type = "gun-speed", ammo_category = "nano-ammo", modifier = "1" } },
    prerequisites = { "nanobots" },
    unit = { count = 100, ingredients = { { "automation-science-pack", 1 } }, time = 30 },
    order = "a-b-ab",
    upgrade = true
}

local tech2 = {
    type = "technology",
    name = "nano-speed-2",
    icons = technology_icon_constant_movement_speed(),
    effects = { { type = "gun-speed", ammo_category = "nano-ammo", modifier = "1" } },
    prerequisites = { "engine", "nano-speed-1" },
    unit = { count = 100, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } }, time = 60 },
    order = "a-b-ac",
    upgrade = true
}

local tech3 = {
    type = "technology",
    name = "nano-speed-3",
    icons = technology_icon_constant_movement_speed(),
    effects = { { type = "gun-speed", ammo_category = "nano-ammo", modifier = "1" } },
    prerequisites = { "electric-engine", "nano-speed-2" },
    unit = { count = 300, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } }, time = 90 },
    order = "a-b-ad",
    upgrade = true
}

local tech4 = {
    type = "technology",
    name = "nano-speed-4",
    icons = technology_icon_constant_movement_speed(),
    effects = { { type = "gun-speed", ammo_category = "nano-ammo", modifier = "1" } },
    prerequisites = { "robotics", "nano-speed-3" },
    unit = { count = 400, ingredients = { { "automation-science-pack", 1 }, { "logistic-science-pack", 1 } }, time = 120 },
    order = "a-b-ae",
    upgrade = true
}

data:extend { tech1, tech2, tech3, tech4 }
