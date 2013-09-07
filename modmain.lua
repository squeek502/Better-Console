
-- improve the console

-------------------------------------------
-- load config
-------------------------------------------

modimport("config.lua")

-------------------------------------------
-- code
-------------------------------------------
local require = GLOBAL.require

GLOBAL.BetterConsole = { 
	Config = {
		ENABLE_FONT_SCALING = ENABLE_FONT_SCALING,
		MAX_LINES_IN_CONSOLE_LOG_HISTORY = MAX_LINES_IN_CONSOLE_LOG_HISTORY,
	} 
}
BetterConsole = GLOBAL.BetterConsole

require "betterconsole/betterconsolecommands"
require "betterconsole/betterdebugprint"
require "betterconsole/widgets/bettertextedit"
require "betterconsole/screens/betterconsolescreen"

local BetterConsoleUtil = require "betterconsole/betterconsoleutil"

-------------------------------------------
-- postinits
-------------------------------------------
AddGamePostInit( function()
	
	if GLOBAL.TheFrontEnd and BetterConsole.Config.ENABLE_FONT_SCALING then

		local TheFrontEnd = GLOBAL.TheFrontEnd

		local max_text_size, min_text_size = 22, 14
		local max_console_lines_shown, min_console_lines_shown = 24, 16
		local screenw = TheSim:GetScreenSize()
		local text_size = BetterConsoleUtil.GetScaledTextSize( max_text_size, min_text_size )
		local function GetMaxConsoleLinesShown( new_text_size )
			local lines_shown = max_console_lines_shown - ((new_text_size-min_text_size) / (max_text_size-min_text_size) * (max_console_lines_shown-min_console_lines_shown))
			lines_shown = GLOBAL.tonumber(string.format("%.0f", lines_shown))
			--print( "console lines",lines_shown )
			return lines_shown
		end

		GLOBAL.MAX_CONSOLE_LINES_SHOWN = GetMaxConsoleLinesShown(text_size)
		TheFrontEnd.consoletext:SetSize( text_size )
		TheFrontEnd.consoletext:EnableWordWrap(true)

		local TheFrontEnd_UpdateConsoleOutput_base = TheFrontEnd.UpdateConsoleOutput or function() end
		function TheFrontEnd:UpdateConsoleOutput()
			TheFrontEnd_UpdateConsoleOutput_base(self)

			local curscreenw = TheSim:GetScreenSize()
			if curscreenw ~= screenw then
				local text_size = BetterConsoleUtil.GetScaledTextSize( max_text_size, min_text_size )
				GLOBAL.MAX_CONSOLE_LINES_SHOWN = GetMaxConsoleLinesShown(text_size)
				self.consoletext:SetSize( text_size )
				screenw = curscreenw
			end
		end

	end
	
end )