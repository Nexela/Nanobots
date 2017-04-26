--bobmods recipe changes
if bobmods and bobmods.lib then
    local replace = bobmods.lib.recipe.replace_ingredient
    local add = bobmods.lib.recipe.add_ingredient

    replace("gun-nano-emitter", "electronic-circuit", "basic-circuit-board")
    replace("ammo-nano-constructors", "electronic-circuit", "basic-circuit-board")
    replace("ammo-nano-termites", "electronic-circuit", "basic-circuit-board")
    replace("ammo-nano-scrappers", "electronic-circuit", "basic-circuit-board")
    replace("ammo-nano-deconstructors", "advanced-circuit", "electronic-circuit")

    add("equipment-bot-chip-items", "robot-brain-constuction")
    add("equipment-bot-chip-trees", "robot-brain-constuction")
    add("equipment-bot-chip-nanointerface", "robot-brain-constuction")
    add("equipment-bot-chip-nanointerface", "gun-nano-emitter")
    add("equipment-bot-chip-launcher", "robot-brain-combat")
    add("equipment-bot-chip-feeder", "robot-brain-combat")
    add("belt-immunity-equipment", "robot-brain-construction")
end
