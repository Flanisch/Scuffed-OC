local term = require("term")
local component = require("component")
local string = require("string")

local me = component.me_interface
local db = component.database





local function grabItem() --takes first itemstack in ME system and copies it to index 1 in database; returns false if more than 1 item in ME
    if me.getItemsInNetwork()[2] then return false
    me.store(me.getItemsInNetwork()[1],db.address)
    return true
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
term.write("Aura's ME Pattern Output Editor/n/nPlease ensure that the pattern you want to edit is in the interface to the left in the first slot./nAlso ensure that the only item in the ME system to the left is the template item./nAnd, of course, you'll need a template item. If you haven't gotten one yet, get one now./n/n")
term.write("Please enter the desired amount you would like written to the pattern: ")
amount = string.gsub(term.read(),"/n","")
print(amount)