local Pad = prequire("__PickerAtheneum__/utils/adjustment-pad", true) ---@diagnostic disable-line: undefined-global
local config = require("config")

local match_to_item = {
    ["equipment-bot-chip-trees"] = true,
    ["equipment-bot-chip-items"] = true,
    ["ammo-nano-constructors"] = true,
    ["ammo-nano-termites"] = true
}

local bot_radius = config.BOT_RADIUS

--- @param stack LuaItemStack?
--- @return boolean
local function get_match(stack)
    return stack and stack.valid_for_read and match_to_item[stack.name] or false
end

--- @param player LuaPlayer
--- @return number
local function get_max_radius(player)
    local cursor = player.cursor_stack
    if cursor and cursor.type == "ammo" then
        return bot_radius[player.force.get_ammo_damage_modifier(cursor.prototype.get_ammo_type().category)] or bot_radius[4]
    else
        local character = player.character
        local cell = character and character.logistic_cell
        return cell and cell.mobile and math.floor(cell.construction_radius) or 15
    end
end

if Pad then
    local function increase_decrease_reprogrammer(event)
        local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
        local pdata = global.players[event.player_index]
        local stack = player.cursor_stack
        local change = event.change or 0
        if get_match(stack) then
            ---@cast stack -nil
            local pad = Pad.get_or_create_adjustment_pad(player, "nano")
            local text_field = pad["nano_text_box"]
            local max_radius = get_max_radius(player)
            local radius = pdata.ranges[stack.name] or max_radius
            if event.element and event.element.name == "nano_text_box" then
                local number = tonumber(event.element.text)
                if not number then
                    radius = max_radius
                else
                    radius = math.min(number, max_radius)
                end
            elseif event.element and event.element.name == "nano_btn_reset" then
                radius = max_radius
            else
                radius = math.min(math.max(0, radius + change), max_radius)
            end
            pad["nano_btn_reset"].enabled = radius ~= max_radius
            pdata.ranges[stack.name] = radius ~= max_radius and radius or nil
            text_field.text = tostring(radius)
        else
            Pad.remove_gui(player, "nano_frame_main")
        end
    end

    local events = { defines.events.on_player_cursor_stack_changed }
    Pad.register_events("nano", increase_decrease_reprogrammer, events)
end
