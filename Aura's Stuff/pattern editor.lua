local term = require("term")
local component = require("component")
local string = require("string")

local me = component.me_interface
local db = component.database





local function grabItem() --takes first itemstack in ME system and copies it to index 1 in database; returns false if more than 1 item in ME
    if me.getItemsInNetwork()[2] then 
        return false
    else
        me.store(me.getItemsInNetwork()[1],db.address)
        return me.getItemsInNetwork()[1]["label"]
    end
end

local function processAmount(amount)
    local numberOfSlots = math.floor(amount / 64)
    local mod = amount % 64
    return numberOfSlots, mod
end

--[[
    ask user to place template item in ME system and affected pattern in slot 1 of interface
    ask user to ensure that the only item in the ME system is the template item
    ask user desired quantity
    quantity / 64 (math.floor) = number of slots to fill with full itemstacks
    quantity % 64 != 0:
        fill slot after that with said modulus
    report output
]]--

term.clear()
term.write("Aura's ME Pattern Output Editor\n\nPlease ensure that the pattern you want to edit is in the interface to the left in the first slot.\nAlso ensure that the only item in the ME system to the left is the template item.\nAnd, of course, you'll need a template item. If you haven't gotten one yet, get one now.\n\n")
term.write("Please enter the desired amount you would like written to the pattern (max 384): ")
local amount = term.read()
amount = string.gsub(amount,"\n","")
term.write("Writing "..amount.." items of "..grabItem().." to pattern...\n")
local numberOfSlots, isMod, mod = processAmount(amount)
for i=1, 6, 1 do
    if i <= numberOfSlots then
        me.setInterfacePatternOutput(1, db.address, 1, 64, i)
    else if mod ~= 0 then
        me.setInterface(1, db.address, 1, mod, i)
    else
        --something here that removes the slot
end
if isMod then
    me.setInterfacePatternOutput(1, db.address, 1, mod, modSlot)
end
term.write("Write complete! Please remove pattern and template item.")
db.clear(1)
