--[[
-- Defines a "view" of a CircularQueue with a given offset.
--
-- Only matters for the Tail method.
--]]

module(..., package.seeall)


local CircularQueue = require "betterconsole.lib.circularqueue"


local CircularQueueView = Class(CircularQueue, function(self, maxsize, viewsize)
	CircularQueue._ctor(self, maxsize)

	self.offset = 0
	self.viewsize = viewsize or 1
end)

function CircularQueueView:GetOffset()
	return self.offset
end

function CircularQueueView:SetOffset(offset)
	assert( type(offset) == "number"  )
	offset = math.min(0, math.max(-self.size + self:GetViewSize(), offset))
	self.offset = offset
end

--[[
-- Returns the "effective" viewsize.
--]]
function CircularQueueView:GetViewSize()
	return math.min(self.viewsize, self.size)
end

function CircularQueueView:SetViewSize( viewsize )
	assert( type(viewsize) == "number" and viewsize > 0 )
	self.viewsize = viewsize
end

--[[
function CircularQueueView:IsValidOffset(offset)
	return -self.size+self:GetViewSize() <= offset and offset <= 0
end
]]--

function CircularQueueView:Reset()
	self:SetOffset(0)
end

-- Steps towards the end.
function CircularQueueView:Step(numsteps)
	self:SetOffset( self:GetOffset() + (numsteps or 1) )
end

-- Steps towards the beginning.
function CircularQueueView:StepBack(numsteps)
	self:Step( -(numsteps or 1) )
end

function CircularQueueView:Get(offset)
	offset = (offset or 0) + self.offset
	return CircularQueue.Get(self, offset)
end

function CircularQueueView:Tail(n, offset)
	offset = (offset or 0) + self.offset
	n = n or self:GetViewSize()
	return CircularQueue.Tail(self, n, offset)
end


return CircularQueueView
