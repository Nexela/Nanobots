_G.DEBUG = true
local NANO             = {}

NANO.BUILD_RADIUS      = 7.5  --default: 7.5, tiles about 1/2 vanilla personal roboport
NANO.TERMITE_RADIUS    = 7.5  --default: 7.5, tiles
NANO.CHIP_RADIUS       = 10

NANO.control = {}
NANO.control.no_network_limits = false -- disable checking for existing logistic networks
NANO.control.tick_mod          = 60    --default:60,  (1 seconds), ticks between checks, set to 0 to disable all automatic events
NANO.control.ticks_per_queue   = 4     --default:4, builds from queue 1 item every 4 ticks.
NANO.control.auto_equipment    = true  --default: true, set to false to disable automatic power armor equipment (item will need to be used) (soon)
NANO.control.auto_nanobots     = true  --default: true, set to false to disable automatic nanobots.
NANO.control.run_ticks         = true

NANO.quickstart = {}
NANO.quickstart.clear_items = true
NANO.quickstart.power_armor = false
NANO.quickstart.destroy_everything = true
NANO.quickstart.floor_tile = "concrete"
NANO.quickstart.mod_name = "Nanobots"
NANO.quickstart.stacks = {
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
  "ammo-nano-deconstructors"
}


return NANO
