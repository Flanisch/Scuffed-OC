local OreProcessing = {}

local component = require("component")
local serialization = require("serialization")
local colors = require("lib.graphics.colors")
local gui = require("lib.graphics.gui")
local graphics = require("lib.graphics.graphics")
local renderer = require("lib.graphics.renderer")
local event = require("event")
local sides = require("sides")

local transposer = {}
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
local savingMode
local shouldListen = {listen = false, args = {}}
local orientation
local transposerSides = {}

local debugnumber = 0
local function debugnum(num, y, type)
    local screenY
    if y then screenY = y else screenY = 1 end
    require("term").setCursor(1,screenY)
    if num ~= nil then
        if type == "table" then
            for k, v in pairs(num) do print(k, v) end
        else
            print(num)
        end
    else
        print(debugnumber)
        debugnumber = debugnumber + 1
    end
end

local function save()
    local file = io.open("/home/NIDAS/settings/oreFilters", "w")
    file:write(serialization.serialize(oreFilters))
    file:close()
    local file = io.open("/home/NIDAS/settings/oreAddr", "w")
    file:write(serialization.serialize(oreAddr))
    file:close()
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
        transposer = {component.proxy(component.get(oreAddr[1])), component.proxy(component.get(oreAddr[2]))}
        orientation = oreAddr[3]
    end
end

local function filterByLabel(data, keyword)
    local filtered = {}
    for key, value in pairs(data) do
        if string.find(string.lower(value.name), string.lower(keyword)) ~= nil then
            filtered[key] = value
        end
    end
    return filtered
end

local function searchFilter(keyword)
    for ID, entry in pairs(oreFilters) do
        if entry.name == keyword then
            return ID
        end
    end
    return false
end

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

--- Generates a 10x3 button at reference coordinates for confirmation purposes
---@param x number @ reference coordinate
---@param y number @ reference coordinate
---@return boolean
local function confirm(x, y)
    local context = graphics.context()
    local buttonpage
    local function yes()
        removeFilter(input["name"])
        windowRefresh()
        return true
    end
    buttonpage = gui.bigButton(x, y, "Confirm?", yes)
    table.insert(pageBuffer, buttonpage)
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
    input = {}
    shouldListen.listen = false
    savingMode = nil
    context.gpu.fill(middle + 1, 1, context.width - middle, context.height - 2, " ")
end

local function saveButton(_, mode)
    local context = graphics.context()
    local savemode
    local name = input["name"]
    local filter = input["filter"]
    print(mode)
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
    event.ignore("filter_manipulation", saveButton)
end

local function cancelButton()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    table.insert(pageBuffer, gui.bigButton(context.width - 8, context.height - 5, "Cancel", cancel))
end

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
    local attributeData = {
         {name = "", attribute = "name", type = "string", defaultValue = "None"},
         {name = "", attribute = "filter", type = "number", defaultValue = "None"}
    }
    gui.multiAttributeList(middle + 16, 7, editor, nameInput, attributeData, input)
    local information = {
        {text = "The available filters are as follows:", color = colors.white},
        {text = "1: Primary Byproduct"},
        {text = "2: Ore Washer Purification (Secondary Byproduct)"},
        {text = "3: Chemical Bath Purification Using Mercury (Secondary BP)"},
        {text = "4: Tertiary Byproduct"},
        {text = "5: Smelting"},
        {text = "6: Gem Sifting"},
        {text = "7: Special Uses"}
    }
    gui.multiLineText(1, 12, information, colors.white)

    shouldListen.listen = true
    savingMode = "save"
    table.insert(pageBuffer, nameInput)
    event.listen("filter_manipulation", saveButton)
    context.gpu.setActiveBuffer(0)

    cancelButton()
    renderer.update()
end

