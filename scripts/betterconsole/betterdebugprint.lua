--[[
--
--
--
--  This file is no longer being used!
--
--
--
--]]




print_loggers = {}

function AddPrintLogger( fn, verbose )
	if verbose == nil then verbose = true end
    table.insert(print_loggers, { fn=fn, verbose=verbose } )
end

global("CWD")

local dir = CWD or ""
dir = string.gsub(dir, "\\", "/") .. "/"
local oldprint = print

local function packstring(...)
    local str = ""
    for i,v in ipairs({...}) do
        str = str..tostring(v).."\t"
    end
    return str
end

local escape_lua_pattern
do
    local matches =
    {
        ["^"] = "%^";
        ["$"] = "%$";
        ["("] = "%(";
        [")"] = "%)";
        ["%"] = "%%";
        ["."] = "%.";
        ["["] = "%[";
        ["]"] = "%]";
        ["*"] = "%*";
        ["+"] = "%+";
        ["-"] = "%-";
        ["?"] = "%?";
        ["\0"] = "%z";
    }

    escape_lua_pattern = function(s)
        return (s:gsub(".", matches))
    end
end

--this wraps print in code that shows what line number it is coming from, and pushes it out to all of the print loggers
print = function(...)

	local info = debug.getinfo(2, "Sl")
	local source = info.source
	local verbosestr = ""
	if info.source and string.sub(info.source,1,1)=="@" then
		source = source:sub(2)
		source = source:gsub(escape_lua_pattern(dir), "")
		verbosestr = string.format("%s(%d,1) %s", tostring(source), info.currentline, packstring(...))
	else
		verbosestr = packstring(...)
	end

	for i,v in ipairs(print_loggers) do
        local str = v.verbose and verbosestr or packstring(...)
		v.fn(str)
	end

end

--This is for times when you want to print without showing your line number (such as in the interactive console)
nolineprint = function(...)

    local str = packstring(...)
    for i,v in ipairs(print_loggers) do
        v.fn(str)
    end
    
end


---- This keeps a record of the last n print lines, so that we can feed it into the debug console when it is visible
MAX_CONSOLE_LINES = BetterConsole.Config.MAX_LINES_IN_CONSOLE_LOG_HISTORY or 1000
MAX_CONSOLE_LINES_SHOWN = 16
local base_GetConsoleOutputList = GetConsoleOutputList

local consolelog = function(...)
    
    local str = packstring(...)
	local debugstr = base_GetConsoleOutputList()
    str = string.gsub(str, dir, "")

    for idx,line in ipairs(string.split(str, "\r\n")) do
        table.insert(debugstr, line)
    end

    while #debugstr > MAX_CONSOLE_LINES do
        table.remove(debugstr,1)
    end
end

function ClearConsoleLog()
    local new_console_log = {}
    base_GetConsoleOutputList = function() return new_console_log end
    SetConsoleLogIndex(nil)
end

local consolelog_idx = nil
function GetConsoleLogIndex()
    return consolelog_idx or #base_GetConsoleOutputList()
end
function SetConsoleLogIndex(idx)
    if idx ~= nil then
        if idx < MAX_CONSOLE_LINES_SHOWN then idx = MAX_CONSOLE_LINES_SHOWN end
        if idx >= #base_GetConsoleOutputList() then idx = nil end
    end
    consolelog_idx = idx
end

GetConsoleOutputList = function()
    local debugstr = base_GetConsoleOutputList()
    local output_debugstr = {}
    if #debugstr > MAX_CONSOLE_LINES_SHOWN then
        local endidx = GetConsoleLogIndex()
        local startidx = math.max( 1, endidx - MAX_CONSOLE_LINES_SHOWN + 1 )
        for idx=startidx,endidx do
            table.insert(output_debugstr, debugstr[idx])
        end
    else
        output_debugstr = debugstr
    end
    return output_debugstr
end

-- add our print loggers
AddPrintLogger(consolelog, false)
AddPrintLogger(function(...) TheSim:LuaPrint(...) end)

