
local ImageButton = require "widgets/imagebutton"

-- added <> characters as valid (gotta compare stuff!)
local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]

local ConsoleScreen = require "screens/consolescreen"

local BetterConsoleUtil = require "betterconsole/betterconsoleutil"

---------------------------------------------------
-- Overwritten functions
---------------------------------------------------

function ConsoleScreen:OnRawKey( key, down)
	if ConsoleScreen._base.OnRawKey(self, key, down) then return true end
	
	if down then return end

	local CONSOLE_HISTORY = GetConsoleHistory()
	
	if key == KEY_TAB then
		self:AutoComplete()
	elseif key == KEY_UP then
		local len = #CONSOLE_HISTORY
		if len > 0 then
			if self.history_idx ~= nil then
				self.history_idx = math.max( 1, self.history_idx - 1 )
			else
				self.history_idx = len
			end
			self.console_edit:SetString( CONSOLE_HISTORY[ self.history_idx ] )
		end
	elseif key == KEY_DOWN then
		local len = #CONSOLE_HISTORY
		if len > 0 then
			if self.history_idx ~= nil then
				if self.history_idx == len then
					self.history_idx = nil
					self.console_edit:SetString( "" )
				else
					self.history_idx = math.min( len, self.history_idx + 1 )
					self.console_edit:SetString( CONSOLE_HISTORY[ self.history_idx ] )
				end
			end
		end
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

function ConsoleScreen:Run()
	local fnstr = self.console_edit:GetString()

	-- reset log index no matter what (enter becomes an automatic scroll to bottom)
	SetConsoleLogIndex()

	-- no reason not to totally ignore empty strings
	if fnstr ~= "" then

		local CONSOLE_HISTORY = GetConsoleHistory()
	
		SuUsedAdd("console_used")
	
		-- ignore consecutive duplicates
		local laststr = #CONSOLE_HISTORY > 0 and CONSOLE_HISTORY[#CONSOLE_HISTORY] or nil
		if laststr ~= nil and laststr == fnstr then
			table.remove(CONSOLE_HISTORY)
		end
		table.insert( CONSOLE_HISTORY, fnstr )

		-- reset history index on each new command
		self.history_idx = nil
	
		nolineprint("> "..fnstr)
		
		local status, r = pcall( loadstring( fnstr ) )
		if not status and r == "attempt to call a nil value" then
			fnstr = "return "..fnstr
			status, r = pcall( loadstring( fnstr ) )
			r = tostring(r)
		end
		
		if not status then
			nolineprint(r)
		elseif r ~= nil then
			nolineprint(r)
		end
		
	end
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
	TheFrontEnd:HideConsoleLog()
end

---------------------------------------------------
-- Extended functions
---------------------------------------------------

local ConsoleScreen_DoInit_base = ConsoleScreen.DoInit or function() end
function ConsoleScreen:DoInit()
	ConsoleScreen_DoInit_base(self)

	if BetterConsole.Config.ENABLE_FONT_SCALING then
		local text_size = BetterConsoleUtil.GetScaledTextSize( 30 )
		self.console_edit:SetSize( text_size )
	end

	local edit_width, label_height = self.console_edit:GetRegionSize()

	self.console_edit:SetCharacterFilter( VALID_CHARS )
	self.console_edit.richedit = true -- setting specific to bettertextedit

	self.default_focus = self.console_edit
	self.focus_forward = self.console_edit

	self.console_edit.validrawkeys[KEY_ENTER] = true
	
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
    self.clearbutton:SetPosition(0, -label_height, 0)
    self.clearbutton:SetText("Clear Console")
    self.clearbutton:SetOnClick( function() ClearConsoleLog() end )
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
	SetConsoleLogIndex( GetConsoleLogIndex() - 3 )
end

function ConsoleScreen:ScrollLogDown()
	SetConsoleLogIndex( GetConsoleLogIndex() + 3 )
end

return ConsoleScreen