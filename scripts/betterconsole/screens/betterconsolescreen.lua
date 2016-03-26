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

local preprocess = require "betterconsole.preprocess"
local Compiler = require "betterconsole.compiler"
require "betterconsole.processor"

--- 

local oldRun = assert( ConsoleScreen.Run )

--- 

--[[
-- I split this from DoInit() just for visibility, since they are quite
-- important below.
--]]
local function ImbueEssentials(self)
	self.compiler = Compiler("console")

	local function process(fn)
		local chunk = self.compiler:GetChunk()
		-- ignore consecutive duplicates
		if chunk ~= History.history:Get() then
			History.history:Insert( chunk )
		end

		if self.toggle_remote_execute then
			nolineprint("% "..chunk)
		end

		self.console_edit:SetString(chunk)
		return oldRun(self)
	end

	self.compiler:SetMultiline(CFG.MULTILINE_INPUT_DEFAULT)
	self.compiler:SetPreprocessor(preprocess)
	self.compiler:SetProcessor(process)
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

	if not down and key == KEY_UP then
		self.console_edit:SetString( History.history:Get() or "" )
		History.history:Step(-1)
		return true
	elseif not down and key == KEY_DOWN then
		if History.history:GetOffset() == 0 then
			local str = self.console_edit:GetString()
			if not str:find("^%s*$") then
				local prechunk = self.compiler:GetChunk()
				if #prechunk > 0 then
					str = prechunk.." "..str
				end
				if str ~= History.history:Get() then
					History.history:Insert(str)
				end
			end
		else
			History.history:Step(1)
		end
		self.console_edit:SetString( History.history:Get(1) or "" )
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

	self.compiler(fnstr)
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
    	self.multilineinputbutton:SetText((self.compiler:IsMultiline() and "Disable" or "Enable").." Multi-Line Input")
    end
    SetButtonTextBasedOnState()
    self.multilineinputbutton:SetOnClick( function() self.compiler:ToggleMultiline(); SetButtonTextBasedOnState(); end )
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
