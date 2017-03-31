-------------------------------------------------------------------------------
--[[Force]]
-------------------------------------------------------------------------------
local Force = {}
local List = require("stdlib/utils/list")

Force.get_object_and_data = function (name)
    if game.forces[name] then
        return game.forces[name], global.forces[name]
    end
end

Force.new = function(force_name)
    local obj = {
        index = force_name,
        queued = List.new()
    }
    return obj
end

Force.init = function(force_name, overwrite)
    global.forces = global.forces or {}
    local fdata = global.forces or {}
    if force_name then
        if not game.forces[force_name] then error("Invalid Force "..force_name) end
        if not fdata[force_name] or (fdata[force_name] and overwrite) then
            fdata[force_name] = Force.new(force_name)
        end
    else
        for name in pairs(game.forces) do
            if not fdata[name] or (fdata[name] and overwrite) then
                fdata[name] = Force.new(name)
            end
        end
    end
    Force.quick_list(fdata)
    return fdata
end

Force.quick_list = function(fdata)
    global.force_list = {}
    local list = global.force_list
    for name in pairs(fdata) do
        if not (name == "enemy" or name == "neutral") then
            list[#list+1] = name
        end
    end
    return list
end

-- local recipe_list = {
--     ["tkm-submachine-gun-upgrade"] = true,
--     ["tkm-piercing-rounds-magazine-upgrade"] = true,
--     ["tkm-piercing-shotgun-shell-upgrade"] = true,
--     ["tkm-heavy-armor-upgrade"] = true,
--     ["tkm-modular-armor-upgrade"] = true,
--     ["tkm-power-armor-upgrade"] = true,
--     ["tkm-power-armor-mk2-upgrade"] = true,
--     ["tkm-medium-electric-pole-upgrade"] = true,
--     ["tkm-steel-chest-upgrade"] = true,
--     ["tkm-steel-axe-upgrade"] = true,
--     ["tkm-steel-furnace-upgrade"] = true,
--     ["tkm-reinforced-wall-upgrade"] = true,
--     ["tkm-reinforced-gate-upgrade"] = true,
--     ["tkm-ore-crusher-upgrade"] = true,
-- }
--
-- for _, force in pairs(game.forces) do
--     for _, tech in pairs(force.technologies) do
--         if tech.researched then
--             for _, effect in pairs(tech.effects) do
--                 if effect.type == "unlock-recipe" and recipe_list[effect.recipe] then
--                     log("Unlocking recipe "..effect.recipe)
--                     force.recipes["effect.recipe"].enabled = true
--                 end
--             end
--         end
--     end
-- end

return Force
