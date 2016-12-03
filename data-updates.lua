--Change blueprint to use electronic-circuit for earlier building
data.raw.recipe["blueprint"].ingredients = {{"electronic-circuit", 1}}

--Add unlock for blueprint to automation.
local effects = data.raw.technology["automation"].effects
effects[#effects + 1] = {type = "unlock-recipe", recipe="blueprint"}
