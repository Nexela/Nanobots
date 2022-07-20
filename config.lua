local Config = {}

local Table = require("__stdlib__/stdlib/utils/table")

Config.DEBUG = false

-- Combat robot names, indexed by capsule name
Config.COMBAT_ROBOTS = {
    { capsule = "bob-laser-robot-capsule", unit = "bob-laser-robot", qty = 5, rank = 75 },
    { capsule = "destroyer-capsule", unit = "destroyer", qty = 5, rank = 50 }, { capsule = "defender-capsule", unit = "defender", qty = 1, rank = 25 },
    { capsule = "distractor-capsule", unit = "distractor", qty = 1, rank = 1 }
}

Config.FOOD = { ["alien-goop-cracking-cotton-candy"] = 100, ["cooked-biter-meat"] = 50, ["cooked-fish"] = 40, ["raw-fish"] = 20, ["raw-biter-meat"] = 20 }

Config.TRANSPORT_TYPES = { ["transport-belt"] = 2, ["underground-belt"] = 2, ["splitter"] = 8, ["loader"] = 2 }

Config.ALLOWED_NOT_ON_MAP = { ["entity-ghost"] = true, ["tile-ghost"] = true, ["item-on-ground"] = true }

Config.NANO_EMITTER = "gun-nano-emitter"
Config.AMMO_TERMITES = "ammo-nano-termites"
Config.AMMO_CONSTRUCTORS = "ammo-nano-constructors"

-- Tables linked to technologies, values are the tile radius
Config.BOT_RADIUS = { [0] = 7, [1] = 9, [2] = 11, [3] = 13, [4] = 15 }
Config.QUEUE_SPEED_BONUS = { [0] = 0, [1] = 2, [2] = 4, [3] = 6, [4] = 8 }

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

function Config.update_settings()
    Config.poll_rate = settings["global"]["nanobots-player-cycle-rate"].value --[[@as uint]]
    Config.entities_per_cycle = settings["global"]["nanobots-queued-actions-per-cycle"].value --[[@as uint]]
    Config.actions_per_group = settings["global"]["nanobots-queued-actions-per-group"].value --[[@as uint]]
    Config.ticks_between_actions = settings["global"]["nanobots-ticks-between-action-groups"].value --[[@as uint]]
    Config.build_tiles = settings["global"]["nanobots-build-tiles"].value --[[@as boolean]]
    Config.network_limits = settings["global"]["nanobots-network-limits"].value --[[@as boolean]]
    Config.nanobots_auto = settings["global"]["nanobots-nanobots-auto"].value --[[@as boolean]]
    Config.equipment_auto = settings["global"]["nanobots-equipment-auto"].value --[[@as boolean]]
    Config.afk_time = settings["global"]["nanobots-afk-time"].value --[[@as uint]]
    Config.do_proxies = settings["global"]["nanobots-fulfill-requests"].value --[[@as boolean]]
    return Config
end

Config.update_settings()

Config.control = {}
Config.control.loglevel = 2

return Config
