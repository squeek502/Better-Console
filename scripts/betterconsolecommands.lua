
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
	if GetClock() then
		GetClock():MakeNextDay()
	end
end

-- added support for going to the mouse location
c_teleport = function(x, y, z, inst)
	inst = inst or GetPlayer()
	if not x then
		x,y,z = TheInput:GetWorldPosition():Get()
	end
	inst.Transform:SetPosition(x, y, z)
    SuUsed("c_teleport", true)
end

-- for debugging this mod
c_testprint = function()
	print("print test")
	nolineprint("nolineprint test")
end