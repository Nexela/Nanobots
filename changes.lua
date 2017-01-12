--Special file for on_configuration_changed
--versions os passed as paramaters for the functions containing new_version and old_version
local changes = {}

changes["1.2.0"] = function (versions)
  global.current_index = 1
  global.config = global.config or table.deepcopy(MOD.config.control)
  remote.call("nanobots", "reset_config")
  global._changes = global._changes or {}
  global._changes["1.2.0"] = {from = versions.old_version}
end

return changes
