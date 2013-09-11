--[[
-- Returns the standard console commands in a table mapping their
-- names to the respective functions.
--]]

module(..., package.seeall)

local commands = {}


local function SlurpCommandsFile(name, overwrite)
	local fullname = "scripts/" .. name .. ".lua"

	local dumpbin = {}
	package.seeall(dumpbin)

	local env = setmetatable(
		{},
		{
			__index = dumpbin,
			__newindex = dumpbin,
		}
	)

	local fn = loadfile(fullname)
	if type(fn) ~= "function" then return error(fn or (tostring(fullname) .. " doesn't exist!")) end

	setfenv(fn, env)

	fn()

	RunScript(name)

	for k in pairs(dumpbin) do
		local v = rawget(_G, k)
		if type(k) == "string" and not k:match("^_") and type(v) == "function" then
			if commands[k] == nil or overwrite then
				commands[k] = v
			end
		end
	end
end


SlurpCommandsFile("consolecommands")


return commands
