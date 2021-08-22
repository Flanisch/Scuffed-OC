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
local function type(input, startx, starty, cd)
	if cd == nil then local cd == 0 end
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
			os.sleep(0.5)
		end
	end
end
term.clear()
type("space", 39, 5)
