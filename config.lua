local NANO           = {}
NANO.TICK_MOD        = 60   --default:60,  (1 seconds), ticks between checks, set to 0 to disable all automatic events
NANO.TICKS_PER_QUEUE = 4    --default:4, builds from queue 1 item every 4 ticks.
NANO.AUTO_EQUIPMENT  = true --default: true, set to false to disable automatic power armor equipment (item will need to be used) (soon)
NANO.AUTO_NANO_BOTS  = true --default: true, set to false to disable automatic nanobots. (gun will need to be fired to use) (soon)
NANO.BUILD_RADIUS    = 7.5  --default: 7.5, tiles about 1/2 vanilla personal roboport
NANO.TERMITE_RADIUS  = 7.5  --default: 7.5, tiles
NANO.CHIP_RADIUS     = 10

return NANO
