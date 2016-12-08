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
if _G.bobmods and _G.bobmods.lib then
  _G.bobmods.lib.recipe.replace_ingredient("ammo-nano-constructors", "electronic-circuit", "basic-circuit-board")
  _G.bobmods.lib.recipe.add_ingredient("equipment-bot-chip-items", "robot-brain-constuction")
  _G.bobmods.lib.recipe.add_ingredient("equipment-bot-chip-trees", "robot-brain-constuction")
end
