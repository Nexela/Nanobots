--luacheck: ignore
-- utils.lua by binbinhfr, v1.0.10

local author_name1 = "Nexela"
local author_name2 = "Nexela"

-------------------------------------------------------------------------------
--@return Player Object
-- function Game.get_valid_player(player_or_index)
-- if not player_or_index then
-- if game.player then return game.player
-- elseif game.players[1] then
-- return game.players[1]
-- end
-- elseif type(player_or_index) == "number" or type(player_or_index) == "string" then
-- if game.players[player_or_index] and game.players[player_or_index].valid then
-- return game.players[player_or_index]
-- end
-- elseif type(player_or_index) == "table" and player_or_index.valid then
-- return player_or_index
-- end
-- return false
-- end
--
-- function Game.valid_force(force)
-- if type(force) == "string" and game.forces[force] and game.forces[force].valid then
-- return true
-- elseif type(force) == "table" and game.forces[force.name] and game.forces[force.name].valid then
-- return true
-- end
-- return false
-- end

--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
function GetNearest( objects, point )
    if #objects == 0 then
        return nil
    end

    local maxDist = math.huge
    local nearest = objects[1]
    for _, obj in ipairs(objects) do
        local dist = DistanceSqr(point, obj.position)
        if dist < maxDist then
            maxDist = dist
            nearest = obj
        end
    end

    return nearest
end

--------------------------------------------------------------------------------------
function nearest_players( params )
    local origin = params.origin
    local max_distance = params.max_distance or 2
    local list = {}

    for playerIndex = 1, #game.players do
        local player = game.players[playerIndex]
        local distance = util.distance(player.position, origin)
        if distance <= max_distance then
            table.insert(list, player)
        end
    end

    return list
end

--------------------------------------------------------------------------------------
function flying_text(line, color, pos, surface)
    color = color or defines.colors.red
    line = line or "missing text" --If we for some reason didn't pass a message make a message
    if not pos then
        for _, p in pairs(game.players) do
            p.surface.create_entity({name="flying-text", position=p.position, text=line, color=color})
        end
        return
    else
        if surface then
            surface.create_entity({name="flying-text", position=pos, text=line, color=color})
        end
    end
end

--------------------------------------------------------------------------------------
function min( val1, val2 )
    if val1 < val2 then
        return val1
    else
        return val2
    end
end

--------------------------------------------------------------------------------------
function max( val1, val2 )
    if val1 > val2 then
        return val1
    else
        return val2
    end
end

--------------------------------------------------------------------------------------
function iif( cond, val1, val2 )
    if cond then
        return val1
    else
        return val2
    end
end

--------------------------------------------------------------------------------------
function table.add_list(list, obj)
    -- to avoid duplicates...
    for _, obj2 in pairs(list) do
        if obj2 == obj then
            return(false)
        end
    end
    table.insert(list,obj)
    return(true)
end

--------------------------------------------------------------------------------------
function table.del_list(list, obj)
    for i, obj2 in pairs(list) do
        if obj2 == obj then
            table.remove( list, i )
            return(true)
        end
    end
    return(false)
end

--------------------------------------------------------------------------------------
function table.in_list(list, obj)
    for k, obj2 in pairs(list) do
        if obj2 == obj then
            return(k)
        end
    end
    return(nil)
end

function table.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

------------------------------------------------------------------------------------
function is_dev(player)
    return( player.name == author_name1 or player.name == author_name2 )
end

--------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
--Additional Table Helpers

function table.raw_merge(tblA, tblB, safe_merge)
    --safe_merge, only merge tblB[k] does not already exsist in tblA
    if safe_merge then
        for k, v in pairs(tblB) do
            if not rawget(tblA, k) then
                rawset(tblA, k, v)
            end
        end
    else
        for k, v in pairs(tblB) do
            rawset(tblA, k, v)
        end
    end
    return tblA
end

function table.val_to_str ( v )
    if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
                return "'" .. v .. "'"
            else
                return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
            end
        else
            return "table" == type( v ) and table.tostring( v ) or
            tostring( v )

        end
    end

    function table.key_to_str ( k )
        if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
            return k
        else
            return "[" .. table.val_to_str( k ) .. "]"
        end
    end

    function table.tostring( tbl )
        if type(tbl) ~= "table" then return tostring(tbl) end
        local result, done = {}, {}
        for k, v in ipairs( tbl ) do
            table.insert( result, table.val_to_str( v ) )
            done[ k ] = true
        end
        for k, v in pairs( tbl ) do
            if not done[ k ] then
                table.insert( result,
                    table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
            end
        end
        return "{" .. table.concat( result, "," ) .. "}"
    end

    function table.arraytostring(...)
        local s = ""

        for _, v in ipairs({...}) do
            s = s .." " .. tostring(v)
        end
        return s
    end

    function table.getvalue(value, tbl)
        if tbl==nil or value == nil then return nil end
        if type(tbl) ~= "table" then
            if tostring(value) == tostring(tbl) then return value else return nil end
        end
        for _, v in ipairs(tbl) do
            if v == value then return v end
        end
        return nil
    end

    function table.add_values(tbl, key, val)
        tbl[key] = (tbl[key] or 0) + val
        return tbl
    end

    function table.getcount(tbl)
        local i = 0
        for _,_ in pairs(tbl) do
            i = i + 1
        end
        return i
    end
