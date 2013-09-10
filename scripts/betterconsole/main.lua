module(..., package.seeall)

-- improve the console

local CFG = require 'betterconsole.cfg_table'


-------------------------------------------
-- code
-------------------------------------------

--require "betterconsole/betterdebugprint"

local Logging = require 'betterconsole.logging'

require "betterconsole/widgets/bettertextedit"
require "betterconsole/screens/betterconsolescreen"

local BetterConsoleUtil = require "betterconsole/betterconsoleutil"


return function(modenv)
	for k, v in pairs(modenv) do
		if type(k) == "string" and not k:match("^_") then
			_M[k] = v
		end
	end

	-------------------------------------------
	-- postinits
	-------------------------------------------
	AddGamePostInit( function()
		
		if rawget(_G, "TheFrontEnd") and CFG.ENABLE_FONT_SCALING then
			local max_text_size, min_text_size = 22, 14
			local max_console_lines_shown, min_console_lines_shown = 24, 16
			local screenw = TheSim:GetScreenSize()
			local text_size = BetterConsoleUtil.GetScaledTextSize( max_text_size, min_text_size )
			local function GetMaxConsoleLinesShown( new_text_size )
				local lines_shown = max_console_lines_shown - ((new_text_size-min_text_size) / (max_text_size-min_text_size) * (max_console_lines_shown-min_console_lines_shown))
				lines_shown = tonumber(string.format("%.0f", lines_shown))
				--print( "console lines",lines_shown )
				return lines_shown
			end

			-- This needs to be adjusted, so we don't have a dual definition.
			Logging.loghistory:SetViewSize( GetMaxConsoleLinesShown(text_size) )
			TheFrontEnd.consoletext:SetSize( text_size )
			TheFrontEnd.consoletext:EnableWordWrap(true)

			local TheFrontEnd_UpdateConsoleOutput_base = TheFrontEnd.UpdateConsoleOutput or function() end
			function TheFrontEnd:UpdateConsoleOutput()
				TheFrontEnd_UpdateConsoleOutput_base(self)

				local curscreenw = TheSim:GetScreenSize()
				if curscreenw ~= screenw then
					local text_size = BetterConsoleUtil.GetScaledTextSize( max_text_size, min_text_size )
					Logging.loghistory:SetViewSize( GetMaxConsoleLinesShown(text_size) )
					self.consoletext:SetSize( text_size )
					screenw = curscreenw
				end
			end

		end
		
	end )
end
