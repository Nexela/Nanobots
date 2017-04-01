-------------------------------------------------------------------------------
--[[robointerface]]
-------------------------------------------------------------------------------
local robointerface = {}

--[[
raw-wood-cutting, scan for trees, if value is negative only scan for trees if wood in network is less then that amount
tile-item, scan for tiles, only checks first signal, if negative, will not place tiles unless that many are in network.
item-on-ground-sig, Scan for items on ground, if found cell will check for items-ground and mark for pickup if no enemies in range
networks-sig

parameters = {
  {
    count = 1,
    index = 1,
    signal = {
      name = "nano-signal-item-on-ground",
      type = "virtual"
    }
  },
  {
    count = 1,
    index = 2,
    signal = {
      type = "item"
    }
  },

]]

function robointerface.new(entity)
    return {
        name = entity.name,
        unit_number = entity.unit_number,
        entity = entity,
    }
end

local function run_interface(interface)
    local behaviour = interface.entity.get_control_behavior()
    if behaviour and behaviour.enabled then

    end
end

local function destroy_roboport_interface(event)
    if event.entity.name == "roboport-interface" then
        global.robointerfaces[event.entity.unit_number] = nil
    end
end
Event.register(Event.death_events, destroy_roboport_interface)

local function build_roboport_interface(event)
    if event.created_entity.name == "roboport-interface" then
        local interface = robointerface.new(event.created_entity)
        global.robointerfaces[interface.unit_number] = interface
    end
end
Event.register(Event.build_events, build_roboport_interface)

--Process 1 interface every 60 ticks
local function roboport_interface_tick(event)
    if event.tick % 60 == 0 then
        local index, interface = next(global.robointerfaces, global._next_interface)
        if index then
            if interface and interface.entity.valid then
                run_interface(interface)
            else
                interface[index] = nil
            end
        end
        global._next_interface = index
    end
end
Event.register(defines.events.on_tick, roboport_interface_tick)

function robointerface.init()
    local interfaces = {}
    for _, surface in pairs(game.surfaces) do
        for _, interface in pairs(surface.find_entities_filtered{name = "roboport-interface"}) do
            interfaces[interface.unit_number] = robointerface.new(interface)
        end
    end
    return interfaces
end

return robointerface
