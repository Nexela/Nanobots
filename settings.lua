data:extend{
    {
        type = "bool-setting",
        name = "nanobots-nanobots-auto",
        setting_type = "runtime-global",
        default_value = true,
        order = "nanobots-aa[auto-bots-roll-out]"
    },
    {
        type = "bool-setting",
        name = "nanobots-active-emitter-mode",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "nanobots-aa[mode]"
    },
    {
        type = "bool-setting",
        name = "nanobots-equipment-auto",
        setting_type = "runtime-global",
        default_value = true,
        order = "nanobots-ab[poll-rate]"
    },
    {
        type = "bool-setting",
        name = "nanobots-nano-build-tiles",
        setting_type = "runtime-global",
        default_value = true,
        order = "nanobots-ba[build-tiles]"
    },
    {
        type = "bool-setting",
        name = "nanobots-nano-fullfill-requests",
        setting_type = "runtime-global",
        default_value = true,
        order = "nanobots-bb"
    },
    {
        type = "bool-setting",
        name = "nanobots-network-limits",
        setting_type = "runtime-global",
        default_value = true,
        order = "nanobots-ca[check-networks]"
    },
    {
        name = "nanobots-afk-time",
        type = "int-setting",
        setting_type = "runtime-global",
        default_value = 4,
        maximum_value = 60*60,
        minimum_value = 0,
        order = "nanobots-da",
    },
    {
        type = "int-setting",
        name = "nanobots-nano-poll-rate",
        setting_type = "runtime-global",
        default_value = 60,
        maximum_value = 60*60,
        minimum_value = 1,
        order = "nanobots-ea[nano-poll-rate]"
    },
    {
        type = "int-setting",
        name = "nanobots-nano-queue-per-cycle",
        setting_type = "runtime-global",
        default_value = 100,
        maximum_value = 800,
        minimum_value = 1,
        order = "nanobots-eb[nano-queue-rate]"
    },
    {
        type = "int-setting",
        name = "nanobots-nano-queue-rate",
        setting_type = "runtime-global",
        default_value = 12,
        maximum_value = 60*60,
        minimum_value = 4,
        order = "nanobots-ec[nano-queue-rate]"
    }
}
