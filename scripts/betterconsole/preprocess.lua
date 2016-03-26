local CFG = require "betterconsole.cfg_table"
local Language = require "betterconsole.lua.language"
local Commands = require "betterconsole.environment.commands"

----------------------

local function implicit_return(str)
	return string.gsub(str, "^=%s*", "return ")
end

local function command_autoexec(str)
	local id = str:match("^%s*" .. Language.identifier .. "%s*$")
	-- use rawget here to avoid strict.lua when looking up a variable name that doesn't exist
	if id and type( rawget( Commands, id ) ) == "function" then
		return "return " .. str .. "()"
	else
		return str
	end
end

local function variable_autoprint(str)
	local id = str:match("^%s*" .. Language.identifier .. "%s*$")
	if id then
		str = "return "..id
	end
	return str
end

----------------------

-- Preprocesses the code to allow for string substitutions.
-- Only operates over the first line of the input, when it is multiline
-- enabled.
local function preprocess(str)
	str = implicit_return(str)

	if CFG.ENABLE_CONSOLE_COMMAND_AUTOEXEC then
		str = command_autoexec(str)
	end

	if CFG.ENABLE_VARIABLE_AUTOPRINT then
		str = variable_autoprint(str)
	end

	return str
end

return preprocess
