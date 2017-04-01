-------------------------------------------------------------------------------
--[[armormods]]-- Power Armor module code.
-------------------------------------------------------------------------------
local armormods = {}

local combat_robots = MOD.config.COMBAT_ROBOTS
local healer_capsules = MOD.config.FOOD

local Position = require("stdlib/area/position")
local min, max, abs, ceil = math.min, math.max, math.abs, math.ceil

-------------------------------------------------------------------------------
--[[Helper functions]]--
-------------------------------------------------------------------------------

-- Loop through armor and return a table of valid equipment tables indexed by equipment name
-- @param player: the player object
-- @return table: a table of valid equipment, name as key, array of named equipment as value .
local function get_valid_equipment(player)
    local armor = player.get_inventory(defines.inventory.player_armor)
    local list = {}
    if armor and armor[1] and armor[1].valid_for_read and armor[1].grid and armor[1].grid.equipment then
        for _, equip in pairs(armor[1].grid.equipment) do
            if equip.energy > 0 then
                list[equip.name] = list[equip.name] or {}
                list[equip.name][#list[equip.name] + 1] = equip
            end
        end
    end
    return list
end

-- Increment the y position for flying text to keep text from overlapping
-- @param position: position table - start position
-- @return function: increments position all subsequent calls
local function increment_position(position)
    local x = position.x - 1
    local y = position.y - .5
    return function ()
        y=y+0.5
        return {x=x, y=y}
    end
end

-- Does the character have a personal robort and construction robots. Or is in range of a roboport with bots.
-- character: the player character
-- @return bool: true or false
local function are_bots_ready(c)
    if c.logistic_cell and c.logistic_cell.mobile and c.logistic_cell.construction_radius > 0 then
        if c.logistic_cell.stationed_construction_robot_count > 0 then
            return true
        else
            local port = c.surface.find_entities_filtered{
                type = "roboport",
                area=Position.expand_to_area(c.position, c.logistic_cell.construction_radius),
                limit = 1,
                force = c.force
            }[1]
            if port and port.logistic_network and port.logistic_network.all_construction_robots > 0 then
                return true
            end
        end
    end
end

local function get_health_capsules(player)
    for name, health in pairs(healer_capsules) do
        if game.item_prototypes[name] and player.remove_item({name=name, count = 1}) > 0 then
            return max(health, 10), game.item_prototypes[name].localised_name or {"nanobots.free-food-unknown"}
        end
    end
    return 10, {"nanobots.free-food"}
end

local function get_best_follower_capsule(player)
    for capsule, robot in pairs(combat_robots) do
        local count = player.get_item_count(capsule)
        if count > 0 then return capsule, count, robot end
    end
end

-------------------------------------------------------------------------------
--[[Meat and Potatoes]]--
-------------------------------------------------------------------------------
--At this point player is valid, not afk and has a character

--Mark items for deconstruction if player has roboport
local function gobble_items(player, equipment)
    local rad = player.character.logistic_cell.construction_radius
    local area = Position.expand_to_area(player.position, rad)
    if not player.surface.find_nearest_enemy{position=player.position, max_distance=rad+20, force=player.force} then
        if equipment["equipment-bot-chip-items"] then

            local items = player.surface.find_entities_filtered{area=area, name="item-on-ground"}
            local num_items = #items
            local num_item_chips = #equipment["equipment-bot-chip-items"]

            while num_items > 0 and num_item_chips > 0 do
                local chip = equipment["equipment-bot-chip-items"][num_item_chips]
                while num_items > 0 and chip and chip.energy > 100 do
                    local item = items[num_items]
                    if item and not item.to_be_deconstructed(player.force) then
                        item.order_deconstruction(player.force)
                        chip.energy = chip.energy - 100
                    end
                    num_items = num_items - 1
                end
                num_item_chips = num_item_chips - 1
            end
        end
        if equipment["equipment-bot-chip-trees"] then

            local items = player.surface.find_entities_filtered{area=area, type="tree"}
            local num_items = #items
            local num_item_chips = #equipment["equipment-bot-chip-trees"]

            while num_items > 0 and num_item_chips > 0 do
                local chip = equipment["equipment-bot-chip-trees"][num_item_chips]
                while num_items > 0 and chip and chip.energy > 25 do
                    local item = items[num_items]
                    if item and not item.to_be_deconstructed(player.force) then
                        item.order_deconstruction(player.force)
                        chip.energy = chip.energy - 25
                    end
                    num_items = num_items - 1
                end
                num_item_chips = num_item_chips - 1
            end
        end
    end
end

local function launch_units(player, launchers)
    local rad = player.character.logistic_cell.construction_radius
    local num_launchers = #launchers
    local capsule, count, robot = get_best_follower_capsule(player)
    if capsule and player.surface.find_nearest_enemy{position=player.position, max_distance=rad, force=player.force} then
        local max_bots = player.force.maximum_following_robot_count + player.character_maximum_following_robot_count_bonus
        local range = Position.expand_to_area(player.position, rad)
        local existing = player.surface.count_entities_filtered{area=range, type="combat-robot", force=player.force}
        if existing < (max_bots - (num_launchers * 5)) then
            for i = 1, min(num_launchers, count) do
                local launcher = launchers[i]
                if launcher.energy >= 500 then
                    local removed = player.remove_item({name=capsule, count=1})
                    if removed then
                        player.surface.create_entity{name=robot, position=player.position, force = player.force, target=player.character}
                        launcher.energy = launcher.energy - 500
                    end
                end
            end
        end
    end
end

local function emergency_heal(player, feeder)
    local count = #feeder
    local pos = increment_position(player.character.position)
    while (player.character.health < (player.character.prototype.max_health * .75)) and count > 0 do
        if feeder[count].energy >= 480 then
            local last_health = player.character.health
            local heal, locale = get_health_capsules(player)
            player.character.health = last_health + heal
            local health_line = {"nanobots.health_line", ceil(abs(player.character.health - last_health)), locale}
            feeder[count].energy = 0
            player.surface.create_entity{name="flying-text", text = health_line, color = defines.colors.green, position = pos()}
        end
        count = count - 1
    end
end

-------------------------------------------------------------------------------
--[[BOT CHIPS]]--
-------------------------------------------------------------------------------

function armormods.prepare_chips(player)
    if are_bots_ready(player.character) then
        local equipment = get_valid_equipment(player)
        if equipment["equipment-bot-chip-items"] or equipment["equipment-bot-chip-trees"] then
            gobble_items(player, equipment)
        end
        if equipment["equipment-bot-chip-launcher"] then
            launch_units(player, equipment["equipment-bot-chip-launcher"])
        end
        if equipment["equipment-bot-chip-feeder"] then
            emergency_heal(player, equipment["equipment-bot-chip-feeder"])
        end
    end
end

return armormods
