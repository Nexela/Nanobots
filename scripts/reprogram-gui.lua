local match_to_item = {
    ["equipment-bot-chip-trees"] = true,
    ["equipment-bot-chip-items"] = true,
    ["ammo-nano-constructors"] = true,
    ["ammo-nano-termites"] = true,
}

local bot_radius = MOD.config.BOT_RADIUS

local function get_match(stack)
    return stack.valid_for_read and match_to_item[stack.name]
end

local function remove_gui(player, frame_name)
    return player.gui.left[frame_name] and player.gui.left[frame_name].destroy()
end

local function draw_gui(player) -- return gui
    if not player.gui.left["nano_frame_main"] then

        local gui = player.gui.left.add{type="frame", name="nano_frame_main", direction="horizontal", style="nano_frame_style"}
        gui.add{type="label", name="nano_label", caption={"gui-nano-range.label-caption"}, tooltip={"tooltip-nano-range.label-caption"}, style="nano_label_style"}
        gui.add{type="textfield", name = "nano_text_box", text=0, style="nano_text_style"}
        --Up/Down buttons
        local table = gui.add{type="table", name = "nano_table", column_count=1, style="nano_table_style"}
        table.add{type="button", name="nano_btn_up", style="nano_btn_up"}
        table.add{type="button", name="nano_btn_dn", style="nano_btn_dn"}
        --Reset button
        gui.add{type="button", name="nano_btn_reset", style="nano_btn_reset", tooltip={"gui-nano-range.label-reset"}}

        return gui
    else
        return player.gui.left["nano_frame_main"]
    end
end

local function get_max_radius(player)
    if player.cursor_stack.type == "ammo" then
        return bot_radius[player.force.get_ammo_damage_modifier(player.cursor_stack.prototype.get_ammo_type().category)]
    else
        local c = player.character
        return c and c.logistic_cell and c.logistic_cell.mobile and math.floor(c.logistic_cell.construction_radius) or 15
    end
end

local function increase_decrease_reprogrammer(event, change)
    local player, pdata = game.players[event.player_index], global.players[event.player_index]

    if player.cursor_stack.valid_for_read then
        local stack = player.cursor_stack
        if match_to_item[stack.name] then
            local radius
            local text_field = draw_gui(player)["nano_text_box"]
            local max_radius = get_max_radius(player)
            if event.element and event.element.name == "nano_text_box" and not type(event.element.text) == "number" then
                return
            elseif event.element and event.element.name == "nano_text_box" then
                if type(tonumber(text_field.text)) == "number" then
                    radius = tonumber(text_field.text) or 0
                else
                    return
                end
            else
                radius = math.max(0, (pdata.ranges[stack.name] or max_radius) + (change or 0))
            end
            pdata.ranges[stack.name] = ((radius > 0 and radius < 1000) and radius) or nil
            text_field.text = pdata.ranges[stack.name] or max_radius
        end
    else
        remove_gui(player, "nano_frame_main")
    end
end

local function adjust_pad(event)
    local player = game.players[event.player_index]
    if get_match(player.cursor_stack) and player.gui.left["nano_frame_main"] then
        if event.input_name == "adjustment-pad-increase" then
            increase_decrease_reprogrammer(event, 1)
        elseif event.input_name == "adjustment-pad-decrease" then
            increase_decrease_reprogrammer(event, -1)
        end
    end
end

local function load_pad()
    if remote.interfaces["picker"] and remote.interfaces["picker"]["get_adjustment_pad_id"] then
        Event.register(remote.call("picker", "get_adjustment_pad_id"), adjust_pad)
    end
end

Event.register(Event.core_events.load, load_pad)
Event.register(Event.core_events.init, load_pad)

Event.register(defines.events.on_player_cursor_stack_changed, increase_decrease_reprogrammer)
Gui.on_text_changed("nano_text_box", function (event) increase_decrease_reprogrammer(event, 0) end)
Gui.on_click("nano_btn_up", function (event) increase_decrease_reprogrammer(event, 1) end)
Gui.on_click("nano_btn_dn", function (event) increase_decrease_reprogrammer(event, -1) end)
Gui.on_click("nano_btn_reset", function(event) increase_decrease_reprogrammer(event, -99999999999) end)
