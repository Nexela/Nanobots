local NANO = {}

NANO.DEBUG = false

--Combat robot names, indexed by capsule name
NANO.COMBAT_ROBOTS = {
    {capsule = 'bob-laser-robot-capsule', unit = 'bob-laser-robot', qty = 5, rank = 75},
    {capsule = 'destroyer-capsule', unit = 'destroyer', qty = 5, rank = 50},
    {capsule = 'defender-capsule', unit = 'defender', qty = 1, rank = 25},
    {capsule = 'distractor-capsule', unit = 'distractor', qty = 1, rank = 1}
}

NANO.FOOD = {
    ['alien-goop-cracking-cotton-candy'] = 100,
    ['cooked-biter-meat'] = 50,
    ['cooked-fish'] = 40,
    ['raw-fish'] = 20,
    ['raw-biter-meat'] = 20
}

NANO.TRANSPORT_TYPES = {
    ['transport-belt'] = 2,
    ['underground-belt'] = 2,
    ['splitter'] = 8,
    ['loader'] = 2
}

NANO.ALLOWED_NOT_ON_MAP = {
    ['entity-ghost'] = true,
    ['tile-ghost'] = true,
    ['item-on-ground'] = true
}

--Tables linked to technologies, values are the tile radius
NANO.BOT_RADIUS = {[0] = 7, [1] = 9, [2] = 11, [3] = 13, [4] = 15}
NANO.QUEUE_SPEED_BONUS = {[0] = 0, [1] = 2, [2] = 4, [3] = 6, [4] = 8}

NANO.control = {}
NANO.control.loglevel = 2

--These settings only affect debug mode, no need to change them
NANO.quickstart = {
    clear_items = true,
    power_armor = 'power-armor-mk2',
    equipment = {
        'creative_mode-super-fusion-reactor-equipment',
        'personal-roboport-mk2-equipment',
        'belt-immunity-equipment'
    },
    destroy_everything = true,
    disable_rso_starting = true,
    disable_rso_chunk = true,
    floor_tile = 'concrete',
    mod_name = 'Nanobots',
    area_box = {{-250, -250}, {250, 250}},
    chunk_bounds = true,
    center_map_tag = true,
    setup_power = true,
    stacks = {
        'creative-mode_matter-source',
        'creative-mode_fluid-source',
        'creative-mode_energy-source',
        'creative-mode_super-substation',
        'construction-robot',
        'creative-mode_magic-wand-modifier',
        'creative-mode_super-roboport',
        'gun-nano-emitter',
        'ammo-nano-constructors',
        'stone-furnace',
        'ammo-nano-deconstructors'
    }
}

return NANO
