local NANO = {}
NANO.TICK_MOD = 60 -- default:60 (1 seconds), ticks between checks, set to 0 to disable all automatic events
NANO.TICKS_PER_QUEUE = 4
NANO.AUTO_EQUIPMENT = true --default: true, set to false to disable automatic power armor equipment (item will need to be used)
NANO.AUTO_NANO_BOTS = true --default: true, set to false to disable automatic nanobots. (gun will need to be fired to use)
NANO.BUILD_RADIUS = 7.5 -- Radius of 1/2 vanilla personal roboport default: 7.5
NANO.CHIP_RADIUS = 10

return NANO
