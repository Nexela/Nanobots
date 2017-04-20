local NANO = {}

NANO.DEBUG = true

--Combat robot names, indexed by capsule name
NANO.COMBAT_ROBOTS = {
    {capsule = "bob-laser-robot-capsule", unit = "bob-laser-robot", qty = 5, rank = 75},
    {capsule = "destroyer-capsule", unit = "destroyer", qty = 5, rank = 50},
    {capsule = "defender-capsule", unit = "defender", qty = 1, rank = 25},
    {capsule = "distractor-capsule", unit = "distractor", qty = 1, rank = 1},
}

NANO.FOOD = {
    ["alien-goop-cracking-cotton-candy"] = 100,
    ["cooked-biter-meat"] = 50,
    ["cooked-fish"] = 40,
    ["raw-fish"] = 20,
    ["raw-biter-meat"] = 20,
}

NANO.TRANSPORT_TYPES = {
    ["transport-belt"] = 2,
    ["underground-belt"] = 2,
    ["splitter"] = 8,
    ["loader"] = 2,
}

NANO.TRAIN_TYPES = {
    ["locomotive"] = true,
    ["cargo-wagon"] = true
}

--Tables linked to technologies, values are the tile radius
NANO.BOT_RADIUS = {[0] = 7, [1] = 9, [2] = 11, [3] = 13, [4] = 15}
--NANO.TERMITE_RADIUS = {[0] = 7, [1] = 9, [2] = 11, [3] = 13, [4] = 15}
NANO.QUEUE_SPEED_BONUS = {[0] = 0, [1] = 2, [2] = 4, [3] = 6, [4] = 8}

--Changes here will only affect new games unless you reset the config manually in the save
--/c remote.call("nanobots", "reset_config")
NANO.control = {}
NANO.control.loglevel = 2
NANO.control.no_network_limits = false --disable checking for existing logistic networks
NANO.control.poll_rate = 60 --default: 60, (1 seconds), ticks between checks, set to 0 to disable all automatic events
NANO.control.nanobots_tick_spacing = 12 --default: 12, builds from queue 1 item every 12 ticks.
NANO.control.robo_interface_tick_spacing = 5 -- default: 5, queues logistic cell actions every 5 ticks
NANO.control.robo_interface_free_bots_per = 50 -- default: 50 Percentage of free construction bots needed for automatic tasks
NANO.control.auto_equipment = true --default: true, set to false to disable automatic power armor equipment (item will need to be used) (soon)
NANO.control.auto_nanobots = true --default: true, set to false to disable automatic nanobots when emitter is selected gun.

NANO.control.sync_cheat_mode = true --default: true, if cheat mode is enabled nanobots place buildings without cost.
NANO.control.inside_area_radius = 60
NANO.control.nano_emmiter_queues_per_cycle = 80

--These settings only affect debug mode, no need to change them
NANO.quickstart = {
    clear_items = true,
    power_armor = true,
    destroy_everything = true,
    disable_rso_starting = true,
    disable_rso_chunk = true,
    floor_tile = "concrete",
    mod_name = "Nanobots",
    area_box = {{-200, -200}, {200, 200}},
    stacks = {
        "blueprint",
        "deconstruction-planner",
        "creative-mode_matter-source",
        "creative-mode_fluid-source",
        "creative-mode_energy-source",
        "creative-mode_super-electric-pole",
        "construction-robot",
        "creative-mode_magic-wand-modifier",
        "creative-mode_super-roboport",
        "gun-nano-emitter",
        "ammo-nano-constructors",
        "stone-furnace",
        "ammo-nano-deconstructors",
        "equipment-bot-chip-launcher",
        "equipment-bot-chip-trees",
        "equipment-bot-chip-items",
        "chain-gun",
        "chain-ammo",
        "roboport-interface-main"
    }
}

return NANO
