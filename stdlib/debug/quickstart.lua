--luacheck: no global
require("stdlib.event.event")
require("stdlib.config.config")

local QS = Config.new(QS or (MOD and MOD.config and MOD.config.quickstart) or {})

if remote.interfaces["quickstart-script"] then
    if game then game.print("Existing quickstart script - "..remote.call("quickstart-script", "creative_mode_quickstart_registered_to")) end
    return remote.call("quickstart-script", "registered_to")
end
local qs_interface = {}
qs_interface.creative_mode_quickstart_registerd_to = function()
    game.print(QS.get("mod_name", "not-set"))
    return QS.get("mod_name", "not-set")
end
qs_interface.registered_to = function()
    return (MOD and MOD.name) or QS.get("mod_name", "not-set")
end
remote.add_interface("quickstart-script", qs_interface)

local Area=require("stdlib.area.area")
--local quickstart = {}
quickstart = {}
--quickstart.map = require("test")
function quickstart.on_player_created(event)
    if #game.players == 1 then
        local player = game.players[event.player_index]

        if QS.get("clear_items", false) then
            player.clear_items_inside()
        end

        local simple_stacks = QS.get("stacks", {})

        for _, item in pairs(simple_stacks) do
            if game.item_prototypes[item] then
                player.insert(item)
            end
        end

        if QS.get("power_armor", true) then
            --Put on power armor, install equipment
            local inv = player.get_inventory(defines.inventory.player_armor)
            inv.insert("power-armor-mk2")
            local armor = inv[1].grid
            armor.put{name="fusion-reactor-equipment"}
            armor.put{name="personal-roboport-equipment"}
        end

        local surface = player.surface
        local area = QS.get("area_box", {{-100, -100}, {100, 100}})

        if QS.get("disable_rso_starting", false) and remote.interfaces["RSO"] and remote.interfaces["RSO"]["disableStartingArea"] then
            remote.call("RSO", "disableStartingArea")
        end
        if QS.get("disable_rso_chunk", false) and remote.interfaces["RSO"] and remote.interfaces["RSO"]["disableChunkHandler"] then
            remote.call("RSO", "disableChunkHandler")
        end
        if QS.get("destroy_everything", true) then
            for _, entity in pairs(surface.find_entities(area)) do
                if entity.name ~= "player" then
                    entity.destroy()
                end
            end
        end

        if QS.get("floor_tile", true) then
            local tiles = {}
            for x, y in Area.spiral_iterate(area) do
                tiles[#tiles+1]={name=QS.get("floor_tile", "concrete"), position={x=x, y=y}}
            end
            surface.set_tiles(tiles, true)
            --surface.set_tiles(quickstart.map, true)
        end
    end
end
Event.register(defines.events.on_player_created, quickstart.on_player_created)

return quickstart
