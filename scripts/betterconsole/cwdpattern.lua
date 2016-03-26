global("CWD")

local dir = CWD or ""
dir = string.gsub(dir, "\\", "/") .. "/"
local oldprint = print

matches =
{
	["^"] = "%^",
	["$"] = "%$",
	["("] = "%(",
	[")"] = "%)",
	["%"] = "%%",
	["."] = "%.",
	["["] = "%[",
	["]"] = "%]",
	["*"] = "%*",
	["+"] = "%+",
	["-"] = "%-",
	["?"] = "%?",
	["\0"] = "%z",
}
function escape_lua_pattern(s)
	return (s:gsub(".", matches))
end

return escape_lua_pattern(dir)
