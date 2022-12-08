local Nanobots = {}
local Player = require("scripts/player")
local max, floor = math.max, math.floor
local NANO_EMITTER = "gun-nano-emitter"
local AMMO_CONSTRUCTORS = "ammo-nano-constructors"
local AMMO_TERMITES = "ammo-nano-termites"

--- Is the player ready?
--- @param player LuaPlayer
--- @return boolean
local function is_ready(player)
  return player.afk_time <= (60 * 5)
end

--- Get the ammo
--- @param character LuaEntity
--- @return LuaItemStack?
--- @return string
local function get_ammo(pdata, character)
  local gun_inventory = pdata.gun_inventory --[[@as LuaInventory]]
  if not gun_inventory then return nil, "none" end
  local ammo_inventory = pdata.ammo_inventory --[[@as LuaInventory]]
  local index = character.selected_gun_index
  local gun = gun_inventory[index]
  if gun.valid_for_read and gun.name == NANO_EMITTER then
    local ammo = ammo_inventory[index]
    if ammo.valid_for_read then
      return ammo, ammo.name
    end
  end
  return nil, "none"
end

--- Manually drain ammo, if it is the last bit of ammo in the stack pull in more ammo from inventory if available
--- @param player LuaPlayer the player object
--- @param ammo LuaItemStack the ammo itemstack
--- @param amount? float
--- @return boolean #Ammo was fully drained
local function drain_ammo(player, ammo, amount)
  if player.cheat_mode then return true end

  amount = amount or 1.0
  local name = ammo.name
  ammo.drain_ammo(amount)
  if not ammo.valid_for_read then
    local new = player.get_main_inventory().find_item_stack(name)
    if new then
      ammo.set_stack(new) -- swap_stack?
      new.clear()
    end
    return true
  end
  return false
end

--- The range indicator, only shows in alt mode, when ammo is available.
--- @todo Add a setting to disable this.
--- @param player LuaPlayer
--- @param pdata Nanobots.pdata
--- @param character LuaEntity
local function draw_range_overlay(player, pdata, character)
  if not (pdata.range_indicator and rendering.is_valid(pdata.range_indicator)) then
    pdata.range_indicator = rendering.draw_circle {
      color = { r = 0.0, g = 0.1, b = 0.0, a = 0.05 },
      radius = global.gun_range,
      filled = true,
      target = character,
      surface = character.surface,
      players = { player },
      draw_on_ground = true,
      only_in_alt_mode = true,
    }
  end
end

--- @param player LuaPlayer
--- @param character LuaEntity
local function queue_ghosts_in_range(player, pdata, character, ammo, radius)
  local player_force = player.force
  local surface = character.surface
  local entities = surface.find_entities_filtered { radius = radius, position = character.position }
  local counter = 0

  for _, entity in ipairs(entities) do
    if not ammo.valid_for_read then return end
    if counter > 9 then return end


    local entity_force = entity.force --[[@as LuaForce]]
    local friendly_force = entity_force.is_friend(player_force)
    if not friendly_force then goto next_ghost end

    local deconstruct = friendly_force and entity.to_be_deconstructed()
    local upgrade = friendly_force and entity.to_be_upgraded()

    local data = {}

    if deconstruct then
      if entity.type == "cliff" then
      elseif entity.minable then
      end
    elseif upgrade then
      local prototype = entity.get_upgrade_target()
      if prototype then
        if prototype.name == entity.name then
          local dir = entity.get_upgrade_direction()
          if entity.direction ~= dir then
            data.action = "upgrade_direction"
            data.direction = dir
          end
        else
        end
      end
    elseif entity.name == "entity-ghost" or entity.name == "tile-ghost" then
    elseif entity.health > 0 and entity.health < entity.prototype.max_health then
    elseif entity.name == "item-request-proxy" then
      local items = {}
    end
    ::next_ghost::
  end
end

--- Nano Termites
--- Kill the trees! Kill them dead
--- @param player LuaPlayer
--- @param pos MapPosition
--- @param ammo LuaItemStack
local function everyone_hates_trees(player, pos, ammo)
  local force = player.force --[[@as LuaForce]]
  local surface = player.surface
  for _, stupid_tree in pairs(surface.find_entities_filtered { position = pos, radius = global.gun_range, type = "tree", limit = 200 }) do
    if not ammo.valid_for_read then return end
    if not stupid_tree.to_be_deconstructed then
      if surface.count_entities_filtered { position = stupid_tree.position, radius = 0.5, name = "nano-cloud-small-termites" } == 0 then
        surface.create_entity {
          name = "nano-projectile-termites",
          source = player --[[@as LuaEntity]] ,
          position = pos,
          force = force,
          target = stupid_tree,
          speed = .5
        }
        drain_ammo(player, ammo, 1.0)
      end
    end
  end
end

function Nanobots.on_nth_tick(event)
  local tick = event.tick
  local connected_players = game.connected_players
  local num_players = #connected_players
  local last_player, player = next(connected_players, num_players > 1 and global.last_player or nil)
  local pdata = global.players[player.index]
  global.last_player = last_player

  if not (player and is_ready(player)) then return end

  local character = player.character
  if not character then return end

  local ammo, ammo_name, ammo_radius = get_ammo(pdata, character)
  if not ammo then
    rendering.destroy(pdata.range_indicator or 0)
    return
  end
  draw_range_overlay(player, pdata, character)

  if ammo_name == AMMO_CONSTRUCTORS then
    queue_ghosts_in_range(player, pdata, character, ammo_radius)
  elseif ammo_name == AMMO_TERMITES then
    everyone_hates_trees(player, character.position, ammo)
  end
end

function Nanobots.on_init()
  global.gun_range = game.item_prototypes[NANO_EMITTER].attack_parameters.range
end

function Nanobots.on_configuration_changed()
  global.gun_range = game.item_prototypes[NANO_EMITTER].attack_parameters.range
end

function Nanobots.on_player_gun_inventory_changed(event)
  local player, pdata = Player.get(event.player_index)
  if not ((pdata.ammo_inventory and pdata.ammo_inventory.valid) and (pdata.gun_inventory and pdata.gun_inventory.valid)) then
    pdata.ammo_inventory = player.get_inventory(defines.inventory.character_ammo)
    pdata.gun_inventory = player.get_inventory(defines.inventory.character_guns)
  end
end

return Nanobots

--- @class Nanobots.global
--- @field gun_range float

--- @class Nanobots.pdata
--- @field range_indicator uint
