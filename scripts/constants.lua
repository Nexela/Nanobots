local Config = {}

-- local Table = require("__stdlib__/stdlib/utils/table")
local Table = require("scripts/table")

Config.DEBUG = false

Config.TRANSPORT_TYPES = { ["transport-belt"] = 2, ["underground-belt"] = 2, ["splitter"] = 8, ["loader"] = 2 }

Config.ALLOWED_NOT_ON_MAP = { ["entity-ghost"] = true, ["tile-ghost"] = true, ["item-on-ground"] = true }

Config.NANO_EMITTER = "gun-nano-emitter"
Config.AMMO_TERMITES = "ammo-nano-termites"
Config.AMMO_CONSTRUCTORS = "ammo-nano-constructors"

Config.MOVEABLE_TYPES = { train = true, car = true, spidertron = true } ---@type { [string]: true }
Config.BLOCKABLE_TYPES = { ["straight-rail"] = true, ["curved-rail"] = true } ---@type { [string]: true }

--- @type { [number]: SimpleItemStack }
Config.EXPLOSIVES = {
    { name = "cliff-explosives", count = 1 }, { name = "explosives", count = 10 }, { name = "explosive-rocket", count = 4 },
    { name = "explosive-cannon-shell", count = 4 }, { name = "cluster-grenade", count = 2 }, { name = "grenade", count = 14 },
    { name = "land-mine", count = 5 }, { name = "artillery-shell", count = 1 }
}

Config.MAIN_INVENTORIES = Table.keys(Table.invert {
    defines.inventory.character_trash, defines.inventory.character_main, defines.inventory.god_main, defines.inventory.chest,
    defines.inventory.character_vehicle, defines.inventory.car_trunk, defines.inventory.cargo_wagon
})

return Config
