local OreProcessing = {}

--library pulls
local component = require("component")
local serialization = require("serialization")
local colors = require("lib.graphics.colors")
local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")

--variable initializations


local function save()
    local file = io.open("/home/NIDAS/settings/oreFilters", "w")
    file:write(serialization.serialize(oreFilters))
    file:close()
    --windowRefresh(searchKey.keyword)          Do I need this? Idk what it does
end

local function load()
    local file = io.open("/home/NIDAS/settings/oreFilters", "r")
    if file then
        oreFilters = serialization.unserialize(file:read("*a")) or {}
        file:close()
        renderer.update()
    end
end


--provides configuration page from main menu
function OreProcessing.configure(x, y, gui, graphics, renderer, page)
    local availabletransposers = {}
    for address, componentType in component.list() do
        if componentType == "transposer" then
            table.insert(availabletransposers, address)
        end
    end
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
end
--provides the button to access filter page
function OreProcessing.windowButton()\
    return {name = "Ore Filters", func = } --TODO fill in function value
end
--main loop
function OreProcessing.update()
end