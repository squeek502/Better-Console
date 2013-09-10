--[[
-- Defines a "view" of a CircularQueue with a given offset.
--
-- Only matters for the Tail method.
--]]

module(..., package.seeall)


local CircularQueue = require 'betterconsole.circularqueue'


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
	offset = math.min(0, math.max(-self.size + 1, offset))
	if self:IsValidOffset( offset ) then
		self.offset = offset
	end
end

function CircularQueueView:GetViewSize()
	return self.viewsize
end

function CircularQueueView:SetViewSize( viewsize )
	assert( type(viewsize) == "number" and viewsize > 0 )
	self.viewsize = viewsize
end

function CircularQueueView:IsValidOffset(offset)
	return offset > -self.size+self.viewsize
end

function CircularQueueView:Reset()
	self:SetOffset(0)
end

-- Steps towards the end.
function CircularQueueView:Step()
	self:SetOffset( self:GetOffset() + 1 )
end

-- Steps towards the beginning.
function CircularQueueView:StepBack()
	self:SetOffset( self:GetOffset() - 1 )
end

function CircularQueueView:Get(offset)
	offset = offset or 0
	return CircularQueue.Get(self, self.offset + offset)
end

function CircularQueueView:Tail(n, offset)
	offset = (offset or 0) + self.offset
	n = n or self.viewsize
	return CircularQueue.Tail(self, n, offset)
end


return CircularQueueView
