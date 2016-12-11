--[[
TODO log levels
   -1, instant error()
   0 off
   1, print and log
   2, log only
   3, warn log only
   4, info log only
]]

function doDebug(msg, alert)
    local level = MOD.config.get("LOGLEVEL", 1)
    if level == 0 and not alert then return end

    if (level >= 1 or alert) and type(msg) == "table" then
                MOD.logfile.log("vvvvvvvvvvvvvvvvvvvvvvv--Begin Serpent Block--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv")
                MOD.logfile.log(serpent.block(msg, {comment=false}))
                MOD.logfile.log("^^^^^^^^^^^^^^^^^^^^^^^--End   Serpent Block--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
            else
                MOD.logfile.log(tostring(msg))
            end
    if (level >= 2 or alert) and game then
        game.print(MOD.IF .. ":" .. table.tostring(msg))
    end
end
doDebug("vvvvvvvvvvvvvvvvvvvvvvv--Begin Logging--vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv") --Start the debug log with a header
