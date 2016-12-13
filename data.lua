defines = defines or {}
require("stdlib/utils/colors")
require("prototypes/proto-helpers")

--Modular Equipment, When inserted into an equipment grid will automaticly mark items on ground for deconstruction
require("prototypes/equipment/equipment-bot-chip-items")
require("prototypes/equipment/equipment-bot-chip-trees")

--Gun, When equipped and selected will automaticly revive ghosts around it
require("prototypes/gun-nano-emitter")

--Ammos
require("prototypes/ammo/ammo-nano-constructors")
require("prototypes/ammo/ammo-nano-termites")
require("prototypes/ammo/ammo-nano-scrappers")
require("prototypes/ammo/ammo-nano-deconstructors")
-- require("prototypes/ammo/ammo-nano-flooring")

--Sounds
require("prototypes/sounds")
