function ImproveTextEdit(TextEdit)

	-- overwritten to only respond to left mouse clicks
	TextEdit.OnMouseButton = function(self, button, down, x, y)
		if not self.editing and not down and button == MOUSEBUTTON_LEFT then
			self:SetEditing(true)
		end
		
		if self.editing then
			if not down and button == MOUSEBUTTON_LEFT then
				
			end
		end
	end

	-- overwritten to keep editing when processed (enter is pressed)
	TextEdit.OnProcess = function(self)
		--self:SetEditing(false)
		TheInputProxy:FlushInput()
		if self.OnTextEntered then
			self.OnTextEntered(self:GetString())
		end
	end

	-- overwritten to add Select All (CTRL+A) support
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
		
			if down then
				self.inst.TextEditWidget:OnKeyDown(key)
			else
				self.inst.TextEditWidget:OnKeyUp(key)
			end
		end
		
		if self.validrawkeys[key] then return false end
		
		return true --gobble this up, or we will engage debug keys!
	end

	-- overwritten to not gobble CONTROL_CANCEL (so parent widgets can respond to it as well)
	TextEdit.OnControl = function(self, control, down)
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