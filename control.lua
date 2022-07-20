--- @class Nanobots.global
--- @field players {[integer]: Nanobots.pdata}
--- @field nano_queue Nanobots.queue
global = {}

--- @class Nanobots.pdata
--- @field next_nano_tick uint
--- @field ranges table

require("__stdlib__/stdlib/config").skip_script_protections = true

local Config = require("config")

local Player = require("__stdlib__/stdlib/event/player")
Player.additional_data { ranges = {} }
Player.additional_data(function() return { next_nano_tick = game.tick } end)

local Changes = require("__stdlib__/stdlib/event/changes")
Changes.mod_versions["changes/versions"] = require("changes/versions")

local Nanobots = require("scripts/nanobots")
require("scripts/reprogram-gui")


script.on_event(defines.events.on_tick, Nanobots.on_tick)
script.on_nth_tick(15, Nanobots.on_nth_tick)

script.on_init(function()
    Config.update_settings()
    Player.init()
    Nanobots.on_init()
    Changes.on_init()
end)

script.on_load(function()
    Nanobots.on_load()
end)

script.on_configuration_changed(Changes.on_configuration_changed)
script.on_event(defines.events.on_player_created, Player.init)
script.on_event(defines.events.on_player_removed, Player.remove)
script.on_event(defines.events.on_player_changed_force, Player.update_force)
script.on_event({ defines.events.on_player_joined_game, defines.events.on_player_left_game }, Nanobots.on_players_changed)
script.on_event(defines.events.on_runtime_mod_setting_changed, Config.update_settings)

Config.reset_nano_queue = script.generate_event_name()
script.on_event(Config.reset_nano_queue, Nanobots.reset_nano_queue)

remote.add_interface(script.mod_name, require("__stdlib__/stdlib/scripts/interface"))

commands.add_command(script.mod_name, "Nanobot commands", require("commands"))
