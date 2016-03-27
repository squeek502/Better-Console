module(..., package.seeall)

local CircularQueue = Class(function(self, maxsize)
	assert( type(maxsize) == "number" and maxsize > 0 )

	self.size = 0
	self.maxsize = maxsize

	self.data = {}

	-- Points to the last entry
	self.i = 0
end)

function CircularQueue:Clear()
	self.size = 0
end

-- Inserts at the end.
function CircularQueue:Insert(x)
--	TheSim:LuaPrint("Insert! " .. tostring(self))
	self.i = self.i + 1
	if self.i > self.maxsize then
		self.i = self.i - self.maxsize
	end
	self.data[self.i] = x
	self.size = math.min(self.size + 1, self.maxsize)
end

-- Removes from the beginning.
function CircularQueue:Remove()
	if self.size == 0 then return end

	local idx = (self.i - self.size + 1) % self.maxsize
	local x = self.data[idx]
	self.data[idx] = nil
	self.size = self.size - 1

	return x
end

-- Tail access
function CircularQueue:Get(offset)
	offset = offset or 0
	assert( type(offset) == "number" )

	if offset > 0 or self.size == 0 then return end

	return self.data[ (self.i + offset) % self.maxsize ]
end

function CircularQueue:Set(offset, val)
	offset = offset or 0

	assert( type(offset) == "number" )

	if offset > 0 or self.size == 0 then return end

	self.data[ (self.i + offset) % self.maxsize ] = val
end

-- Returns the n elements from the end as a table, with a given offset.
function CircularQueue:Tail(n, offset)
--	TheSim:LuaPrint("Tail " .. tostring(n) .. " " .. tostring(offset) .. " size=" .. tostring(self.size) .. " maxsize=" .. tostring(self.maxsize) .. " " .. tostring(self))

	assert( type(n) == "number" )

	offset = offset or 0
	assert( type(offset) == "number" )

	if offset > 0 then
		n = n - offset
		offset = 0
	end

	if offset <= -self.size or n <= 0 then return {} end

	n = math.min(n, self.size)
	local j = 1 + ( self.i + offset - n ) % self.maxsize

	local ret = {}

	for count = 1, n do
		ret[count] = self.data[j]
--		TheSim:LuaPrint("Putting " .. tostring(ret[count]))

		j = j + 1
		if j > self.maxsize then
			j = j - self.maxsize
		end
	end

	return ret
end

return CircularQueue
