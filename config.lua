local EAC = {}
EAC.TICK_MOD = 180 -- default:180 (3 seconds), ticks between checks
EAC.AUTO_GOBBLE = true --default: true, set to false to disable looting alien artifacts and other items on ground
EAC.AUTO_BUILD = true --default: true, set to false to enable builder-planner item, greatly improved performance
EAC.BUILD_RADIUS = 7.5 -- Radius of 1/2 vanilla personal roboport default: 7.5
EAC.IGNORE_NETWORKS = false --Automatic mode will ignore existing networks, default: false, can give slight perfomance gains if true.
EAC.KEEP_BUILDER = false --Keep the blueprint builder or require a new one every use.

return EAC
