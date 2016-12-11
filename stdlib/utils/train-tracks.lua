--Returns all rails under the current train.  additon to train.stdlib?

local Position=require("stdlib.area.position")
local debug_picker = {}
debug_picker.name = "debug_picker"


local function valid(entity)
    if entity and entity.valid then return true else return false end
end

function debug_picker.do_script(event)
    local player = game.players[event.player_index]
    local entity = player.selected
    local rails = {}

    for _, text in pairs(player.surface.find_entities_filtered({type="flying-text"})) do
        if text and text.valid then text.destroy() end
    end
    if not entity then return end

    if valid(player) and valid(entity) and (entity.type == "cargo-wagon" or entity.type == "locomotive") then
      --valid check should not be needed as find_entities won't return invalid
        local train = entity.train
        if valid(train) then
            local carriages=train.carriages
            for _, carriage in pairs(carriages) do
                for _, rail in pairs(carriage.surface.find_entities_filtered({area=Position.expand_to_area(carriage.position, 4), type="straight-rail"})) do
                    if rail.minable==false then rails[rail.unit_number]=rail end --index by unique unit num to avoid dupes
                end
                --repeat above block using type=curved-rail if you want curved rail.
            end
            for _, rail in pairs(rails) do
                local text = rail.surface.create_entity({name="flying-text", position=rail.position, force=rail.force, text="RAIL", color=colors.yellow})
                text.active=false
            end
        end
    end
end
