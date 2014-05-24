module(..., package.seeall)


local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

-- added <> characters as valid (gotta compare stuff!)
local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]

local ConsoleScreen = require "screens/consolescreen"

local BetterConsoleUtil = require "betterconsole/betterconsoleutil"


local CFG = require 'betterconsole.cfg_table'
local Logging = require 'betterconsole.logging'
local History = require 'betterconsole.history'
local ConsoleEnv = require 'betterconsole.environment.console'
local Interpreter = require 'betterconsole.lua.interpreter'
local Language = require 'betterconsole.lua.language'
local Commands = require 'betterconsole.environment.commands'
local CWDPattern = require 'betterconsole.cwdpattern'


--[[
-- I split this from DoInit() just for visibility, since they are quite
-- important below.
--]]
local function ImbueEssentials(self)
	self.interpreter = Interpreter("console", ConsoleEnv.env)
	self.interpreter:SetMultiline(CFG.MULTILINE_INPUT_DEFAULT)
end


---------------------------------------------------
-- Overwritten functions
---------------------------------------------------

function ConsoleScreen:OnRawKey( key, down)
	if ConsoleScreen._base.OnRawKey(self, key, down) then return true end
	
	if down then return end

	if key == KEY_TAB then
		self:AutoComplete()
	elseif key == KEY_UP then
		self.console_edit:SetString( History.history:Get() or "" )
		History.history:Step(-1)
	elseif key == KEY_DOWN then
		History.history:Step(1)
		self.console_edit:SetString( History.history:Get(1) or "" )
	elseif key == KEY_ENTER then
		self.console_edit:OnProcess()
	else
		self.autocompletePrefix = nil
		self.autocompleteObjName = ""
		self.autocompleteObj = nil
		self.autocompleteOffset = -1
		return false
	end
	
	return true
end