local function modifyPage(id)
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local length = context.width - middle - 5
    local filter = oreFilters[id]
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
        {name = "", attribute = "filter", type = "number", defaultValue = filter.filter or "ERROR"}
    }
    input["name"] = filter.name
    local information = {
        {text = "The available filters are as follows:", color = colors.white},
        {text = "1: Primary Byproduct"},
        {text = "2: Ore Washer Purification (Secondary Byproduct)"},
        {text = "3: Chemical Bath Purification Using Mercury (Secondary BP)"},
        {text = "4: Tertiary Byproduct"},
        {text = "5: Smelting"},
        {text = "6: Gem Sifting"},
        {text = "7: Special Uses"}
    }
    information[filter.filter + 1].color = gui.primaryColor()
    gui.multiLineText(1, 7, information, gui.borderColor())
    gui.multiAttributeList(middle + 16, 8, editor, nameInput, attributeData, input)
    shouldListen.listen = true
    savingMode = "modify"
    event.listen("filter_manipulation", saveButton)
    context.gpu.setActiveBuffer(0)
    
    cancelButton()
    table.insert(pageBuffer, gui.bigButton(middle + 2, context.height - 5, "Remove Filter", confirm, {middle + 18,context.height - 5}))
    renderer.update()
end

local function page2()
    local context = graphics.context()
    local middle = math.floor(context.width / 2)
    local logo = {
        "◥█◤ █◣█ ███ ◢█◣",
        " █  ███ █▅  █ █",
        "◢█◣ █◥█ █   ◥█◤"
    }
    pagePrep()
    drawLogo(logo)
    local infoPanel = renderer.createObject(middle + 2, 5, context.width - middle - 2, context.height - 7)
    table.insert(pageBuffer, infoPanel)
    context.gpu.setActiveBuffer(infoPanel)
    local secondPage = {
        {text = "The available filters are as follows:", color = gui.primaryColor()},
        {text = "1: primary output (macerate-centrifuge-output)"},
        {text = "2: purify with orewasher (orewash-recycle)"},
        {text = "3: purify with chembath with mercury (chembath-recycle)"},
        {text = "4: tertiary output (thermal centrifuge-macerate-output)"},
        {text = "5: primary-smelt (smelt-macerate-package-output)"},
        {text = "6: sift (sift-output)"},
        {text = "7: special (output)"},
        {text = "8: excess/no filter (output)"},
        {}, 
        {text = "\"Recycle\" means the item is sent back to working storage.", color = gui.primaryColor()},
        {text = "\"Output\" means the item is sent to your ME system, etc.", color = gui.primaryColor()},
        {},
        {text = "It is recommended that you prioritize the recycled items"},
        {text = "over newly incoming ones."}
    }
    gui.multiLineText(1, 1, secondPage, colors.white)
    context.gpu.setActiveBuffer(0)
    table.insert(pageBuffer, gui.bigButton(context.width - 12, 1, "Add Filter", addPage))
    table.insert(pageBuffer, gui.bigButton(middle + 2, context.height - 5, "Return", windowRefresh))
    renderer.update()
