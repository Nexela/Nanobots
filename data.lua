defines = defines or {}
require("stdlib/colors/colors")
require("stdlib/utils/protohelpers")

require("prototypes/technology")

--Modular Equipment, When inserted into an equipment grid will automaticly mark items on ground for deconstruction
require("prototypes/equipment/equipment-bot-chip-items")
require("prototypes/equipment/equipment-bot-chip-trees")
require("prototypes/equipment/equipment-bot-chip-launcher")
require("prototypes/equipment/equipment-bot-chip-nanointerface")
require("prototypes/equipment/equipment-bot-chip-feeder")

--Gun, When equipped and selected will automaticly revive ghosts around it
require("prototypes/gun-nano-emitter")
--Ammos
require("prototypes/ammo/proxies")
require("prototypes/ammo/constructors")
require("prototypes/ammo/termites")

--Sounds
require("prototypes/sounds")

if DEBUG then --luacheck: ignore DEBUG
    data.raw["furnace"]["stone-furnace"].max_health = 10000
end
