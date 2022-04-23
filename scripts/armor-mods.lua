local table = require('__stdlib__/stdlib/utils/table')
local config = require('config')
local min, max, abs, ceil, floor = math.min, math.max, math.abs, math.ceil, math.floor

-- TODO: Store this in global and update in on_con_changed
-- TODO: Remote call for inserting/removing into table
local combat_robots = config.COMBAT_ROBOTS
local healer_capsules = config.FOOD

-- Is the personal roboport ready and have a radius greater than 0.
--- @param character LuaEntity
--- @param ignore_radius? boolean
--- @return boolean
local function is_personal_roboport_ready(character, ignore_radius)
    local cell = character.logistic_cell
    return character.grid and cell and cell.mobile and (cell.construction_radius > 0 or ignore_radius)
end

-- Loop through equipment grid and return a table of valid equipment tables indexed by equipment name.
--- @param grid LuaEquipmentGrid
--- @return {[string]: LuaEquipment[]} #equipment with energy in buffer - name as key, array of named equipment as value
--- @return Nanobots.energy_shields
--- @return boolean #Has charged equipment
local function get_valid_equipment(grid)
    if not (grid and grid.valid) then return end

    local has_charged_equipment = false
    local charged = {} ---@type {[string]: LuaEquipment[]}

    --- @class Nanobots.energy_shields
    local energy_shields = {
        shield_level = grid.shield,
        max_shield = grid.max_shield,
        shields = {} ---@type LuaEquipment[]
    }

    for _, equip in pairs(grid.equipment) do
        if equip.type == 'energy-shield-equipment' and equip.shield < equip.max_shield * .75 then
            energy_shields.shields[#energy_shields.shields + 1] = equip
        end
        if equip.energy > 0 then
            charged[equip.name] = charged[equip.name] or {}
            charged[equip.name][#charged[equip.name] + 1] = equip
            has_charged_equipment = true
        end
    end

    return charged, energy_shields, has_charged_equipment
end

--- Increment a position.
--- @param position MapPosition
--- @return MapPosition
local function increment_position(position)
    local x = position.x - 1 ---@type double
    local y = position.y - .5 ---@type double
    return function()
        y = y + 0.5
        return { x = x, y = y }
    end
end

--- Does the character have a personal robort and construction robots. Or is in range of a roboport with construction bots.
--- @param character LuaEntity
--- @param mobile_only? boolean
--- @param stationed_only? boolean
--- @return int
local function get_bot_counts(character, mobile_only, stationed_only)
    if not character.logistic_network then return 0 end

    if mobile_only then
        local cell = character.logistic_cell
        if not (cell and cell.mobile) then return 0 end

        return stationed_only and cell.stationed_construction_robot_count or cell.logistic_network.available_construction_robots
    else
        local bots = 0
        table.each(character.surface.find_logistic_networks_by_construction_area(character.position, character.force), function(network)
            bots = bots + network.available_construction_robots
        end)
        return bots
    end
end

--- @param character LuaEntity
--- @return number, LocalisedString
local function get_health_capsules(character)
    for name, health in pairs(healer_capsules) do
        local prototype = game.item_prototypes[name]
        if prototype and character.remove_item({ name = name, count = 1 }) > 0 then
            return max(health, 10), prototype.localised_name or { 'nanobots.free-food-unknown' }
        end
    end
    return 10, { 'nanobots.free-food' }
end

--- @param character LuaEntity
--- @return table|nil
local function get_best_follower_capsule(character)
    local robot_list = {}
    for _, data in ipairs(combat_robots) do
        local count = game.item_prototypes[data.capsule] and character.get_item_count(data.capsule) or 0
        if count > 0 then robot_list[#robot_list + 1] = { capsule = data.capsule, unit = data.unit, count = count, qty = data.qty, rank = data.rank } end
    end
    return robot_list[1] and robot_list
end

--- Heal shields
--- @param character LuaEntity
--- @param feeders {[int]: LuaEquipment}
--- @param energy_shields Nanobots.energy_shields
local function emergency_heal_shield(character, feeders, energy_shields)
    local num_feeders = #feeders
    local pos = increment_position(character.position)
    local player = character.player
    -- Only run if we have less than max shield, Feeder max energy is 480
    for _, shield in pairs(energy_shields.shields) do
        if num_feeders == 0 then return end
        while num_feeders > 0 do
            local feeder = feeders[num_feeders]
            while feeder and feeder.energy > 120 do
                if shield.shield < shield.max_shield * .75 then
                    local last_health = shield.shield
                    local heal_amount, locale = get_health_capsules(character)
                    shield.shield = shield.shield + (heal_amount * 1.5)
                    local health_line = { 'nanobots.health_line', ceil(abs(shield.shield - last_health)), locale }
                    player.create_local_flying_text { text = health_line, color = defines.color.green, position = pos() }
                    feeder.energy = feeder.energy - 120
                else
                    break
                end
            end
            num_feeders = num_feeders - 1
        end
    end
end

--- Heal Character
--- @param character LuaEntity
--- @param feeders {[int]: LuaEquipment}
local function emergency_heal_character(character, feeders)
    local num_feeders = #feeders
    local pos = increment_position(character.position)
    local max_health = character.prototype.max_health * .75
    local player = character.player

    while num_feeders > 0 do
        local feeder = feeders[num_feeders]
        while feeder and feeder.energy >= 120 do
            if character.health < max_health then
                local last_health = character.health
                local heal, locale = get_health_capsules(player)
                character.health = last_health + heal
                local health_line = { 'nanobots.health_line', ceil(abs(character.health - last_health)), locale }
                feeder.energy = feeder.energy - 120
                player.create_local_flying_text { text = health_line, color = defines.color.green, position = pos() }
            else
                return
            end
        end
        num_feeders = num_feeders - 1
    end
end

--- @param character LuaEntity
--- @param chip_name string
local function get_chip_radius(character, chip_name)
    local pdata = global.players[character.player.index]
    local cell = character.logistic_cell
    local max_radius = cell.mobile and floor(cell.construction_radius) or 15
    local radius = pdata.ranges[chip_name] or max_radius
    return min(radius, max_radius)
end

local chip_type = {
    ['equipment-bot-chip-items'] = { type = 'item-entity', name = nil },
    ['equipment-bot-chip-trees'] = { type = 'tree', name = nil },
    ['equipment-bot-chip-rocks'] = { type = 'simple-entity', name = { 'rock-huge', 'rock-big', 'sand-rock-big' } }
}

--- @param character LuaEntity
--- @param equipment LuaEquipment[]
--- @param limit? number
--- @return LuaEntity[]
local function get_chip_results(character, equipment, limit)
    if #equipment == 0 or limit <= 0 then return {} end

    local eq_name = equipment[1].name
    --- @type LuaSurface.find_entities_filtered_param
    local params = {
        type = chip_type[eq_name].type,
        name = chip_type[eq_name].name,
        position = character.position,
        radius = get_chip_radius(character, eq_name),
        limit = math.min(20 * #equipment, limit), -- 20 usages per equipment @50/1kj
        to_be_deconstructed = false
    }
    return character.surface.find_entities_filtered(params)
end

--- @param force LuaForce
--- @param chips LuaEquipment[]
--- @param entities LuaEntity[]
--- @param bot_counter fun(num: number):number
local function mark_items(force, chips, entities, bot_counter)
    local num_entities = #entities
    local num_chips = #chips
    local bots = bot_counter(0)
    local start_bots = bots
    while num_entities > 0 and num_chips > 0 and bots > 0 do
        local item_chip = entities and chips[num_chips]
        while num_entities > 0 and item_chip and item_chip.energy >= 50 and bots > 0 do
            local item = entities[num_entities]
            item.order_deconstruction(force)
            bots = bots - 1
            item_chip.energy = item_chip.energy - 50
            num_entities = num_entities - 1
        end
        num_chips = num_chips - 1
    end
    bot_counter(-(start_bots - bots))
end

--- @param start number
--- @return fun(add: number):number
local function counter(start)
    local count = start
    return function(add)
        count = count + add
        return count
    end
end

do -- The chips

    --- Process chips that affect healing.
    --- @param character LuaEntity
    --- @param equipment {[string]: LuaEquipment[]}
    --- @param energy_shields Nanobots.energy_shields
    local function process_healing_chips(character, equipment, energy_shields)
        if not equipment['equipment-bot-chip-feeder'] then return end

        if #energy_shields.shields > 0 then
            emergency_heal_shield(character, equipment['equipment-bot-chip-feeder'], energy_shields)
        elseif character.health < character.prototype.max_health * .75 then
            emergency_heal_character(character, equipment['equipment-bot-chip-feeder'])
        end
    end

    --- Process chips that affect combat.
    --- @param character LuaEntity
    --- @param equipment {[string]: LuaEquipment[]}
    local function process_combat_chips(character, equipment)
        if not equipment['equipment-bot-chip-launcher'] then return end

        local launchers = equipment['equipment-bot-chip-launcher']
        local num_launchers = #launchers
        local capsule_data = get_best_follower_capsule(character)
        if capsule_data ~= nil then
            local max_bots = character.force.maximum_following_robot_count + character.character_maximum_following_robot_count_bonus
            local existing = #character.following_robots
            local next_capsule = 1
            local capsule = capsule_data[next_capsule]
            while capsule and existing < (max_bots - capsule.qty) and capsule.count > 0 and num_launchers > 0 do
                local launcher = launchers[num_launchers]
                while capsule and existing < (max_bots - capsule.qty) and launcher and launcher.energy >= 500 do
                    if character.remove_item({ name = capsule.capsule, count = 1 }) == 1 then
                        character.surface.create_entity { name = capsule.unit, position = character.position, force = character.force, target = character }
                        launcher.energy = launcher.energy - 500
                        capsule.count = capsule.count - 1
                        existing = existing + capsule.qty
                        if capsule.count == 0 then
                            next_capsule = next_capsule + 1
                            capsule = capsule_data[next_capsule]
                        end
                    end
                end
                num_launchers = num_launchers - 1
            end
        end
    end

    --- Process chips when no enemies are around.
    --- @param character LuaEntity
    --- @param force LuaForce
    --- @param equipment {[string]: LuaEquipment[]}
    local function process_peaceful_chips(character, force, equipment)
        local item_eq = equipment['equipment-bot-chip-items']
        local tree_eq = equipment['equipment-bot-chip-trees']
        if not (item_eq or tree_eq) then return end

        local bots_available = get_bot_counts(character)
        if bots_available <= 0 then return end

        local bot_count = counter(bots_available)

        if item_eq then
            mark_items(force, item_eq, get_chip_results(character, item_eq, bot_count(0)), bot_count)
        end

        if tree_eq then
            mark_items(force, tree_eq, get_chip_results(character, tree_eq, bot_count(0)), bot_count)
        end
    end

    --- @param player LuaPlayer
    local function prepare_chips(player)
        local character = player.character
        if not is_personal_roboport_ready(character) then return end

        local equipment, energy_shields, has_charged_equipment = get_valid_equipment(character.grid)
        if not has_charged_equipment then return end

        process_healing_chips(character, equipment, energy_shields)

        local force = character.force
        local rad = character.logistic_cell.construction_radius
        local enemy = character.surface.find_nearest_enemy { position = character.position, max_distance = rad + 10, force = force }

        if enemy then
            process_combat_chips(character, equipment)
        else
            process_peaceful_chips(character, force, equipment)
        end
    end

    return prepare_chips
end
