local List = require("stdlib/utils/list")

local interface = {}

function interface.reset()
  _G.on_init()
  interface.destroy_proxies()
  game.print(MOD.name..": Reset Complete.")
end

function interface.add_to_queue(data)
  if data and type(data) =="table" and data.action then
    List.push_right(global.queue, data)
    return true
  end
end

function interface.config(key, value, silent)
  local config = Config.new(global.config)
  if key then
    if key == "reset" then
      global.config = MOD.config.control
      if not silent then game.print(MOD.name.." Reset config to default.") end
      return true
    end
    --key=string.upper(key)
    if config.get(key) ~= nil then
      if value ~= nil then
        config.set(key, value)
        local val=config.get(key)
        if not silent then game.print(MOD.name .. ": New value for '" .. key .. "' is " .. "'" .. tostring(val) .."'") end
        return val-- all is well
      else --value nil
        local val = config.get(key)
        if not silent then game.print(MOD.name .. ": Current value for '" .. key .. "' is " .. "'" .. tostring(val) .."'") end
        return val
      end
    else --key is nill
      if not silent then game.print(MOD.name ..": Config '" .. key .. "' does not exist") end
      return nil
    end
  else
    if not silent then
      game.print(MOD.name .. ": Config requires a key name")
      game.print(serpent.line(global.config))
    end
    return nil
  end
end

function interface.print_global(name)
  if name and type(name) == "string" then
    game.print(name.."="..serpent.block(global[name], {comment=false, sparse=true}))
    game.write_file("/logs/Nanobots/global.log", name.."="..serpent.block(global[name], {comment=false, sparse=true}))
  else
    game.print(serpent.block(global, {comment=false, sparse=true}))
    game.write_file("/logs/Nanobots/global.log", serpent.block(global, {comment=false, sparse=true}))
  end
end

function interface.get_queue()
  return(global.queue)
end

-- Turn toggle or set the tick handlers on or off
-- @param handler: the handler string to set or toggle, "tick", "nanobots", "equipment"
-- @param value: bool (opt): will toggle when nil or set the handler to the bool value
-- @return bool: the new value or nil if wrong handler
function interface.toggle_handlers(handler, value, silent)
  local map = {
    tick="run_ticks", nanobots="auto_nanobots", equipment="auto_equipment",
    run_ticks="run_ticks", auto_nanobots="auto_nanobots", auto_equipment="auto_equipment"
  }
  handler = map[handler]
  if handler then
    local config = Config.new(global.config)
    config.set(handler, (type(value) == "bool" and value) or not config.get(handler, true))
    if not silent then game.print(config.get(handler)) end
    return config.get(handler)
  else
    game.print(MOD.name..": Handler not valid, must be tick, nanobots, equipment")
  end
end

function interface.destroy_proxies()
  global.kill_proxy = {}
  for _, surface in pairs(game.surfaces) do
    for _, ent in pairs(surface.find_entities_filtered{name="nano-target-proxy",type="simple-entity"}) do
      ent.destroy()
    end
  end
  game.print(MOD.name..": All target proxies destroyed.")
end

function interface.test()
  local config = Config.new(global.config)
  config.set("tick_mod", 10)
  config.set("ticks_per_queue", 1)
  game.print(MOD.name..": Test mode enabled")
end

if _G.DEBUG then
  interface.console = require("stdlib/utils/console")
end

--Register with creative-mode for easy testing
if remote.interfaces["creative-mode"] and remote.interfaces["creative-mode"]["register_remote_function_to_modding_ui"] then
  log("Nanobots - Registering with Creative Mode")
  remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "print_global")
  remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "reset")
  remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "destroy_proxies")
  remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "test")
  if _G.DEBUG then
    remote.call("creative-mode", "register_remote_function_to_modding_ui", MOD.interface, "console")
  end
end

return interface
