local Widget = require "widgets/widget"
local Text = require "widgets/text"

local TextEdit = Class(Text, function(self, font, size, text)
    Text._ctor(self, font, size, text)

    self.inst.entity:AddTextEditWidget()
    self:SetString(text)
    self:SetEditing(false)
    self.validrawkeys = {}
	self.allselected = false

end)

function TextEdit:SetString(str)
	if self.inst and self.inst.TextEditWidget then
		self.inst.TextEditWidget:SetString(str or "")
	end
end

function TextEdit:SetEditing(editing)
	if editing then
		self:SetFocus()
	end
	self.editing = editing
	self:SetAllSelected( false )
	self.inst.TextWidget:ShowEditCursor(self.editing)
	-- TheFrontEnd:LockFocus(self.editing)
end

function TextEdit:OnMouseButton(button, down, x, y)
	if not self.editing and not down and button == MOUSEBUTTON_LEFT then
		self:SetEditing(true)
	end
	
	if self.editing then
		if not down and button == MOUSEBUTTON_LEFT then
			
		end
	end
end

function TextEdit:OnTextInput(text)

	if not self.editing then return end

	if self.limit then
		local str = self:GetString()
		--print("len", string.len(str), "limit", self.limit)
		if string.len(str) >= self.limit then
			return
		end
	end

	if self.validchars then
		if not string.find(self.validchars, text, 1, true) then
			return
		end
	end
	
	self.inst.TextEditWidget:OnTextInput(text)
end


function TextEdit:OnProcess()
	--self:SetEditing(false)
	TheInputProxy:FlushInput()
	if self.OnTextEntered then
		self.OnTextEntered(self:GetString())
	end
end

function TextEdit:OnRawKey(key, down)
	
	if TextEdit._base.OnRawKey(self, key, down) then return true end
	
	if self.editing then
		--if not down and key == KEY_V and TheInput:IsKeyDown(KEY_CTRL) then
		--	print( "Paste!" )
		--end
		if not down and key == KEY_A and TheInput:IsKeyDown(KEY_CTRL) then
			self:SetAllSelected( true )
			return true
		elseif down then
			local wasallselected = self.allselected
			self:SetAllSelected( false )
			if wasallselected and key == KEY_BACKSPACE then
				self:SetString("")
				return true
			end
		end
	
		if down then
			self.inst.TextEditWidget:OnKeyDown(key)
		else
			self.inst.TextEditWidget:OnKeyUp(key)
		end
	end
	
	if self.validrawkeys[key] then return false end
	
	return true --gobble this up, or we will engage debug keys!
end

function TextEdit:SetAllSelected( state )
	self.allselected = state or false
	if state then
		self.inst.TextWidget:ShowEditCursor(false)
		self:SetColour(0,.75,.75,1)
	else
		self.inst.TextWidget:ShowEditCursor(true)
		self:SetColour(1,1,1,1)
	end
end

function TextEdit:OnControl(control, down)
	if TextEdit._base.OnControl(self, control, down) then return true end

	--gobble up extra controls
	if self.editing and (control ~= CONTROL_CANCEL and control ~= CONTROL_OPEN_DEBUG_CONSOLE and control ~= CONTROL_ACCEPT) then
		return true
	end

	if self.editing and not down and control == CONTROL_CANCEL then
		self:SetEditing(false)
		--return true
	end

	if not down and control == CONTROL_ACCEPT then
		if not self.richedit then
			if self.editing then
				self:OnProcess()
			else
				self:SetEditing(true)
			end
		end

		return true
	end
end

function TextEdit:OnFocusMove()
	return true
end

function TextEdit:OnGainFocus()
	Widget.OnGainFocus(self)
	self:SetEditing(true)

	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
	end

end

function TextEdit:OnLoseFocus()
	Widget.OnLoseFocus(self)
	self:SetEditing(false)
	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
	end

end

function TextEdit:SetFocusedImage(widget, atlas, focused, unfocused)
	self.focusimage = widget
	self.atlas = atlas
	self.focusedtex = focused
	self.unfocusedtex = unfocused

	if self.focusedtex and self.unfocusedtex then
		self.focusimage:SetTexture(self.atlas, self.focus and self.focusedtex or self.unfocusedtex)
	end

end

function TextEdit:SetTextLengthLimit(limit)
	self.limit = limit
end

function TextEdit:SetCharacterFilter(validchars)
	self.validchars = validchars
end

return TextEdit