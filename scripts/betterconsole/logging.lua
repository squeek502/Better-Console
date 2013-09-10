local standard_print = print


module(..., package.seeall)


local CFG = require 'betterconsole.cfg_table'


local CircularQueueView = require 'betterconsole.circularqueueview'


loghistory = CircularQueueView( CFG.MAX_LINES_IN_CONSOLE_LOG_HISTORY or 1000 )


local function packstring(...)
	local Args = {...}
	for i, v in ipairs(Args) do
		Args[i] = tostring(v)
	end
	return table.concat(Args, (CFG.FIELD_SEPARATOR or "\t"))
end


function consolelogger(first, ...)
	if TheSim and TheSim.LuaPrint then
		TheSim:LuaPrint "custom console logger running"
	end

	local caller = debug.getinfo(2, 'f').func
	if caller == standard_print and type(first) == "string" then
		--[[
		-- This may need tweaks for future updates.
		--]]
		first = first:gsub("^.-%(%s*%d+,%s*%d+%s*%)%s*", "")
	end

	local str = packstring(first, ...)

	-- The game's version using string.split is actually a bit bugged.
	-- The reason is string.split splits on the occurrence of any character
	-- given, not on the whole string.
	for line in str:gmatch("[^\n]+") do
		line = line:gsub("\r$", "")
		loghistory:Insert( line )
	end
end

MAX_CONSOLE_LINES_SHOWN = 16

_G.AddPrintLogger(consolelogger)
function _G.GetConsoleOutputList()
	if TheSim and TheSim.LuaPrint then
		TheSim:LuaPrint "custom GetConsoleOutputList running"
	end

	return loghistory:Tail( MAX_CONSOLE_LINES_SHOWN )
end


return _M
