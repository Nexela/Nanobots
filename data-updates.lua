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
