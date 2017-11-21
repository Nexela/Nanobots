local NANO = require("config")
require("stdlib/core")

--Custom GUI's
require("prototypes/gui")

--Custom virtual signals
require("prototypes/signals")

--Custom Technologies
require("prototypes/technology/nano-range")
require("prototypes/technology/nano-speed")
require("prototypes/technology/nanobots")

--Modular Equipment, When inserted into an equipment grid will automaticly mark items on ground for deconstruction
require("prototypes/equipment/equipment-bot-chip-items")
require("prototypes/equipment/equipment-bot-chip-trees")
require("prototypes/equipment/equipment-bot-chip-launcher")
require("prototypes/equipment/equipment-bot-chip-nanointerface")
require("prototypes/equipment/equipment-bot-chip-feeder")
require("prototypes/equipment/belt-immunity-equipment")

--Gun, When equipped and selected will automaticly revive ghosts around it
require("prototypes/gun-nano-emitter")

--Ammo for nano guns
require("prototypes/ammo/proxies")
require("prototypes/ammo/constructors")
require("prototypes/ammo/termites")

--Roboport reprogramming interface
require("prototypes/roboport-interface")

--Sounds
require("prototypes/sounds")

if NANO.DEBUG then
    local developer = require("stdlib.data.developer.developer")
    developer.make_test_entities("Nanobots")
end
