local Nanobots = {}

local Player = require("scripts/player")

local NANO_EMITTER = "gun-nano-emitter"
local AMMO_CONSTRUCTORS = "ammo-nano-constructors"
local AMMO_TERMITES = "ammo-nano-termites"
local max, floor = math.max, math.floor

--- Is the player ready?
--- @param player LuaPlayer
--- @return boolean
local function is_ready(player)
  return player.afk_time <= (60 * 5)
end

--- @param pdata Nanobots.pdata
--- @param character LuaEntity
--- @return LuaItemStack?, uint?
local function get_gun(pdata, character)
  local gun_inventory = pdata.gun_inventory
  if not (gun_inventory and gun_inventory.valid) then
    gun_inventory = character.get_inventory(defines.inventory.character_guns)
    pdata.gun_inventory = gun_inventory
    if not gun_inventory then return end
  end

  local index = character.selected_gun_index
  local gun = gun_inventory[index]
  if not (gun.valid_for_read and gun.name == NANO_EMITTER) then return end

  if not pdata.gun_range then
    pdata.gun_range = gun.prototype.attack_parameters.range
  end

  return gun, index
end

--- Get the ammo
--- Additionally stores the gun and ammo inventories to avoid creating objects.
--- @param pdata Nanobots.pdata
--- @param character LuaEntity
--- @return LuaItemStack?, string
local function get_ammo(pdata, character)
  local gun, index = get_gun(pdata, character)
  if not gun then return nil, "" end

  local ammo_inventory = pdata.ammo_inventory
  if not (ammo_inventory and ammo_inventory.valid) then
    ammo_inventory = character.get_inventory(defines.inventory.character_ammo)
    pdata.ammo_inventory = ammo_inventory
    if not ammo_inventory then return nil, "none" end
  end

  local ammo = ammo_inventory[index]
  if not ammo.valid_for_read then return nil, "" end

  return ammo, ammo.name
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
    if new then return ammo.swap_stack(new) end
  end
  return false
end

--- The range indicator, only shows in alt mode, when ammo is available.
--- @todo Add a setting to disable this.
--- @param player LuaPlayer
--- @param pdata Nanobots.pdata
--- @param character LuaEntity
local function draw_range_overlay(player, pdata, character, color)
  if not (pdata.range_indicator and rendering.is_valid(pdata.range_indicator)) then
    pdata.range_indicator = rendering.draw_circle {
      color = color,
      radius = pdata.gun_range,
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
    if not (ammo and ammo.valid_for_read) then return end
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
--- @param pdata Nanobots.pdata
--- @param character LuaEntity
--- @param ammo LuaItemStack
local function everyone_hates_trees(player, pdata, character, ammo)
  local force = player.force --[[@as LuaForce]]
  local surface = player.surface
  local position = character.position
  local trees = surface.find_entities_filtered { position = position, radius = pdata.gun_range, type = "tree", limit = 200 }
  for _, stupid_tree in pairs(trees) do
    if not (ammo and ammo.valid_for_read) then return end
    if not stupid_tree.to_be_deconstructed() then
      if surface.count_entities_filtered { position = stupid_tree.position, radius = 0.5, name = "nano-cloud-small-termites" } == 0 then
        surface.create_entity {
          name = "nano-projectile-termites",
          source = character,
          position = position,
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
  pcall(function()
    local tick = event.tick
    local connected_players = game.connected_players
    local num_players = #connected_players
    local last_player, player = next(connected_players, num_players > 1 and global.last_player or nil)
    local pdata = global.players[player.index]
    global.last_player = last_player

    if not (player and is_ready(player)) then return end

    local character = player.character
    if not character then return end

    local ammo, ammo_name = get_ammo(pdata, character)
    if not ammo then return rendering.destroy(pdata.range_indicator or 0) end

    if ammo_name == AMMO_CONSTRUCTORS then
      draw_range_overlay(player, pdata, character, { 0, 0, .1, .1 })
      queue_ghosts_in_range(player, pdata, character)
    elseif ammo_name == AMMO_TERMITES then
      draw_range_overlay(player, pdata, character, { 0, .1, 0, .1 })
      everyone_hates_trees(player, pdata, character, ammo)
    end
  end)
end

--- @param event EventData.on_player_gun_inventory_changed
function Nanobots.on_player_gun_inventory_changed(event)
  local player, pdata = Player.get(event.player_index)
  local character = player.character
  if not character then return end

  pdata.gun_range = nil
  local gun = get_gun(pdata, character)
end

return Nanobots

--- @class Nanobots.global

--- @class Nanobots.pdata
--- @field range_indicator uint64
--- @field gun_range float
