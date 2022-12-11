local Nanobots = {}

local Player = require("scripts/player")
local Inventory = require("scripts/inventory")
local Constants = require("scripts/constants")
local Actions = require("scripts/actions")

local MOVEABLE_TYPES = Constants.MOVEABLE_TYPES
local BLOCKABLE_TYPES = Constants.BLOCKABLE_TYPES
local EXPLOSIVES = Constants.EXPLOSIVES
local NANO_EMITTER = Constants.NANO_EMITTER
local AMMO_CONSTRUCTORS = Constants.AMMO_CONSTRUCTORS
local AMMO_TERMITES = Constants.AMMO_TERMITES

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

--- Can nanobots repair this entity?
--- @param entity LuaEntity
--- @return boolean
local function is_nanobot_repairable(entity)
  if (entity.get_health_ratio() or 1) >= 1 then return false end
  if entity.has_flag("not-repairable") or entity.type:find("robot") then return false end
  if BLOCKABLE_TYPES[entity.type] and entity.minable == false then return false end
  if MOVEABLE_TYPES[entity.type] and entity.speed > 0 then return false end
  return table_size(entity.prototype.collision_mask) > 0
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
  local entities = surface.find_entities_filtered { radius = radius, position = character.position, type = "resource", invert = true, limit = 1000 }
  local cheat_mode = player.cheat_mode
  local counter = 0

  for _, entity in ipairs(entities) do
    if not (ammo and ammo.valid_for_read) then return end
    if counter > 100 then return end

    local entity_force = entity.force --[[@as LuaForce]]
    local friendly_force = entity_force.is_friend(player_force)
    if not friendly_force then goto next_ghost end

    local deconstruct = friendly_force and entity.to_be_deconstructed()
    local upgrade = friendly_force and entity.to_be_upgraded()

    --- @class Nanobots.action_data
    local function new_data(action, item_stack)
      counter = counter + 1
      return {
        action = action, ---@type string
        item_stack = item_stack, ---@type LuaItemStack
        player_index = player.index, ---@type uint
        player = player, ---@type LuaPlayer
        ammo = ammo, ---@type LuaItemStack
        entity = entity, ---@type LuaEntity
        position = entity.position, ---@type MapPosition
        surface = surface, ---@type LuaSurface
        unit_number = entity.unit_number, ---@type uint
        force = entity_force ---@type LuaForce
      }
    end

    if deconstruct then
      if entity.type == "cliff" then
        if player_force.technologies["nanobots-cliff"].researched then
          local item_stack = Inventory.find_item(player, EXPLOSIVES, cheat_mode)
          if item_stack then
            local explosive = Inventory.get_item_stack(player, item_stack, cheat_mode)
            if explosive then
              local data = new_data("cliff_deconstruction", explosive)
              -- queue:insert(data, get_next_tick())
              Actions[data.action](data)
              drain_ammo(player, ammo, 1.0)
            end
          end
        end
      elseif entity.minable then
        local data = new_data("deconstruction")
        -- queue:insert(data, get_next_tick())
        Actions[data.action](data)
        drain_ammo(player, ammo, 1.0)
      end
    elseif upgrade then
      local prototype = entity.get_upgrade_target()
      if prototype then
        if prototype.name == entity.name then
          local dir = entity.get_upgrade_direction()
          if entity.direction ~= dir then
            local data = new_data("upgrade_direction")
            data.direction = dir
            -- queue:insert(data, get_next_tick())
            Actions[data.action](data)
            drain_ammo(player, ammo, 1.0)
          end
        else
          local item_stack = Inventory.find_item(player, prototype.items_to_place_this, cheat_mode)
          if item_stack then
            local place_item = Inventory.get_item_stack(player, item_stack, cheat_mode)
            if place_item then
              local data = new_data("upgrade_ghost", place_item)
              data.entity_name = prototype.name
              -- queue:insert(data, get_next_tick())
              Actions[data.action](data)
              drain_ammo(player, ammo, 1.0)
            end
          end
        end
      end
    elseif entity.name == "entity-ghost" or entity.name == "tile-ghost" then
      local prototype = entity.ghost_prototype
      local item_stack = Inventory.find_item(player, prototype.items_to_place_this, cheat_mode)
      if item_stack then
        if entity.name == "entity-ghost" then
          local place_item = Inventory.get_item_stack(player, item_stack, cheat_mode)
          if place_item then
            local data = new_data("build_entity_ghost", place_item)
            -- queue:insert(data, get_next_tick())
            Actions[data.action](data)
            drain_ammo(player, ammo, 1.0)
          end
        elseif entity.name == "tile-ghost" then
          -- Don't queue tile ghosts if entity ghost is on top of it.
          if surface.count_entities_filtered { name = "entity-ghost", area = entity.selection_box, limit = 1 } == 0 then
            local tile = surface.get_tile(entity.position--[[@as TilePosition]] )
            local place_item = Inventory.get_item_stack(player, item_stack, cheat_mode)
            if place_item then
              local data = new_data("build_tile_ghost, place_item")
              data.tile = tile
              -- queue:insert(data, get_next_tick())
              Actions[data.action](data)
              drain_ammo(player, ammo, 1.0)
            end
          end
        end
      end
    elseif is_nanobot_repairable(entity) then
      if surface.count_entities_filtered { name = "nano-cloud-small-repair", position = entity.position } == 0 then
        local data = new_data("repair_entity")
        -- queue:insert(data, get_next_tick())
        Actions[data.action](data)
        drain_ammo(player, ammo, 1.0)
      end
    elseif entity.name == "item-request-proxy" then
      local items = {}
      for item, count in pairs(entity.item_requests) do items[#items + 1] = { name = item, count = count } end
      local item_stack = Inventory.find_item(player, items, cheat_mode, true)
      if item_stack then
        local place_item = Inventory.get_item_stack(player, item_stack, cheat_mode, true)
        if place_item then
          local data = new_data("item_requests", place_item)
          -- queue:insert(data, get_next_tick())
          Actions[data.action](data)
          drain_ammo(player, ammo, 1.0)
        end
      end
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
      queue_ghosts_in_range(player, pdata, character, ammo, pdata.gun_range)
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
