local NANO = {}
NANO.TICK_MOD = 120 -- default:180 (3 seconds), ticks between checks
NANO.AUTO_EQUIPMENT = true --default: true, set to false to disable looting alien artifacts and other items on ground
NANO.AUTO_NANO_BOTS = true --default: true, set to false to enable builder-planner item, greatly improved performance
NANO.BUILD_RADIUS = 7.5 -- Radius of 1/2 vanilla personal roboport default: 7.5

--Defunct
NANO.IGNORE_NETWORKS = false --Automatic mode will ignore existing networks, default: false, can give slight perfomance gains if true.
NANO.KEEP_BUILDER = false --Keep the blueprint builder or require a new one every use.

return NANO
