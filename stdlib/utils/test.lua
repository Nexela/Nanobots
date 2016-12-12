-- luacheck: ignore List
local serpent = require("serpent")
local List = require("stdlib/utils/list")

local test = List.new()

print(List.count(test))
List.push_right(test, {item="ItemA", name="NameA"})
print(List.count(test))
List.push_right(test, {item="ItemB", name="NameB"})
print(List.count(test))
List.push_right(test, {item="ItemC", name="NameC"})
print(List.count(test))
List.pop_left(test)
print(List.count(test))
List.pop_left(test)
print(List.count(test))
List.pop_left(test)
print(List.count(test))
print(List.count(test))
List.push_right(test, {item="ItemA", name="NameA"})
print(List.count(test))
List.push_right(test, {item="ItemB", name="NameB"})
print(List.count(test))
List.push_right(test, {item="ItemC", name="NameC"})
print(List.count(test) .. "-".. test.first .. "-" .. test.last)

require("stdlib/table")
local find=table.find
-- local function find(tbl, func, ...)
--     for k, v in pairs(tbl) do
--         if func(v, k, ...) then
--             return v, k
--         end
--     end
--     return nil
-- end

local count = {["iron-chest"] = 0, ["steel-chest"]=0}
local function get_count(item) return count[item] or 0 end

print(get_count("iron-chest"))
print(get_count("steel-chest"))

local a = {["iron-chest"]={}, ["steel-chest"]={}}

print(find(a, function(_, k) return get_count(k) > 0 end))
