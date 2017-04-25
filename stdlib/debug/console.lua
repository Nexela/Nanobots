local USE_FALLBACK_INTERFACE = false

--Console Code from adil modified for use with STDlib
require("stdlib.gui.gui")

local function create_gui_player(player)
    if player.gui.left.console then player.gui.left.console.destroy() end
    local c=player.gui.left.add{type='frame',name='console',direction='horizontal'}
    local t = c.add{type='textfield',name='console_line'}
    t.style.minimal_width=600
    t.style.maximal_width=600
    c.add{type='button', name='console_enter',caption='<', tooltip="Run Script"}
    c.add{type='button', name='console_clear', caption='C', tooltip="Clear Input"}
    c.add{type='button', name ='console_close', caption="X", tooltip="Close"}
end

--console.create_gui = function(player)
local function create_gui(player)
    --if not sent with a player, then enable for all players?
    if not (player and player.valid) then
        for _, cur_player in pairs(game.players) do
            create_gui_player(cur_player)
        end
    else
        create_gui_player(player)
    end
end

local function handler(event)
    local i=event.element.player_index
    local p=game.players[event.player_index]
    --if second then second=false return end
    local s=p.gui.left.console.console_line.text
    assert(loadstring(s))()
    game.write_file('console.log',s..'\n',true,i)
end
Gui.on_click("console_enter", handler)

local function close(event)
    local p = game.players[event.player_index]
    p.gui.left.console.destroy()
end
Gui.on_click("console_close", close)

local function clear(event)
    local p = game.players[event.player_index]
    p.gui.left.console.console_line.text = ""
end
Gui.on_click("console_clear", clear)

--Fallback interface --- set USE_FALLBACK_INTERACE = true and
--just using a require("path.to.console") in your control will
--create the console interface, this interface is only recomended for local testing.
--If more then 1 mod adds it, the first mod to add it will be the enviorment used
if USE_FALLBACK_INTERFACE and not remote.interfaces.console then
    remote.add_interface("console", {show = function(player) create_gui(player) end})
end

--return the create_gui function
--example usage:
--remote.add_interface("my_interface", {show=require("path.to.console")})
--/c remote.call("my_interface", "show", game.player)
return create_gui
