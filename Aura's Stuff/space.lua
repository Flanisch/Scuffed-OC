local os = require("os")
local term = require("term")

function Split(s, delimiter)
    local result = {};
    local count = 1
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        --table.insert(result, match);
        result[count] = match
        count = count + 1
    end
    return result, count
end
--primary writing tool
local function type(input, startx, starty, wait, cd)
	local str, length = Split(input," ")
	length = length - 1
	local spacer = 0
	for i=1, length do
		term.setCursor(startx + spacer, starty)
		term.write(str[i])
		spacer = spacer + string.len(str[i]) + 1
		if i ~= length then
			os.sleep(cd)
		else
			os.sleep(wait)
		end
	end
end
term.clear()
type("space", 39, 5, .25)
type("space", 12, 7, .4)
type("wanna go to space", 30, 16, .7, .08)
type("going to space", 21, 10, .2, .08)
type("oh boy", 25, 11, .7, .08)
type("space", 2, 3, .25)
type("space", 44, 13, .5)
type("wanna go to space", 10, 1, .5, .08)
type("yes", 43, 15, .8)
type("please space", 19, 8, .7, .1)
type("space space", 23, 15, .7, .09)
type("go to space", 4, 12, 1, .08)
term.clear()
type("wanna go to", 14, 3, .4, .08)
type("wanna go to space", 14, 4, 1, .08)
type("space", 6, 3, .3)
type("wanna go", 33, 4, .4, .08)
type("wanna go to space", 13, 2, .6, .08)
type("wanna go to space", 17, 5, 1, .084)
term.clear()
type("hey", 1, 1, .4)
type("hey", 1, 2, .4)
type("hey", 1, 3, .4)
type("hey", 1, 4, .4)
type("hey", 1, 5, .4)
type("hey lady", 1, 6, .4, .2)
type("lady", 1, 7, .4)
type("space!", 1, 8, .4)
type("lady", 1, 9, .4)
type("space", 1, 10, .4)
type("gotta go to space", 1, 11, .5, .1)
type("lady", 19, 11, .4)
type("lady", 24, 11, .6)
type("oo oo oo", 1, 12, .1, .08)
type("lady", 10, 12, .12)
type("oo", 15, 12, .1)
type("let's go to space", 18, 12, .6, .09)
type("please go to space", 1, 13, .54, .08)
type("space", 1, 14, .45)
type("wanna go to space", 1, 15, .25, .08)
type("S", 47, 1, .25)
type("so much space", 1, 16, .15, .088)
type("P",47 ,2 , .4)
type("A",47 ,3 , .05)
type("need to see it all", 15, 16, .35, .08)
type("A",46 ,4 , .4)
type("A",46 ,5 , .4)
type("A",46 ,6 , .4)
type("A",46 ,7 , .4)
type("A",46 ,8 , .4)
type("A",45 ,9 , .4)
type("A",45 ,10 , .4)
type("A",45 ,11 , .4)
type("C",45 ,12 , .4)
type("E",45 ,13 , .4)
type("!",44 ,14 , .4)
type("!",44 ,15 , .4)
type("!",44 ,16 , .2)
term.clear()