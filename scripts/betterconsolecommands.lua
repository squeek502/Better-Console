
require "consolecommands"

-- added support for calling this with no parameters to set the debugentity to whats under the mouse
c_select = function(inst)
	inst = inst or TheInput:GetWorldEntityUnderMouse()
	if inst then
		SetDebugEntity(inst)
		return inst
	end
end

-- shortcut to make it the next day
c_nextday = function()
	GetClock():MakeNextDay()
end

-- for debugging this mod
c_testprint = function()
	print("print test")
	nolineprint("nolineprint test")
end