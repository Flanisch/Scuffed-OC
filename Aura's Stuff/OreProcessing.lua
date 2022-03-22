local OreProcessing = {}

--library pulls
local component = require("component")
local serialization = require("serialization")
local colors = require("lib.graphics.colors")
local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")
local renderer = require("lib.graphics.renderer")
local event = require("event")

--variable initializations
local dummy = {}
local transposer = {}
local editorPage
drawn = false
local idPages
local oreAddr = {}
local oreFilters = {}
local search = {}
local windowRefresh
local refreshFilters
local searchKey = {keyword = ""}
local logoPage
local pageBuffer = {}
local input = {}
local shouldListen = {listen = false, args = {}}
local filterOutputs = {
    primary = TBD,
    orewash = TBD,
    chembath = TBD,
    tertiary = TBD,
    smelt = TBD,
    sift = TBD,
    special = TBD
}
local outputChoices = {
    {displayName = "Primary Output", value = filterOutputs.primary},
    {displayName = "Purify (Ore Wash)", value = filterOutputs.orewash},
    {displayName = "Purify (Mercury Bath)", value = filterOutputs.chembath},
    {displayName = "Tertiary Output", value = filterOutputs.tertiary},
    {displayName = "Smelt", value = filterOutputs.smelt},
    {displayName = "Sift", value = filterOutputs.sift},
    {displayName = "Special", value = filterOutputs.special}
}

local debugnumber = 0
local function debugnum(num)
    if num ~= nil then
        print(num)
    else
        print(debugnumber)
        debugnumber = debugnumber + 1
    end
    require("term").setCursor(1,1)
end
--- saves table of filters and transposer addresses to file
local function save()
    local file = io.open("/home/NIDAS/settings/oreFilters", "w")
    file:write(serialization.serialize(oreFilters))
    file:close()
    local file = io.open("/home/NIDAS/settings/oreAddr", "w")
    file:write(serialization.serialize(oreAddr))
    file:close()
    windowRefresh(searchKey.keyword)
end
--- loads table of filters and transposer addresses to memory
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

--- searches table for matching entries
---@param data table @ oreFilters
---@param keyword string @ search keyword
---@return table
local function filterByLabel(data, keyword)
    local filtered = {}
    for key, value in pairs(data) do
        if string.find(string.lower(key), string.lower(keyword)) ~= nil then
            filtered[key] = value
        end
    end
    return filtered
end

--- searches oreFilters for a name match
---@param name string @ filter name
---@return boolean
local function searchFilter(name)
    for ID, entry in pairs(oreFilters) do
        if entry == name then
            return ID
        end
    end
    return false
end

--- adds a filter to oreFilters
---@return boolean
local function addFilter(name, filter)
    if not searchFilter(name) then
        table.insert(oreFilters, {name = name, filter = filter})
        save()
        refreshFilters(searchKey.keyword)
        return true
    else
        return false
    end
end

--- modifies a filter to change where that ore goes
---@return boolean
local function modifyFilter(filter, desired)
    local target = searchFilter(filter)
    if target then
        oreFilters[target].filter = desired
        save()
        refreshFilters(searchKey.keyword)
        return true
    else
        return false
    end
end

--- removes a filter from oreFilters
---@param name string @ filter name
---@return boolean
local function removeFilter(name)
    local target = searchFilter(name)
    if target then
        table.remove(oreFilters, target)
        save()
        refreshFilters(searchKey.keyword)
        return true
    else
        return false
    end
end

--- "Are you sure about that?" Generates a 10x3 button at reference coordinates for confirmation purposes
---@param x number @ reference coordinate
---@param y number @ reference coordinate
---@return boolean
local function confirm(x, y)
    local context = graphics.context()
    local buttonpage
    local function yes()
        renderer.removeObject(buttonpage)
        context.gpu.fill(x, y, 10, 3, " ")
        renderer.update()
        return true
    end
    buttonpage = gui.bigButton(x, y, "Confirm?", yes)
    renderer.update()
end

