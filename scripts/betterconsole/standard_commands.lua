--[[
-- Returns the standard console commands in a table mapping their
-- names to the respective functions.
--]]

module(..., package.seeall)

local commands = {}


local function SlurpCommandsFile(name, overwrite)
	local dumpbin = {}
	package.seeall(dumpbin)

	local env = setmetatable(
		{},
		{
			__index = dumpbin,
			__newindex = dumpbin,
		}
	)

	local fn = loadfile(name)
	if type(fn) ~= "function" then return error(fn or (tostring(name) .. " doesn't exist!")) end

	setfenv(fn, env)

	fn()

	for k, v in pairs(dumpbin) do
		if type(k) == "string" and not k:match("^_") and type(v) == "function" then
			if commands[k] == nil or overwrite then
				commands[k] = v
			end
		end
	end
end


SlurpCommandsFile("scripts/consolecommands.lua")


return commands
