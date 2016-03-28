local _G = _G

module(..., package.seeall)

-------------------------------------------
-- code
-------------------------------------------

local CFG = require "betterconsole.cfg_table"

local Logging = require "betterconsole.lib.logging"

require "betterconsole.screens.betterconsolescreen"

local BetterConsoleUtil = require "betterconsole.lib.betterconsoleutil"

local Pred = require "betterconsole.lib.pred"

---

local preprocess = require "betterconsole.preprocess"

local Compiler = require "betterconsole.compiler"

local Processor = require "betterconsole.processor"

--- 

local function bindCompilerToMainFunctions(gcc_spec)
	local function NewFakeLoadstring(gcc)
		return function(str)
			return function() gcc(str) end
		end
	end

	local NewSmartRunner = (function()
		local run
		if Pred.IsDST() then
			run = assert( _G.ExecuteConsoleCommand )
			return function(gcc)
				local fake_loadstring = NewFakeLoadstring(gcc)
				return function(...)
					_G.loadstring = fake_loadstring

					run(...)

					_G.loadstring = loadstring
				end
			end
		else
			return function(gcc)
				return function(...)
					gcc(...)
				end
			end
		end
	end)()

	local is_dedi = Pred.IsDST() and _G.TheNet:IsDedicated()

	local gccs = {
		stdin = gcc_spec:Copy(is_dedi and "stdin++" or "console"),
	}

	if not Pred.IsDST() then
		global "ExecuteConsoleCommand"
	end

	function _G.ExecuteConsoleCommand(fnstr, guid, ...)
		local loadstring = _G.loadstring

		local gcc
		if guid == nil then
			gcc = gccs.stdin
		else
			gcc = gccs[guid]
			if gcc == nil then
				local player = _G.Ents[guid]
				local name = "["..tostring(player.prefab).." - "..tostring(player.userid).."]"
				gcc = gcc_spec:Copy(name)
				gccs[guid] = gcc
			end
		end

		NewSmartRunner(gcc)(fnstr, guid, ...)
		if is_dedi and gcc == gccs.stdin  then

		end
	end
end

---

local cpu = Processor()

local gcc_spec = Compiler("betterconsole")
gcc_spec:SetMultiline(false)
gcc_spec:SetPreprocessor(preprocess)
gcc_spec:SetProcessor(cpu)

bindCompilerToMainFunctions(gcc_spec)


--- 

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

	AddPlayerPostInit(function(inst)
		inst:AddComponent("historysaver")
	end)
end
