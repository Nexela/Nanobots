-------------------------------------------------------------------------------
--[[Force]]
-------------------------------------------------------------------------------
local Force = {}
-- local List = require("stdlib/utils/list")

Force.get_object_and_data = function (name)
    if game.forces[name] then
        return game.forces[name], global.forces[name]
    end
end

Force.new = function(force_name)
    local obj = {
        index = force_name,
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
    --Force.quick_list(fdata)
    return fdata
end

return Force
