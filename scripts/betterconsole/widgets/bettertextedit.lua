function ImproveTextEdit(TextEdit)
	-- overwritten to only respond to left mouse clicks
	TextEdit.OnMouseButton = function(self, button, down, x, y)
		if not self.editing and not down and button == MOUSEBUTTON_LEFT then
			self:SetEditing(true)
		end
	end

	-- patched to keep editing when processed (enter is pressed)
	local oldOnProcess = TextEdit.OnProcess
	TextEdit.OnProcess = function(self)
		oldOnProcess(self)
		self:SetEditing(true)
	end

	-- patched to add Select All (CTRL+A) support
	local oldOnRawKey = TextEdit.OnRawKey
	TextEdit.OnRawKey = function(self, key, down)
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
		end

		return oldOnRawKey(self, key, down)
	end

	-- patched to not gobble CONTROL_CANCEL (so parent widgets can respond to it as well)
	local oldOnControl = TextEdit.OnControl
	TextEdit.OnControl = function(self, control, down)
		if TextEdit._base.OnControl(self, control, down) then return true end

		if self.editing and not down and control == CONTROL_CANCEL then
			self:SetEditing(false)
			return
		end

		return oldOnControl(self, control, down)
	end

	-- extended to enable editing on focus
	local OnGainFocus_base = TextEdit.OnGainFocus
	TextEdit.OnGainFocus = function(self)
		OnGainFocus_base(self)

		self:SetEditing(true)
	end

	-- added for Select All (CTRL+A) support
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
end

return ImproveTextEdit
