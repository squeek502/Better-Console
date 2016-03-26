local rawset = GLOBAL.rawset
local setmetatable = GLOBAL.setmetatable
local tostring = GLOBAL.tostring
local tonumber = GLOBAL.tonumber
local setfenv = GLOBAL.setfenv
local error = GLOBAL.error


local CFG_TABLE = GLOBAL.require "betterconsole.cfg_table"


-- modified (stripped down) version of the LoadConfigs function written by simplex for the Blackhouse mod
-- see: https://github.com/nsimplex/Blackhouse/blob/master/src/customizability.lua
function LoadConfig(file)
	local cfg = GLOBAL.kleiloadlua(MODROOT .. file)
	if type(cfg) ~= "function" then return print(cfg or "(Better Console) Unable to load " .. file .. ' (does it exist?)') end
	
	-- A sandbox inside a sandbox!
	setfenv(cfg, setmetatable(
	{
		TUNING = TUNING,
		math = math,
		table = table,
		string = string,
		tostring = tostring,
		tonumber = tonumber,
	},
	{
		__index = CFG_TABLE,
		__newindex = CFG_TABLE,
	}))

	cfg()
end