--- prepares the right side pane for a new page
local function pagePrep()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    if #pageBuffer > 0 then
        renderer.removeObject(pageBuffer)
        pageBuffer = {}
    end
    context.gpu.fill(middle + 1, 1, context.width - middle, context.height - 2, " ")
end

--- generates a save button at the top right of the screen
---@param mode string @ either "save" or "modify"
---@param data table @ 
local function saveButton(mode, data)
    local context = graphics.context()
    local savemode
    local name = data.name
    local filter = data.filter
    if mode == "save" then
        savemode = addFilter
    elseif mode == "modify" then
        savemode = modifyFilter
    end
    table.insert(pageBuffer, gui.bigButton(context.width - 13, 1, "Save Filter", savemode, {name, filter}))
    renderer.update()
end

local function cancel()
    pagePrep()
    windowRefresh()
    input = {}
    shouldListen.listen = false
    shouldListen.args = {}
    event.ignore("filter_manipulation", saveButton)
end
--- generates a cancel button
local function cancelButton()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    table.insert(pageBuffer, gui.bigButton(context.width - 8, context.height - 5, "Cancel", cancel))
end

--- draws a page's logo
---@param logo table @ logo information
---@return number @ NIDAS page number
local function drawLogo(logo)
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    renderer.removeObject(logoPage)
    logoPage = renderer.createObject(middle + 2, 1, #logo[1], 3)
    context.gpu.setActiveBuffer(logoPage)
    graphics.outline(1, 1, logo, gui.primaryColor())
    context.gpu.setActiveBuffer(0)
    return logoPage
end

--- draws page to add a filter
local function addPage()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local length = context.width - middle - 5
    local logo = {
        "◢█◣ ██◣ ██◣   ███ ◥█◤ █   ◥█◤ ███ ██◣",
        "█▃█ █ █ █ █   █▅   █  █    █  █▄  █ ◤",
        "◤ ◥ ██◤ ██◤   █   ◢█◣ ███  █  █▆▆ █◥◣"
    }
    pagePrep()
    drawLogo(logo)
    local editor = renderer.createObject(middle + 2, 5, length, context.height - 7)
    local nameInput = {}
    table.insert(pageBuffer, editor)
    context.gpu.setActiveBuffer(editor)
    graphics.text(math.floor(length / 2) - 6, 1, "Filter Entry", gui.primaryColor())
    graphics.text(1, 7, "Filter Name:", colors.white)
    graphics.text(1, 9, "Filter Output:", colors.white)
    --TODO rest of data here
    context.gpu.setActiveBuffer(0)
    local attributeData = {
         {name = "", attribute = name, type = "string", defaultValue = "None"},
         {name = "", attribute = filter, type = "number", defaultValue = "None"}
    }
    gui.multiAttributeList(middle + 16, 7, editor, nameInput, attributeData, input)
    shouldListen.listen = true
    table.insert(pageBuffer, nameInput)
    shouldListen.eventID = event.listen("filter_manipulation", saveButton)

    cancelButton()
    renderer.update()
end

--- draws page to modify a filter
---@param filter string @ name of filter
local function modifyPage(filter)
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local length = context.width - middle - 5
    local filter = oreFilters[filter]
    input[filter] = filter.filter
    local logo = {
        "███ ██◣ ◥█◤ ◥█◤   ███ ◥█◤ █   ◥█◤ ███ ██◣",
        "█▄  █ █  █   █    █▅   █  █    █  █▄  █ ◤",
        "█▆▆ ██◤ ◢█◣  █    █   ◢█◣ ███  █  █▆▆ █◥◣"
    }
    pagePrep()
    drawLogo(logo)
    local editor = renderer.createObject(middle + 2, 5, length, context.height - 7)
    local nameInput = {}
    table.insert(pageBuffer, editor)
    context.gpu.setActiveBuffer(editor)
    graphics.text(math.floor(length / 2) - 6, 1, "Filter Entry", gui.primaryColor())
    graphics.text(1, 7, "Filter Name:   "..(filter.name or "ERROR"), colors.white)
    graphics.text(1, 9, "Filter Output:", colors.white)
    local attributeData = {
        {name = "", attribute = filter, type = "number", defaultValue = filter.filter or "ERROR"}
    }
    gui.multiAttributeList(middle + 16, 8, editor, nameInput, attributeData, input)
    context.gpu.setActiveBuffer(0)

    cancelButton()
    renderer.update()
end

--- draws page showing information
local function aboutPage()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local logo = {
        "◥█◤ █◣█ ███ ◢█◣",
        " █  ███ █▅  █ █",
        "◢█◣ █◥█ █   ◥█◤"
    }
    pagePrep()
    drawLogo(logo)
    --draw other information here
    table.insert(pageBuffer, gui.bigButton(context.width - 12, 1, "Add Filter", addPage))
    renderer.update()
end

--- draws the list of filters, filtered by param filterString
---@param filterString string @ search keyword
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
            local label = filters[k]
            table.insert(
                buttons,
                {name = label.name, func = modifyPage, args = {k}}
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
refreshFilters = displayFilters

--- draws a search box
local function searchBox()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local searchFrame = renderer.createObject(1, 1, middle - 1, 3)
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
oreFilters is a table with the following format:
oreFilters {
    {name="[name of ore]",filter=[number]}
}
the filters are:
1: primary output (macerate-centrifuge-output)
2: purify with orewasher (orewash-recycle)
3: purify with chembath with mercury (chembath-recycle)
4: tertiary output (thermal centrifuge-macerate-output)
5: primary-smelt (smelt-macerate-package-output)
6: sift (sift-output)
7: special (output)

it is technically an array with the value as a table
--]]

