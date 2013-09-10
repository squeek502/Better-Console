--[[
-- Defines a "view" of a CircularQueue with a given offset.
--
-- Only matters for the Tail method.
--]]

module(..., package.seeall)


local CircularQueue = require 'betterconsole.circularqueue'


local CircularQueueView = Class(CircularQueue, function(self, maxsize)
	CircularQueue._ctor(self, maxsize)

	self.offset = 0
end)

function CircularQueueView:GetOffset()
	return self.offset
end

function CircularQueueView:SetOffset(offset)
	assert( type(offset) == "number"  )
	self.offset = math.min(0, math.max(-self.size + 1, offset))
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
	offset = offset or 0
	return CircularQueue.Tail(self, n, self.offset + offset)
end


return CircularQueueView
