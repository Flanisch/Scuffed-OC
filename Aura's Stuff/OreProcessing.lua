local OreProcessing = {}

--library pulls
local component = require("component")
local serialization = require("serialization")
local colors = require("lib.graphics.colors")
local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")
local renderer = require("lib.graphics.renderer")

--variable initializations
local transposer = {}
local editorPage
drawn = false
local idPages
local oreAddr = {}
local oreFilters = {}
local search = {}
local windowRefresh
local searchKey = {keyword = ""}

local debugnumber = 0
local function debugnum()
    print(debugnumber)
    require("term").setCursor(1,1)
    debugnumber = debugnumber + 1
end
local function save()
    local file = io.open("/home/NIDAS/settings/oreFilters", "w")
    file:write(serialization.serialize(oreFilters))
    file:close()
    local file = io.open("/home/NIDAS/settings/oreAddr", "w")
    file:write(serialization.serialize(oreAddr))
    file:close()
    windowRefresh(searchKey.keyword)
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
        if string.find(string.lower(key.name), string.lower(keyword)) ~= nil then
            filtered[key] = value
        end
    end
    return filtered
end

local function modifyFilter(filter)
end

local function displayFilters(filterString)
    filterString = filterString or ""
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local topHeight = 4
    local height = context.height - topHeight - 1
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
        idPages = gui.multiButtonList(1, topHeight, buttons, middle - 1, height, "Filters", colors.white, true)
        context.gpu.setActiveBuffer(0)
    end
    local filteredFilters = filterByLabel(oreFilters, filterString)
    formCurrentView(filteredFilters)
    renderer.update(idPages)
end

windowRefresh = displayFilters
local function searchBox()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local searchFrame = renderer.createObject(1, 1, middle - 2, 3)
    local top = "╭"
    local mid = "│"
    local bottom = "╰"
    for i = 1, middle - 4 do
        top = top .. "─"
        mid = mid .. " "
        bottom = bottom .. "─"
    end
    top = top .. "╮"
    mid = mid .. "│"
    bottom = bottom .. "╯"
    context.gpu.setActiveBuffer(searchFrame)
    graphics.text(1, 1, top, gui.primaryColor())
    graphics.text(1, 3, mid, gui.primaryColor())
    graphics.text(1, 5, bottom, gui.primaryColor())
    graphics.text(3, 3, "Search:", colors.white)
    gui.multiAttributeList(2, 1, searchFrame, search, {{name = "Search: ", attribute = "keyword", type = "string", defaultValue = ""}}, searchKey, nil, 35)
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


--]]
local function returnToMenu()
    drawn = false
    renderer.switchWindow("main")
    renderer.clearWindow("OreProcessing")
    renderer.update()
end

--main window draw
local function displayWindow()
    drawn = true
    load()
    local context = graphics.context()
    local height = context.height
    local middle = math.floor(context.width / 2)
    renderer.switchWindow("OreProcessing")
    gui.smallButton(1, context.height, "< < < Return", returnToMenu, {}, nil, gui.primaryColor())
    --local divider = renderer.createObject(math.floor(context.width / 4) - 3, 2, 7, 1, true)
    --draw lower divider
    local divider = renderer.createObject(1, context.height - 1, context.width, 1)
    context.gpu.setActiveBuffer(divider)
    local bar = "▂▂▂"
    for i = 1, context.width - 6 do bar = bar .. "▄" end
    local bar = bar .. "▂▂▂"
    graphics.text(1, 1, bar, gui.borderColor())
    graphics.text(middle, 1, "▟", gui.borderColor())
    context.gpu.setActiveBuffer(0)
    --draw middle divider
    local dividervert = renderer.createObject(middle, 1, 1, height - 2)
    context.gpu.setActiveBuffer(dividervert)
    for i = 1, height - 2 do
        graphics.text(1, i * 2 - 1, "▐", gui.borderColor())
    end
    context.gpu.setActiveBuffer(0)
    displayFilters()
    searchBox()
    graphics.text(context.width / 4 - 3, 3, "Filters", colors.white)
    renderer.update()
end


local refresh
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
    refresh(x, y, gui, graphics, renderer, page) --alias for OreProcessing.configure()
end

--provides the button to access filter page
function OreProcessing.windowButton()
    return {name = "OreFilters", func = displayWindow}
end

--provides configuration page from main menu
function OreProcessing.configure(x, y, gui, graphics, renderer, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    graphics.context().gpu.setActiveBuffer(page)
    local function findTransposers(index)
        local onActivation = {}
        table.insert(onActivation, {displayName = "None", value = changeAddr, args = {"None", index, renderingData}})
        for address, componentType in component.list() do
            if componentType == "transposer" then
                local displayName = address
                table.insert(onActivation, {displayName = displayName, value = changeAddr, args = {address, index, renderingData}})
            end
        end
        return onActivation
    end
    for i=1, 2 do
        graphics.text(3, (i * 2) + 3, "Transposer "..tostring(i)..":")
    end
    for i=1, 2 do
        --graphics.text(x+2, (i * 2) + 3, "Transposer "..tostring(i)..":")
        table.insert(currentConfigWindow, gui.smallButton(x+15, y+1+i, oreAddr[i] or "None", gui.selectionBox, {x+16, y+i+1, findTransposers(i)}))
    end
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    renderer.update()
    return currentConfigWindow
end
refresh = OreProcessing.configure

local lastKeyword = searchKey.keyword
--main loop
function OreProcessing.update()
    --TODO this
    if drawn then
        graphics.context().gpu.setActiveBuffer(0)
    end
    if drawn and lastKeyword ~= searchKey.keyword then
        displayFilters(searchKey.keyword)
        lastKeyword = searchKey.keyword
    end
end

return OreProcessing