local OreProcessing = {}

--library pulls
local component = require("component")
local serialization = require("serialization")
local colors = require("lib.graphics.colors")
local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")

--variable initializations
local transposer = {}
local editorPage
local 

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
        oreAddr = serialization.unserialize(file:read("*a")) or {}
        file:close()
    end
end

local function getName(filter)
    return string.gmatch(filter, "[^%|]+")()
end

local function

local refresh = nil
local currentConfigWindow = {}
--changes config window values
local function changeAddr(transposerAddress, indexNumber, data)
    if transposerAddress == "None" then
        oreAddr[indexNumber] = "None"
        transposer[indexNumber] = nil
    else
        oreAddr[indexNumber] = transposerAddress
        transposer[indexNumber] = component.proxy(component.get(transposerAddress))
    end
    local x, y, gui, graphics, renderer, page = table.unpack(data)
    renderer.removeObject(currentConfigWindow)
    refresh(x, y, gui, graphics, renderer, page)
end

--provides configuration page from main menu
function OreProcessing.configure(x, y, gui, graphics, renderer, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    local onActivation = {}
    graphics.context().gpu.setActiveBuffer(page)
    for address, componentType in component.list() do
        if componentType == "transposer" then
            table.insert(onActivation, {displayName = displayName, value = changeAddr, args = {address, number, renderingData}})
        end
    end
    table.insert(onActivation, {displayName = "None", value = changeAddr, args = {"None", renderingData}})
    for i=1, 2 do
        table.insert(currentConfigWindow, graphics.text(3,(i * 2) + 3, "Transposer "..tostring(i)..":"))
        table.insert(currentConfigWindow, gui.smallButton(x+15, y+2, oreAddr[i] or "None", gui.selectionBox, {x+16, y+i+1, onActivation}))
    end
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    renderer.update()
    return currentConfigWindow
end
--provides the button to access filter page
function OreProcessing.windowButton()
    return {name = "Ore Filters", func = } --TODO fill in function value, pulls up filter window
end
--main loop
function OreProcessing.update()
end