---returns to NIDAS main menu
local function returnToMenu()
    drawn = false
    renderer.switchWindow("main")
    renderer.clearWindow("OreProcessing")
    renderer.update()
    debugnumber = 0 --debug line
end

---main window draw
local function displayWindow()
    drawn = true
    load()
    local context = graphics.context()
    local height = context.height
    local middle = math.floor(context.width / 2)
    renderer.switchWindow("OreProcessing")
    gui.smallButton(1, context.height, "< < < Return", returnToMenu, {}, nil, gui.primaryColor())
    --draw lower divider
    local divider = renderer.createObject(1, context.height - 1, context.width, 1)
    context.gpu.setActiveBuffer(divider)
    local bar = "▂▂▂"
    for i = 1, context.width - 6 do bar = bar .. "▄" end
    local bar = bar .. "▂▂▂"
    graphics.text(1, 1, bar, gui.borderColor())
    graphics.text(middle, 1, "▟", gui.borderColor())
    --draw middle divider
    local dividervert = renderer.createObject(middle, 1, 1, height - 2)
    context.gpu.setActiveBuffer(dividervert)
    for i = 1, height - 2 do
        graphics.text(1, i * 2 - 1, "▐", gui.borderColor())
    end
    context.gpu.setActiveBuffer(0)
    --function calls to draw extra stuff
    displayFilters()
    searchBox()
    aboutPage()
    renderer.update()
end

windowRefresh = aboutPage
local refresh
local currentConfigWindow = {}
---changes config window values
---@param transposerAddress string @ address of transposer
---@param indexNumber number @ index number in oreAddr
---@param data table @ rendering data for refreshing config window
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

---provides the button to access filter page
---@return table @ NIDAS data
function OreProcessing.windowButton()
    return {name = "OreFilters", func = displayWindow}
end

---provides configuration page from main menu
---@param all any @ rendering data
---@return table @ NIDAS config window data
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
--- main loop
function OreProcessing.update()
    --TODO this
    if drawn then
        graphics.context().gpu.setActiveBuffer(0)
    end
    if drawn and lastKeyword ~= searchKey.keyword then
        displayFilters(searchKey.keyword)
        lastKeyword = searchKey.keyword
    end
    if shouldListen.listen then
        debugnum()
        if input.name and input.filter then 
            if string.match(tostring(input.filter), "[1234567]") then
                shouldListen.args = input
                event.push("filter_manipulation", shouldListen.args)
                shouldListen.listen = false
                shouldListen.args = {}
            end
        end
    end
end

return OreProcessing