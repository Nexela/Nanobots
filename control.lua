local Player = require('scripts/player')
local Nanobots = require('scripts/nanobots')

script.on_nth_tick(60, Nanobots.on_nth_tick)

script.on_init(Player.on_init)

script.on_configuration_changed(Nanobots.on_configuration_changed)
script.on_event(defines.events.on_player_joined_game, Player.on_player_joined_game)
script.on_event(defines.events.on_player_left_game, Player.on_player_left_game)
script.on_event(defines.events.on_player_created, Player.on_player_created)
script.on_event(defines.events.on_player_gun_inventory_changed, Nanobots.on_player_gun_inventory_changed)
