local num_players = 120
local count = 0
for i = 0, 60*10-1 do
  if i % math.max(0, math.floor(60 / num_players)) == 0 then
    count = count + 1
    print(i, count)
  end
end
