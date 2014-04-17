module(..., package.seeall)

---
-- Function to be wrapped in a coroutine.
--
-- @param self An interpreter object.
local function process_code(self)
	local chunkname = self.name and ("=" .. self.name)


	local function line_grabber()
		-- Indicates the need for further input.
		self.status = "RUNNING"

		while true do
			--print "waiting line"
			local newline = coroutine.yield(false, nil):gsub("%s+$", "")
			if newline ~= "" then
			--	print("got line ", newline)
				return newline
			end
		end
	end


	-- Saved pieces of an incomplete chunk.
	self.code_pieces = {}

	local function NewHistoryFeeder(callback)
		local i = 0

		return function()
			if i < #self.code_pieces then
				i = i + 1
				return self.code_pieces[i] .. "\n"
			elseif i == #self.code_pieces then
				callback()
				return nil
			end
		end
	end

	
	--print "first halt"
	self.status = "IDLE"
	-- Halts execution, waiting for the first input.
	coroutine.yield()


	while true do
		--print "loop start"
		local is_incomplete = false
		local set_incomplete = self:IsMultiline() and function() is_incomplete = true end or function() end

		table.insert( self.code_pieces, line_grabber() )
		local fn, err = load( NewHistoryFeeder(set_incomplete), chunkname )
		--print "load ended"
		self.status = "IDLE"

		if fn then
			--print "function loaded"
			coroutine.yield(true, fn)
			self.code_pieces = {}
		elseif not is_incomplete then
			--print "invalid chunk"
			coroutine.yield(false, err)
			self.code_pieces = {}
		else
			--print "incomplete chunk"
		end
	end
end

---
-- @description The interpreter class.
--
-- The constructor receives its name followed by the environment to run code
-- in.
--
-- @class table
local Interpreter = Class(function(self, name, env)
	assert( type(name) == "string" )
	assert( type(env) == "table" )

	self.name = name
	self.env = env
	self.multiline = true
	
	self.code_processor = coroutine.create(process_code)

	-- If coroutine.resume fails, it returns false followed
	-- by the error message, so the assert below will print
	-- an informative error, if need be.
	assert( coroutine.resume(self.code_processor, self) )
	assert( self.status == "IDLE" )
	assert( self.code_pieces )
end)

function Interpreter:GetChunk()
	return table.concat(self.code_pieces, " ")
end

function Interpreter:IsIdle()
	return self.status == "IDLE"
end

function Interpreter:IsRunning()
	return self.status == "RUNNING"
end
Interpreter.IsHungry = Interpreter.IsRunning

function Interpreter:GetStatus()
	return self.status
end

function Interpreter:IsMultiline()
	return self.multiline
end

function Interpreter:SetMultiline(state)
	self.multiline = not self.multiline
end

function Interpreter:ToggleMultiline()
	self:SetMultiline(not self:IsMultiline())
end

local function split_first(x, ...)
	return x, {n = select("#", ...), ...}
end

---
-- @description Processes a code string.
--
-- @return If it (possibly concatenated with previous input) is a
-- complete, valid Lua chunk, returns table with its return values,
-- if any.
--
-- @return false if it is an invalid or incomplete Lua chunk. If the
-- second return value is nil, it is incomplete. Otherwise, the second
-- return value is the error message.

function Interpreter:Process(code)
	--print("process ", code)
	local fn

	do
		if self:IsIdle() then
			coroutine.resume(self.code_processor)
			assert( self:IsRunning() )
		end

		local coroutine_status, code_status, ret = coroutine.resume(self.code_processor, code)
	
		if not coroutine_status then
			-- Then the second return value is the error message.
			return error(code_status)
		end
		if not code_status then
			return false, ret
		end

		fn = ret
	end

	assert( type(fn) == "function" )

	setfenv(fn, self.env)

	local run_status, run_rets = split_first(xpcall(fn, debug.traceback))

	if run_status then
		return run_rets
	else
		return false, run_rets[1]
	end
end


Interpreter.__call = Interpreter.Process


return Interpreter
