-- script.on_event( "BB_IP_PU", function(event)
-- if game.players[event.player_index].gui.left["BB_frame_main"] then
-- local fakedata = {}
-- fakedata.element = {}
-- fakedata.element.name = "BB_btn_up"
-- fakedata.player_index = event.player_index
-- IncreaseDecreaseBeltNumber(fakedata)
-- end
-- end)
--
-- script.on_event( "BB_IP_PD", function(event)
-- if game.players[event.player_index].gui.left["BB_frame_main"] then
-- local fakedata = {}
-- fakedata.element = {}
-- fakedata.element.name = "BB_btn_down"
-- fakedata.player_index = event.player_index
-- IncreaseDecreaseBeltNumber(fakedata)
-- end
-- end)

local match_to_item = {
    ["equipment-bot-chip-trees"] = true,
    ["equipment-bot-chip-items"] = true,
    ["equipment-bot-chip-launcher"] = true,
    ["ammo-nano-constructors"] = true,
    ["ammo-nano-termites"] = true,
}

local function remove_gui(player, frame_name)
    return player.gui.left[frame_name] and player.gui.left[frame_name].destroy()
end

local function draw_gui(player, pdata) -- return gui
    remove_gui(player, "nano_frame_main")
    if player.gui.left["nano_frame_main"] then player.gui.left["nano_frame_main"].destroy() end

    local gui = player.gui.left.add{type = "frame", name = "nano_frame_main", direction = "horizontal", style="nano_frame_style"}
    gui.add{type="label", name="nano_label", caption={"frame.label-caption"}, tooltip={"tooltip.label"}, style="nano_label_style"}
    gui.add{type="textfield", name = "nano_text_box", text=pdata.name, tooltip={"tooltip.text-field"}, style="nano_text_style"}
    local table = gui.add{type="table", name = "nano_table", colspan=1, style="nano_table_style"}
    table.add{type="button", name="nano_btn_up", style="nano_btn_up"}
    table.add{type="button", name="nano_btn_down", style="nano_btn_dn"}
end

local function on_cursor_stack_changed(event)
    local player, pdata = game.players[event.player_index], global.players[event.player_index]
    local stack_name = player.cursor_stack.valid_for_read and player.cursor_stack.name
    if stack_name and match_to_item[stack_name] then
        draw_gui(player, pdata)
    else
        remove_gui(player, "nano_frame_main")
    end
end

Event.register(defines.events.on_player_cursor_stack_changed, on_cursor_stack_changed)

local function increase_decrease_reprogrammer(event, change)
    local player, pdata = game.players[event.player_index], global.players[event.player_index]
    if player.cursor_stack.valid_for_read then
        local stack_name = player.cursor_stack.name
        if match_to_item[stack_name] then
            pdata.ranges[stack_name] = math.min(1, pdata.ranges[stack_name] or 1 + change)
        end
    end
end

Event.gui_hotkeys = Event.gui_hotkeys or {}
Event.gui_hotkeys["nano-increase-radius"] = function (event) increase_decrease_reprogrammer(event, 1) end
Event.gui_hotkeys["nano-decrease-radius"] = function (event) increase_decrease_reprogrammer(event, -1) end

for event_name in pairs(Event.gui_hotkeys) do
    script.on_event(event_name, Event.gui_hotkeys[event_name])
end
