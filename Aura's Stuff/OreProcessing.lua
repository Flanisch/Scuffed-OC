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
local drawn
local idPages

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


function filterByLabel(data, keyword)
    local filtered = {}
    for key, value in pairs(data) do
        if string.find(string.lower(key), string.lower(keyword)) ~= nil then
            filtered[key] = value
        end
    end
    return filtered
end

local function displayFilters(filterString)
    filterString = filterString or ""
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local height = context.height - 2
    local topHeight = 6
    local maxEntries = height - topHeight - 3
    context.gpu.fill(1, topHeight, middle - 1, height, " ")
    local function formCurrentView(filters)
        if idPages ~= nil then
            renderer.removeObject(idPages)
        end
        local buttons = {}
        for k, _ in pairs(filters) do
            label = filters[k]
            table.insert(
                buttons,
                {name = label.name, func = modifyFilter, args = {k}}
            )
            if k > maxEntries then break end
        end
        idPages = gui.multiButtonList(x, y, buttons, width, height, "Filters", colors.white, true)
        context.gpu.setActiveBuffer(0)                          --displayFilters() up to here is eh??? potentially needs debugging
    end
    local filteredFilters = filterByLabel(oreFilters, filterString)
    formCurrentView(filteredFilters)
    renderer.update(idPages)
end
--[[

ok
so
oreFilters is a table with the following format:
oreFilters {
    1   {name = [name of ore], filter = [1-7]}
}
the filters are:
1: primary output (macerate-centrifuge-output)
2: purify with orewasher (orewash-recycle)
3: purify with chembath with mercury (chembath-recycle)
4: tertiary output (thermal centrifuge-macerate-output)
5: primary-smelt (smelt-macerate-package-output)
6: sift (sift-output)
7: special (output)


]]
--main window draw
local function displayWindow()
    drawn = true
    load()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    renderer.switchWindow("OreProcessing")
    gui.smallButton(1, (context.height), "< < < Return", returnToMenu, {}, nil, gui.primaryColor())
    context.gpu.setActiveBuffer(renderer.createObject(math.floor(context.width / 4) - 3, 2, 7, 1, true))
    graphics.text(context.width / 4 - 3, 5, "Filters", colors.white)
    --draw lower divider
    context.gpu.setActiveBuffer(renderer.createObject(1, context.height - 1, context.width, 1))
    local bar = "▂▂▂"
    for i = 1, context.width - 6 do bar = bar .. "▄" end
    local bar = bar .. "▂▂▂"
    graphics.text(1, 1, bar, gui.borderColor())
    --draw middle divider
    context.gpu.setActiveBuffer(renderer.createObject(middle, 1, 1, context.height - 1))
    for i=1, context.height - 2 do
        graphics.text(middle, i, "▐", gui.borderColor())
    end
    graphics.text(middle, context.height - 1, "▟", gui.borderColor())
    context.gpu.setActiveBuffer(0)
    --TODO rest of window draw
end

local function returnToMenu()
    drawn = false
    renderer.switchWindow("main")
    renderer.clearWindow("OreProcessing")
    renderer.update()
end


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
        graphics.text(3, (i * 2) + 3, "Transposer "..tostring(i)..":")
        table.insert(currentConfigWindow, gui.smallButton(x+15, y+2, oreAddr[i] or "None", gui.selectionBox, {x+16, y+i+1, onActivation}))
    end
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    renderer.update()
    return currentConfigWindow
end
--provides the button to access filter page
function OreProcessing.windowButton()
    return {name = "Ore Filters", func = displayWindow}
end
--main loop
function OreProcessing.update()
    --TODO this
end

return OreProcessing