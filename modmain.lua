
-- improve the console

-------------------------------------------
-- settings
-------------------------------------------
local ENABLE_SMALLER_FONTS = true
local MAX_LINES_IN_CONSOLE_LOG_HISTORY = 1000


-------------------------------------------
-- code
-------------------------------------------
local require = GLOBAL.require

require "betterdebugprint"
GLOBAL.MAX_CONSOLE_LINES = MAX_LINES_IN_CONSOLE_LOG_HISTORY

AddGlobalClassPostConstruct("screens/consolescreen", "ConsoleScreen", function(self)

	if ENABLE_SMALLER_FONTS then
		self.console_edit:SetSize(20)
	end
	require "betterconsolecommands"

end)

AddGamePostInit( function()
	
	if GLOBAL.TheFrontEnd and GLOBAL.TheFrontEnd.consoletext then
		if ENABLE_SMALLER_FONTS then
			GLOBAL.TheFrontEnd.consoletext:SetSize(16)
			GLOBAL.MAX_CONSOLE_LINES_SHOWN = 20
		end
		GLOBAL.TheFrontEnd.consoletext:EnableWordWrap(true)
	end
	
end )