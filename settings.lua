data:extend {
    {
        type = 'bool-setting',
        name = 'nanobots-active-emitter-mode',
        setting_type = 'runtime-per-user',
        default_value = true,
        order = 'nanobots-aa[mode]',
    },
}

data:extend {
    {
        type = 'bool-setting',
        name = 'nanobots-nanobots-auto',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'nanobots-aa[auto-bots-roll-out]',
    },
    {
        type = 'bool-setting',
        name = 'nanobots-equipment-auto',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'nanobots-ab[poll-rate]',
    },
    {
        type = 'bool-setting',
        name = 'nanobots-build-tiles',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'nanobots-ba[build-tiles]',
    },
    {
        type = 'bool-setting',
        name = 'nanobots-fullfill-requests',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'nanobots-bb',
    },
    {
        type = 'bool-setting',
        name = 'nanobots-network-limits',
        setting_type = 'runtime-global',
        default_value = true,
        order = 'nanobots-ca[check-networks]',
    },
    {
        name = 'nanobots-afk-time',
        type = 'int-setting',
        setting_type = 'runtime-global',
        default_value = 4,
        maximum_value = 60 * 60,
        minimum_value = 0,
        order = 'nanobots-da',
    },
    {
        type = 'int-setting',
        name = 'nanobots-player-cycle-rate',
        setting_type = 'runtime-global',
        default_value = 60,
        maximum_value = 60 * 60,
        minimum_value = 1,
        order = 'nanobots-ea',
    },
    {
        type = 'int-setting',
        name = 'nanobots-queued-actions-per-cycle',
        setting_type = 'runtime-global',
        default_value = 100,
        maximum_value = 800,
        minimum_value = 1,
        order = 'nanobots-eb',
    },
    {
        type = 'int-setting',
        name = 'nanobots-queued-actions-per-group',
        setting_type = 'runtime-global',
        default_value = 5,
        minimum_value = 1,
        maximum_value = 100,
        order = 'nanobots-ec',
    },
    {
        type = 'int-setting',
        name = 'nanobots-ticks-between-action-groups',
        setting_type = 'runtime-global',
        default_value = 30,
        maximum_value = 60 * 60,
        minimum_value = 4,
        order = 'nanobots-ed',
    },
}
--[[
nanobots-player-cycle-rate
nanobots-queued-actions-per-cycle
nanobots-queued-actions-per-group
nanobots-ticks-between-action-groups
]]
