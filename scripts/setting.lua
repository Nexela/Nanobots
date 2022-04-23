local setting = {} ---@type Nanobots.settings

local function update_settings()
    --- @class Nanobots.settings
    setting.poll_rate = settings['global']['nanobots-player-cycle-rate'].value ---@type uint
    setting.entities_per_cycle = settings['global']['nanobots-queued-actions-per-cycle'].value ---@type uint
    setting.actions_per_group = settings['global']['nanobots-queued-actions-per-group'].value ---@type uint
    setting.ticks_between_actions = settings['global']['nanobots-ticks-between-action-groups'].value ---@type uint
    setting.build_tiles = settings['global']['nanobots-build-tiles'].value ---@type boolean
    setting.network_limits = settings['global']['nanobots-network-limits'].value ---@type boolean
    setting.nanobots_auto = settings['global']['nanobots-nanobots-auto'].value ---@type boolean
    setting.equipment_auto = settings['global']['nanobots-equipment-auto'].value ---@type boolean
    setting.afk_time = settings['global']['nanobots-afk-time'].value ---@type uint
    setting.do_proxies = settings['global']['nanobots-fullfill-requests'].value ---@type boolean
    return setting
end
setting.update_settings = update_settings
update_settings()

return setting
