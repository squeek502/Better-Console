
local Widget = require "widgets/widget"
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
		local chunkname
	
		SuUsedAdd("console_used")

		if fnstr:sub(0,1) == "=" then
			fnstr = string.gsub(fnstr, "^=%s*", "return ")
		end
	
		-- ignore consecutive duplicates
		local laststr = #CONSOLE_HISTORY > 0 and CONSOLE_HISTORY[#CONSOLE_HISTORY] or nil
		if laststr ~= nil and laststr == fnstr then
			table.remove(CONSOLE_HISTORY)
		end
		table.insert( CONSOLE_HISTORY, fnstr )

		-- reset history index on each new command
		self.history_idx = nil
	
		nolineprint("> "..fnstr)

		local result = { self:DoString( fnstr, chunkname ) }
		
		if next(result) then
			nolineprint( unpack(result) )
		end
		
	end
end

function ConsoleScreen:IsConsoleCommand( str )
	if string.starts( str, BetterConsole.Config.CONSOLE_COMMAND_PREFIX ) then
		if str:match("^[A-Za-z0-9_]+$", 2) then
			return true
		end
	end

	return false
end

function ConsoleScreen:DoString( fnstr, chunkname )
	local fn, loaderror = loadstring( fnstr, chunkname )

	if not fn then
		local retry, isconsolecommand = false, false

		if BetterConsole.Config.ENABLE_CONSOLE_COMMAND_AUTOEXEC and self:IsConsoleCommand(fnstr) then
			fnstr = "return "..fnstr.."()"
			retry = true
		elseif BetterConsole.Config.ENABLE_VARIABLE_AUTOPRINT and loaderror:match("'=' expected near '<eof>'") then
			fnstr = "return "..fnstr
			retry = true
		end

		if retry then
			fn = loadstring( fnstr, chunkname )
		end
	end

	if fn then
		
		local result = { pcall( fn ) }
		local status = result[1]

		if status then
			-- get nil returns if they are succeeded by non-nil ones (under a certain limit of consecutive nil values)
			-- this allows us to properly print a return like nil, "errormsg"
			local max_consecutive_nils = 5
			local consecutive_nils = 0
			local last_non_nil = 1
			local i = last_non_nil+1
			while consecutive_nils < max_consecutive_nils do
				if result[i] == nil then
					consecutive_nils = consecutive_nils + 1
				else
					for n=i-1,last_non_nil+1,-1 do
						result[n] = tostring(nil)
					end
					last_non_nil = i
					consecutive_nils = 0
				end
				i = i+1
			end
		end

		return select(2, unpack(result))

	end

	return loaderror
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
	if BetterConsole.Config.ENABLE_BLACK_OVERLAY then
	    self.blackoverlay = self:AddChild( Image("images/global.xml", "square.tex") )
	    self.blackoverlay:SetVRegPoint(ANCHOR_MIDDLE)
	    self.blackoverlay:SetHRegPoint(ANCHOR_MIDDLE)
	    self.blackoverlay:SetVAnchor(ANCHOR_MIDDLE)
	    self.blackoverlay:SetHAnchor(ANCHOR_MIDDLE)
	    self.blackoverlay:SetScaleMode(SCALEMODE_FILLSCREEN)
		self.blackoverlay:SetClickable(false)
		self.blackoverlay:SetTint(0,0,0,BetterConsole.Config.BLACK_OVERLAY_OPACITY)
	end

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