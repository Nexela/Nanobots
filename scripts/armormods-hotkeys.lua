-------------------------------------------------------------------------------
--[[Equipment toggle hotkeys]]--
-------------------------------------------------------------------------------

local function toggle_armor_modules(event, name, types)
    local player = game.players[event.player_index]
    local armor = player.get_inventory(defines.inventory.player_armor)[1]
    if armor and armor.valid_for_read and armor.grid then
        local grid = armor.grid
        local status = "notfound"
        local equip_locale

        for eq_name in pairs(types or {[name] = true}) do
            for _, equipment in pairs(grid.equipment) do
                if equipment.name:gsub("^nano%-disabled%-", "") == eq_name then
                    if status == "notfound" then
                        status = equipment.name:find("^nano%-disabled%-") and "enable" or "disable"
                    end
                    if status ~= "notfound" --[[and equipment.valid --]] then
                        local position, energy = equipment.position, equipment.energy
                        local new_name = status == "enable" and eq_name or status == "disable" and "nano-disabled-"..eq_name
                        grid.take(equipment)
                        local new_equip = grid.put{name = new_name, position = position}
                        if new_equip then
                            new_equip.energy = energy
                        end
                    end
                end
            end
            equip_locale = types and types[eq_name] or {"equipment-name."..eq_name}
        end
        player.print({"equipment-hotkeys."..status, equip_locale})
    end
end

local function place_equipment(event)
    local filtered_name = function(name) return name:gsub("^nano%-disabled%-", "") end
    local grid = event.grid
    local placed = event.equipment
    if game.equipment_prototypes["nano-disabled-"..placed.name] then
        for _, equipment in pairs(grid.equipment) do
            if equipment ~= placed then
                if placed.name == filtered_name(equipment.name) and placed.name ~= equipment.name then
                    local new = {name = equipment.name, position = placed.position}
                    grid.take(placed)
                    grid.put(new)
                    break
                end
            end
        end
    end
end
Event.register(defines.events.on_player_placed_equipment, place_equipment)

--TODO Store this in global and update on config changed?
local function get_eq_type_names(type)
    --Add non disabled equipment prototype names to a table if they have a disabled prototype
    local t = {}
    for _, eq in pairs(game.equipment_prototypes) do
        if eq.type == type and not eq.name:find("^nano%-disabled%-") and game.equipment_prototypes["nano-disabled-"..eq.name] then
            t[eq.name] = {"equipment-types."..eq.type}
        end
    end
    return t
end

Event.armor_hotkeys = Event.armor_hotkeys or {}
Event.armor_hotkeys["toggle-equipment-roboport"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-all", get_eq_type_names("roboport-equipment")) end
Event.armor_hotkeys["toggle-equipment-movement-bonus"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-all", get_eq_type_names("movement-bonus-equipment")) end
Event.armor_hotkeys["toggle-equipment-night-vision"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-all", get_eq_type_names("night-vision-equipment")) end
Event.armor_hotkeys["toggle-equipment-bot-chip-all"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-all", get_eq_type_names("active-defense-equipment")) end
Event.armor_hotkeys["toggle-equipment-bot-chip-trees"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-trees") end
Event.armor_hotkeys["toggle-equipment-bot-chip-items"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-items") end
Event.armor_hotkeys["toggle-equipment-bot-chip-launcher"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-launcher") end
Event.armor_hotkeys["toggle-equipment-bot-chip-feeder"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-feeder") end
Event.armor_hotkeys["toggle-equipment-bot-chip-nanointerface"] = function (event) toggle_armor_modules(event, "equipment-bot-chip-nanointerface") end

for event_name in pairs(Event.armor_hotkeys) do
    script.on_event(event_name, Event.armor_hotkeys[event_name])
end