end

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
    local infoPanel = renderer.createObject(middle + 2, 5, context.width - middle - 2, context.height - 7)
    table.insert(pageBuffer, infoPanel)
    context.gpu.setActiveBuffer(infoPanel)
    local aboutText = {
        {text = "This module requires a specific physical setup to operate.", color = gui.primaryColor()},
        {text = "This module runs off of a pair of transposers that pull"},
        {text = "from a central \"working inventory\" into 8 output chests."},
        {text = "Note: all chests used must have only 1 slot. I might", color = colors.red},
        {text = "change this later if I care and performance doesn't get", color = colors.red},
        {text = "hurt. Valid chests include baby chests, dirt chests, etc.", color = colors.red},
        {text = "Place the transposers and chests like so:"},
        {},
        {text = "    [1]     [6]"},
        {text = "[2][T/8][W][T/7][5]"},
        {text = "    [3]     [4]"},
        {},
        {text = "Where [T] = the transposers, [W] = working inventory,"},
        {text = "and [number] = output chest."},
        {text = "Outputs 7 and 8 go on top of the transposers.", color = gui.primaryColor()},
        {text = "Route the cables on the bottom. Connect each chest to its"},
        {text = "correlated processing line. Fast, stackwise item"},
        {text = "extraction is highly recommended."},
        {text = "Select your transposers and orientation in the config", color = gui.primaryColor()},
        {text = "window based on the diagram. 1 is left, 2 is right.", color = gui.primaryColor()},
        {},
        {text = "This info can be disabled by disabling \"Setup Assistance\".", color = gui.borderColor()}
    }
    if oreAddr.help then
        gui.multiLineText(1, 1, aboutText, colors.white)
        table.insert(pageBuffer, gui.bigButton(context.width - 8, context.height - 5, "Page 2", page2))
    end
    context.gpu.setActiveBuffer(0)
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
        for k, entry in pairs(filters) do
            table.insert(
                buttons,
                {name = filters[k].name, func = modifyPage, args = {k}}
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
8: excess (output)

--]]

local function returnToMenu()
    drawn = false
    shouldListen.listen = false
    shouldListen.args = {}
    input = {}
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
    displayFilters()            --refer to line 466
    searchBox()
    aboutPage()
    renderer.update()
end

--[[
physical section of the code
how I want to do this
     1    6
  2[t1]w[t2]5
    3    4
where w is the working storage

]]

local function setSides()
    if orientation == "North" then
        transposerSides[1] = sides.north
        transposerSides[2] = sides.west
        transposerSides[3] = sides.south
        transposerSides[4] = sides.south
        transposerSides[5] = sides.east
        transposerSides[6] = sides.north
        transposerSides[7] = sides.up
        transposerSides[8] = sides.up
        transposerSides["work"] = {sides.east, sides.west}
    elseif orientation == "South" then
        transposerSides[1] = sides.south
        transposerSides[2] = sides.east
        transposerSides[3] = sides.north
        transposerSides[4] = sides.north
        transposerSides[5] = sides.west
        transposerSides[6] = sides.south
        transposerSides[7] = sides.up
        transposerSides[8] = sides.up
        transposerSides["work"] = {sides.west, sides.east}
    elseif orientation == "East" then
        transposerSides[1] = sides.east
        transposerSides[2] = sides.north
        transposerSides[3] = sides.west
        transposerSides[4] = sides.west
        transposerSides[5] = sides.south
        transposerSides[6] = sides.east
        transposerSides[7] = sides.up
        transposerSides[8] = sides.up
        transposerSides["work"] = {sides.south, sides.north}
    elseif orientation == "West" then
        transposerSides[1] = sides.west
        transposerSides[2] = sides.south
        transposerSides[3] = sides.east
        transposerSides[4] = sides.east
        transposerSides[5] = sides.north
        transposerSides[6] = sides.west
        transposerSides[7] = sides.up
        transposerSides[8] = sides.up
        transposerSides["work"] = {sides.north, sides.south}
    end
end

local function checkInventory(inventory)
    local output
    local toUse
    if inventory == 0 then
        output = transposer[1].getStackInSlot(transposerSides["work"][1], 1)
    elseif inventory <= 3 or inventory == 8 then
        output = transposer[1].getStackInSlot(transposerSides[inventory], 1)
        toUse = 1
    else
        output = transposer[2].getStackInSlot(transposerSides[inventory], 1)
        toUse = 2
    end
    local label = false
    if output then
        label = output.label
    end
    return {label, toUse}
end

local function checkDatabase()
    local item, _ = table.unpack(checkInventory(0))
    if item and searchFilter(item) then
        return oreFilters[searchFilter(item)].filter
    elseif item then
        return 8
    end
    return false
end

