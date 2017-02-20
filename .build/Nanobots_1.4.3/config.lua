--luacheck: globals DEBUG
DEBUG = false
local NANO = {}

--Combat robot names, indexed by capsule name
NANO.COMBAT_ROBOTS = {
    ["destroyer-capsule"] = "destroyer",
    ["defender-capsule"] = "defender",
    ["distractor-capsule"] = "distractor"
}

--Changes here will take effect
NANO.CHIP_RADIUS = 10 --default: 10, radius of tiles to check for personal bot mark for deconstruction and unit launcher

--Tables linked to technologys, values are the tile radius
NANO.BOT_RADIUS = {[0] = 7.5, [1] = 9.5, [2]=11.5, [3]=13.5, [4]=15.5}
NANO.TERMITE_RADIUS = {[0] = 7.5, [1] = 9.5, [2]=11.5, [3]=13.5, [4]=15.5}

--Changes here will only affect new games unless you reset the config manually in the save
--/c remote.call("nanobots", "reset_config")
NANO.control = {}
NANO.control.no_network_limits = false --disable checking for existing logistic networks
NANO.control.tick_mod = 60 --default: 60, (1 seconds), ticks between checks, set to 0 to disable all automatic events
NANO.control.ticks_per_queue = 4 --default: 4, builds from queue 1 item every 4 ticks.
NANO.control.auto_equipment = true --default: true, set to false to disable automatic power armor equipment (item will need to be used) (soon)
NANO.control.auto_nanobots = true --default: true, set to false to disable automatic nanobots when emitter is selected gun.
NANO.control.run_ticks = true --default: true, run the tick handler.
NANO.control.sync_cheat_mode = true --default: true, if cheat mode is enabled nanobots place buildings without cost.

--These settings only affect debug mode, no need to change them
NANO.quickstart = {
    clear_items = true,
    power_armor = true,
    destroy_everything = true,
    disable_rso_starting = true,
    disable_rso_chunk = true,
    floor_tile = "concrete",
    mod_name = "Nanobots",
    stacks = {
        "blueprint",
        "deconstruction-planner",
        "creative-mode_matter-source",
        "creative-mode_fluid-source",
        "creative-mode_energy-source",
        "creative-mode_super-electric-pole",
        "construction-robot",
        "creative-mode_magic-wand-modifier",
        "gun-nano-emitter",
        "ammo-nano-constructors",
        "stone-furnace",
        "ammo-nano-deconstructors",
        "equipment-bot-chip-launcher",
        "equipment-bot-chip-trees",
        "equipment-bot-chip-items",
        "chain-gun",
        "chain-ammo"
    }
}

return NANO