-- just need to overwrite this, Klei made the console lock focus in this function :(
function ConsoleScreen:OnBecomeActive()
	ConsoleScreen._base.OnBecomeActive(self)
	TheFrontEnd:ShowConsoleLog()

	self.console_edit:SetEditing(true)
end

function ConsoleScreen:Run()
	local fnstr = self.console_edit:GetString()

	-- reset log index no matter what (enter becomes an automatic scroll to bottom)
	Logging.loghistory:Reset()

	-- no reason not to totally ignore blank strings
	if fnstr:match("^%s*$") then return end

	SuUsedAdd("console_used")

	-- reset history index on each new command
	History.history:Reset()

	nolineprint("> "..fnstr)

	local result = self:DoString( fnstr )

	if self.interpreter:IsIdle() then
		local chunk = self.interpreter:GetChunk()
--		TheSim:LuaPrint("Got chunk: " .. (chunk or ""))
		-- ignore consecutive duplicates
		if chunk ~= History.history:Get() then
--			TheSim:LuaPrint("Storing chunk.")
			History.history:Insert( chunk )
		end
	end

	local result_size = result and (result.n or #result) or 0
	
	if result_size > 0 then
		local r = {}
		for i = 1, result_size do
			local v = result[i]
			table.insert(r, tostring(v))
		end
		nolineprint( unpack(r) )
	end
end

--[[
function ConsoleScreen:IsConsoleCommand( str )
	if string.starts( str, CFG.CONSOLE_COMMAND_PREFIX ) then
		if str:match("^[A-Za-z0-9_]+$", 2) then
			return true
		end
	end

	return false
end
]]--

function ConsoleScreen:DoString( fnstr, is_recursive )
	if self.interpreter:IsIdle() then
		fnstr = string.gsub(fnstr, "^=%s*", "return ")

		if CFG.ENABLE_CONSOLE_COMMAND_AUTOEXEC then
			local id = fnstr:match("^%s*" .. Language.identifier .. "%s*$")
			-- use rawget here to avoid strict.lua when looking up a variable name that doesn't exist
			if id and type( rawget( Commands, id ) ) == "function" then
				fnstr = "return " .. fnstr .. "()"
			end
		end
	end

	local Rets, err = self.interpreter(fnstr)
	if Rets then return Rets end

	if not err then
		--[[
		-- Incomplete chunk.
		-- How to warn the user of this needs some work.
		--]]
		nolineprint("Proceed with input.")
		return
	end

	assert( self.interpreter:IsIdle() )

	if not is_recursive then
		local chunk = self.interpreter:GetChunk()

		local retry, isconsolecommand = false, false

		if not retry and CFG.ENABLE_VARIABLE_AUTOPRINT and err:match("'=' expected near '<eof>'") then
			chunk = "return " .. chunk
			retry = true
		end

		if retry then
			return self:DoString(chunk, true)
		end
	end

	-- clean up the error message/stack trace
	-- get rid of any part of the stack trace that is irrelevant (the console xpcall trace and below)
	local start_of_console_trace = err:find("%s*="..self.interpreter.name.."%(%d+,%d+%) in main chunk")
	if start_of_console_trace then
		err = err:sub(0, start_of_console_trace)
	end

	-- either make all paths relative to the game dir
	-- or get rid of the stack trace entirely if it's now empty
	local start_of_traceback, traceback_header_len = err:find("LUA ERROR stack traceback:")
	if start_of_traceback then
		if err:sub(start_of_traceback+traceback_header_len):len() > 0 then
			err = err:gsub(CWDPattern, "")
		else
			err = err:sub(0, start_of_traceback-1)
		end
	end

	return {err}
end

function ConsoleScreen:OnTextEntered()
	self:Run()
	self.console_edit:SetString( "" )
    if TheFrontEnd.consoletext.closeonrun then
		self:Close()
        TheFrontEnd:HideConsoleLog()
    end
end

function ConsoleScreen:Close()
	SetPause(false)
	TheInput:EnableDebugToggle(true)
	TheFrontEnd:PopScreen()
	if CFG.HIDE_LOG_ON_CLOSE then
		TheFrontEnd:HideConsoleLog()
	end
end

---------------------------------------------------
-- Extended functions
---------------------------------------------------

local ConsoleScreen_DoInit_base = ConsoleScreen.DoInit or function() end
function ConsoleScreen:DoInit()
	if CFG.ENABLE_BLACK_OVERLAY then
	    self.blackoverlay = self:AddChild( Image("images/global.xml", "square.tex") )
	    self.blackoverlay:SetVRegPoint(ANCHOR_MIDDLE)
	    self.blackoverlay:SetHRegPoint(ANCHOR_MIDDLE)
	    self.blackoverlay:SetVAnchor(ANCHOR_MIDDLE)
	    self.blackoverlay:SetHAnchor(ANCHOR_MIDDLE)
	    self.blackoverlay:SetScaleMode(SCALEMODE_FILLSCREEN)
		self.blackoverlay:SetClickable(false)
		self.blackoverlay:SetTint(0,0,0,CFG.BLACK_OVERLAY_OPACITY)
	end

	ConsoleScreen_DoInit_base(self)

	ImbueEssentials(self)

	if CFG.ENABLE_FONT_SCALING then
		local text_size = BetterConsoleUtil.GetScaledTextSize( 30 )
		self.console_edit:SetSize( text_size )
	end

	self.edit_bg:SetClickable(false)

	local edit_width, label_height = self.console_edit:GetRegionSize()

	self.console_edit:SetCharacterFilter( VALID_CHARS )
	self.console_edit.richedit = true -- setting specific to bettertextedit

	self.default_focus = self.console_edit
	self.focus_forward = self.console_edit

	self.console_edit.validrawkeys[KEY_ENTER] = true
	self.console_edit:SetAllowClipboardPaste(true)
	
	self.downbutton = self.root:AddChild(ImageButton("images/ui.xml", "spin_arrow.tex"))
    self.downbutton:SetPosition(edit_width/2+30, label_height, 0)
	self.downbutton:SetScale(.7,.7,.7)
	self.downbutton:SetRotation(90)
    self.downbutton:SetOnClick( function() self:ScrollLogDown() end)

	self.upbutton = self.root:AddChild(ImageButton("images/ui.xml", "spin_arrow.tex"))
    self.upbutton:SetPosition(edit_width/2+30, label_height+40, 0)
    self.upbutton:SetScale(.7,.7,.7)
	self.upbutton:SetRotation(-90)
    self.upbutton:SetOnClick( function() self:ScrollLogUp() end )

    self.clearbutton = self.root:AddChild(ImageButton())
    self.clearbutton:SetScale(.6,.6,.6)
    self.clearbutton:SetPosition(-85, -label_height, 0)
    self.clearbutton:SetText("Clear Console")
    self.clearbutton:SetOnClick( function() Logging.loghistory:Clear() end )

    self.multilineinputbutton = self.root:AddChild(ImageButton())
    self.multilineinputbutton:SetScale(.6,.6,.6)
    self.multilineinputbutton.image:SetScale(1.75, 1, 1)
    self.multilineinputbutton:SetPosition(65, -label_height, 0)
    local function SetButtonTextBasedOnState()
    	self.multilineinputbutton:SetText((self.interpreter:IsMultiline() and "Disable" or "Enable").." Multi-Line Input")
    end
    SetButtonTextBasedOnState()
    self.multilineinputbutton:SetOnClick( function() self.interpreter:ToggleMultiline(); SetButtonTextBasedOnState(); end )
end

---------------------------------------------------
-- Brand new functions
---------------------------------------------------

function ConsoleScreen:OnMouseButton(button, down, x, y)
	if button == MOUSEBUTTON_SCROLLUP then
		self:ScrollLogUp()
		return true
	elseif button == MOUSEBUTTON_SCROLLDOWN then
		self:ScrollLogDown()
		return true
	end
end

function ConsoleScreen:ScrollLogUp()
	Logging.loghistory:StepBack()
	Logging.loghistory:StepBack()
	Logging.loghistory:StepBack()
end

function ConsoleScreen:ScrollLogDown()
	Logging.loghistory:Step()
	Logging.loghistory:Step()
	Logging.loghistory:Step()
end

return ConsoleScreen
