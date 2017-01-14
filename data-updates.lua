--luacheck: globals bobmods
--Change blueprint to use electronic-circuit for earlier building
data.raw.recipe["blueprint"].ingredients = {{"electronic-circuit", 1}}
data.raw.recipe["deconstruction-planner"].ingredients = {{"electronic-circuit", 1}}

--Change automated construction to unlock after automation, using science pack 1
local tech = data.raw.technology["automated-construction"]
tech.prerequisites = {"automation"}
tech.unit =
{
  count = 75,
  ingredients =
  {
    {"science-pack-1", 1},
  },
  time = 30
}

--bobmods recipe changes
if bobmods and bobmods.lib then
  local replace = bobmods.lib.recipe.replace_ingredient
  local add = bobmods.lib.recipe.add_ingredient
  replace("gun-nano-emitter", "electronic-circuit", "basic-circuit-board")
  replace("ammo-nano-constructors", "electronic-circuit", "basic-circuit-board")
  --replace("ammo-nano-scrappers", "electronic-circuit", "basic-circuit-board")
  replace("ammo-nano-termites", "electronic-circuit", "basic-circuit-board")
  add("equipment-bot-chip-items", "robot-brain-constuction")
  add("equipment-bot-chip-trees", "robot-brain-constuction")
end
