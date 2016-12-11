--luacheck: ignore List
-- local serpent = require("serpent")
-- List = {}
--
-- function List.new ()
--   return {first = 1, last = 0}
-- end
--
-- function List.count(list)
--   if list.first > list.last then return 0
--   else return list.last - list.first + 1 end
-- end
--
-- function List.push_left (list, value)
--   local first = list.first - 1
--   list.first = first
--   list[first] = value
-- end
--
-- function List.push_right (list, value)
--   local last = list.last + 1
--   list.last = last
--   list[last] = value
-- end
--
-- function List.pop_left (list)
--   local first = list.first
--   if first > list.last then return nil end
--   local value = list[first]
--   list[first] = nil        -- to allow garbage collection
--   list.first = first + 1
--   return value
-- end
--
-- function List.pop_right (list)
--   local last = list.last
--   if list.first > last then return nil end
--   local value = list[last]
--   list[last] = nil         -- to allow garbage collection
--   list.last = last - 1
--   return value
-- end
--
-- function List.peek_left(list)
--   return list[list.first]
-- end
--
-- function List.peek_right(list)
--   return list[list.last]
-- end
--
-- local test = List.new()
--
-- print(List.count(test))
-- List.push_right(test, {item="ItemA", name="NameA"})
-- print(List.count(test))
-- List.push_right(test, {item="ItemB", name="NameB"})
-- print(List.count(test))
-- List.push_right(test, {item="ItemC", name="NameC"})
-- print(List.count(test))
-- List.pop_left(test)
-- print(List.count(test))
-- List.pop_left(test)
-- print(List.count(test))
-- List.pop_left(test)
-- print(List.count(test))
-- print(List.count(test))
-- List.push_right(test, {item="ItemA", name="NameA"})
-- print(List.count(test))
-- List.push_right(test, {item="ItemB", name="NameB"})
-- print(List.count(test))
-- List.push_right(test, {item="ItemC", name="NameC"})
-- print(List.count(test) .. "-".. test.first .. "-" .. test.last)


function table.find(tbl, func, ...)
    for k, v in pairs(tbl) do
        if func(v, k, ...) then
            return v, k
        end
    end
    return nil
end

local a = {["iron-chest"]="yes"}

print(table.find(a, function(k) return k end))