local function moveItem(output)
    local label, _ = table.unpack(checkInventory(0))
    local used, toUse = table.unpack(checkInventory(output))
    if not used then
        transposer[toUse].transferItem(transposerSides["work"][toUse], transposerSides[output])
        return true
    end
    return false
end

windowRefresh = aboutPage
local refresh
local currentConfigWindow = {}

local function changeSetting(settingData, indexNumber, data)
    if indexNumber == 3 then
        oreAddr[indexNumber] = settingData
        orientation = settingData    
    elseif settingData == "None" then
        oreAddr[indexNumber] = "None"
        transposer[indexNumber] = nil
    else
        oreAddr[indexNumber] = settingData
        transposer[indexNumber] = component.proxy(component.get(settingData))
    end
    local x, y, gui, graphics, renderer, page = table.unpack(data)
    setSides()
    renderer.removeObject(currentConfigWindow)
    refresh(x, y, gui, graphics, renderer, page) --alias for OreProcessing.configure()
end

function OreProcessing.windowButton()
    return {name = "OreFilters", func = displayWindow}
end

function OreProcessing.configure(x, y, gui, graphics, renderer, page)
    local renderingData = {x, y, gui, graphics, renderer, page}
    graphics.context().gpu.setActiveBuffer(page)
    local function findTransposers(index)
        local onActivationTransposer = {}
        table.insert(onActivationTransposer, {displayName = "None", value = changeSetting, args = {"None", index, renderingData}})
        for address, componentType in component.list() do
            if componentType == "transposer" then
                table.insert(onActivationTransposer, {displayName = address, value = changeSetting, args = {address, index, renderingData}})
            end
        end
        return onActivationTransposer
    end
    for i=1, 2 do
        graphics.text(3, (i * 2) + 3, "Transposer "..tostring(i)..":")
    end
    graphics.text(3, 11, "Orientation:")
    for i=1, 2 do
        table.insert(currentConfigWindow, gui.smallButton(x+15, y+1+i, oreAddr[i] or "None", gui.selectionBox, {x+16, y+i+1, findTransposers(i)}))
    end
    local onActivationOrientation = {
        {displayName = "North", value = changeSetting, args = {"North", 3, renderingData}},
        {displayName = "South", value = changeSetting, args = {"South", 3, renderingData}},
        {displayName = "East", value = changeSetting, args = {"East", 3, renderingData}},
        {displayName = "West", value = changeSetting, args = {"West", 3, renderingData}},
    }
    table.insert(currentConfigWindow, gui.smallButton(x+15, y+5, orientation, gui.selectionBox, {x+15, y+5, onActivationOrientation}))
    gui.multiAttributeList(x + 3, y + 6, page, currentConfigWindow, {{name = "Setup Assistance:", attribute = "help", type = "boolean", defaultValue = true}}, oreAddr)
    local _, ySize = graphics.context().gpu.getBufferSize(page)
    table.insert(currentConfigWindow, gui.bigButton(x+2, y+tonumber(ySize)-4, "Save Configuration", save))
    renderer.update()
    return currentConfigWindow
end
refresh = OreProcessing.configure

local lastKeyword = searchKey.keyword

--- main loop
load()
setSides()
local item
function OreProcessing.update()
    item = checkDatabase()
    if item then
        moveItem(item)
    end
    if drawn then
        graphics.context().gpu.setActiveBuffer(0)
    end
    if drawn and lastKeyword ~= searchKey.keyword then      --since there's a bigger bug when displayWindow() calls displayFilters() WITH the proper arg rather than without,
        displayFilters(searchKey.keyword)                   --I'm not going to have it called with said arg to avoid said bug
        lastKeyword = searchKey.keyword                     --even though it makes this section of code useless, /shrug
    end
    if shouldListen.listen then
        if input["name"] and input["filter"] then 
            if string.match(tostring(input["filter"]), "[1234567]") then
                event.push("filter_manipulation", savingMode)
                shouldListen.listen = false

            end
        end
    end
end

return OreProcessing