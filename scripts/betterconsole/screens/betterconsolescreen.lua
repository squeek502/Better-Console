module(..., package.seeall)


local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"

-- added <> characters as valid (gotta compare stuff!)
local VALID_CHARS = [[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;[]\@!#$%&()'*+-/=?^_{|}~"<>]]

local ConsoleScreen = require "screens/consolescreen"

local BetterConsoleUtil = require "betterconsole.lib.betterconsoleutil"
local ImproveTextEdit = require "betterconsole.widgets.bettertextedit"

local CFG = require "betterconsole.cfg_table"
local Logging = require "betterconsole.lib.logging"
local History = require "betterconsole.history"

local Pred = require "betterconsole.lib.pred"

local preprocess = require "betterconsole.preprocess"
local Compiler = require "betterconsole.compiler"
require "betterconsole.processor"

--- 

local dispatchSelf
if Pred.IsDST() then
	dispatchSelf = assert( ConsoleScreen.Run )
else
	dispatchSelf = function(self)
		local fnstr = self.console_edit:GetString()
		SuUsedAdd("console_used")
		return ExecuteConsoleCommand(fnstr)
	end
end

--- 

local function addToHistory(code)
	if code ~= nil and code ~= History.history:Get() then
		History.history:Set(0, code)
		return true
	else
		return false
	end
end

local function insertInHistory(code)
	if code ~= History.history:RawGet() then
		History.history:RawSet(0, code)
		History.history:Insert("")
		return true
	else
		return false
	end
end

--[[
-- I split this from DoInit() just for visibility, since they are quite
-- important below.
--]]
local function ImbueEssentials(self)
	--[[
	-- A Compiler object used only as a syntax analyzer.
	--]]
	self.parser = Compiler("console")

	local function process(fn)
		local chunk = self.parser:GetChunk()
		local r_chunk = self.parser:GetRawChunk()
		self.parser:Clear()

		insertInHistory(r_chunk)

		if self.toggle_remote_execute then
			nolineprint("% "..r_chunk)
		else
			nolineprint("> "..r_chunk)
		end

		self.console_edit:SetString(r_chunk)
		return dispatchSelf(self)
	end

	self.parser:SetMultiline(false)
	self.parser:SetPreprocessor(preprocess)
	self.parser:SetProcessor(process)
end

---------------------------------------------------
-- Patched functions
---------------------------------------------------


local oldClose = ConsoleScreen.Close
function ConsoleScreen:Close()
	oldClose(self)
	if not CFG.HIDE_LOG_ON_CLOSE then
		TheFrontEnd:ShowConsoleLog()
	end
end

-- better up/down arrow history
local oldOnRawKey = ConsoleScreen.OnRawKey or function() end
function ConsoleScreen:OnRawKey(key, down)
	if ConsoleScreen._base.OnRawKey(self, key, down) then return true end

	local function getfullchunk()
		local str = self.console_edit:GetString()
		local prechunk = self.parser:GetChunk()
		if #prechunk > 0 then
			str = prechunk.." "..str
		end
		if not str:find("^%s*$") then
			return str
		end
	end

	if not down and (key == KEY_UP or key == KEY_DOWN) then
		local dir = (key == KEY_UP and -1 or 1)

		if History.history:Get(dir) ~= nil then
			local str = getfullchunk()

			if addToHistory(str) and History.history:GetOffset() == 0 then
				History.history:Insert("")
			end

			History.history:Step(dir)
			self.parser:Clear()
			self.console_edit:SetString( History.history:Get() )
		end

		return true
	elseif not down and key == KEY_ENTER then
		self.console_edit:OnProcess()
	end

	return oldOnRawKey(self, key, down)
end

local oldOnBecomeActive = ConsoleScreen.OnBecomeActive
function ConsoleScreen:OnBecomeActive()
	oldOnBecomeActive(self)
	TheFrontEnd:LockFocus(false)
end

function ConsoleScreen:Run()
	local fnstr = self.console_edit:GetString()

	-- reset log index no matter what (enter becomes an automatic scroll to bottom)
	Logging.loghistory:Reset()

	-- no reason not to totally ignore blank strings
	if fnstr:match("^%s*$") then return end

	-- reset history index on each new command
	History.history:Reset()

	self.parser(fnstr)
end

---------------------------------------------------
-- Overwritten functions
---------------------------------------------------

-- local oldOnTextEntered = ConsoleScreen.OnTextEntered
function ConsoleScreen:OnTextEntered()
	self:Run()
	self.console_edit:SetString( "" )
    if TheFrontEnd.consoletext.closeonrun then
		self:Close()
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
	ImproveTextEdit(self.console_edit)

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

	local BUTSCALE = .7

    self.clearbutton = self.root:AddChild(ImageButton())
    self.clearbutton:SetScale(BUTSCALE, BUTSCALE)
    -- self.clearbutton:ForceImageSize(200,70)
	self.clearbutton:SetTextSize(32)
    self.clearbutton:SetText("Clear Console")
    self.clearbutton:SetOnClick( function() Logging.loghistory:Clear() end )
	self.clearbutton:SetPosition(0, -label_height, 0)


	if CFG.MULTILINE_INPUT then
		self.clearbutton:SetPosition(-105, -label_height, 0)
		self.multilineinputbutton = self.root:AddChild(ImageButton())
		self.multilineinputbutton:SetScale(1.4*BUTSCALE,BUTSCALE)
	--     self.clearbutton:ForceImageSize(200,70)
	--     self.multilineinputbutton.image:SetScale(1.4, 1)
		self.multilineinputbutton:SetPosition(100, -label_height, 0)
		self.multilineinputbutton:SetTextSize(32)
		local function SetButtonTextBasedOnState()
			self.multilineinputbutton:SetText((self.parser:IsMultiline() and "Disable" or "Enable").." Multiline")
		end
		SetButtonTextBasedOnState()
		self.multilineinputbutton:SetOnClick( function() self.parser:ToggleMultiline(); SetButtonTextBasedOnState(); end )
	end
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
