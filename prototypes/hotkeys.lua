-- 'consuming'
-- available options:
-- none: default if not defined
-- all: if this is the first input to get this key sequence then no other inputs listening for this sequence are fired
-- script-only: if this is the first *custom* input to get this key sequence then no other *custom* inputs listening for this sequence are fired. Normal game inputs will still be fired even if they match this sequence.
-- game-only: The opposite of script-only: blocks game inputs using the same key sequence but lets other custom inputs using the same key sequence fire.

data:extend
{
    {
        type = "custom-input",
        name = "toggle-equipment-roboport",
        key_sequence = "CONTROL + F1",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-movement-bonus",
        key_sequence = "CONTROL + F2",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-night-vision",
        key_sequence = "CONTROL + F3",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-all",
        key_sequence = "CONTROL + F4",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-trees",
        key_sequence = "CONTROL + F5",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-items",
        key_sequence = "CONTROL + F6",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-launcher",
        key_sequence = "CONTROL + F7",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-feeder",
        key_sequence = "CONTROL + F8",
        consuming = "game-only"
    },
    {
        type = "custom-input",
        name = "toggle-equipment-bot-chip-nanointerface",
        key_sequence = "CONTROL + F9",
        consuming = "game-only"
    },
}
