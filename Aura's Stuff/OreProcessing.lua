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
    local file = io.open("/home/NIDAS/settings/oreAddr", "w")
    file:write(serialization.serialize(oreAddr))
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
    local file = io.open("/home/NIDAS/settings/oreAddr", "r")
    if file then
        oreAddr = serialization.unserialize(file:read("*a")) or {} --TODO get this to work
        file:close()
    end
end
local refresh = nil
local currentConfigWindow = {}
--changes config window values
local function changeAddr(transposerAddress, indexNumber, data)
    if transposerAddress == "None" then
        --TODO this
    else
        --TODO this
        oreAddr[indexNumber] = transposerAddress
    end
    local x, y, gui, graphics, renderer, page = table.unpack(data)
    renderer.removeObject(currentConfigWindow)
    refresh(x, y, gui, graphics, renderer, page)
end

--provides configuration page from main menu
function OreProcessing.configure(x, y, gui, graphics, renderer, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    local number = 1
    local onActivation = {}
    graphics.context().gpu.setActiveBuffer(page)
    graphics.text(3, 5, "Transposer 1:")
    graphics.text(3, 7, "Transposer 2:")
    for address, componentType in component.list() do
        if componentType == "transposer" then
            table.insert(onActivation, {displayName = displayName, value = changeAddr, args = {address, number, renderingData}})
        end
    end
    table.insert(onActivation, {displayName = "None", value = changeAddr, args = {"None", renderingData}})
    table.insert(currentConfigWindow, gui.smallButton(x+15, y+2, oreAddr[1] or "None", gui.selectionBox, {x+16, y+2, onActivation}))
    local number = 2
    table.insert(currentConfigWindow, gui.smallButton(x+15, y+3, oreAddr.[2] or "None", gui.selectionBox, {x+16, y+3, onActivation}))
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    
    renderer.update()
    return currentConfigWindow
end
--provides the button to access filter page
function OreProcessing.windowButton()\
    return {name = "Ore Filters", func = } --TODO fill in function value
end
--main loop
function OreProcessing.update()
end