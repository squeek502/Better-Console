module(..., package.seeall)

local function default_error_handler(err)
	nolineprint(err)
end

local function Nil() end

---
-- Coroutine body compiling chunks of text.
--
-- @param self A compiler object.
local function compiler_body(self)
	local chunkname = self.name and ("=" .. self.name)
	self.chunkname = chunkname

	-- Saved pieces of an incomplete chunk.
	self.code_pieces = {}

	local function line_grabber()
		-- Indicates the need for further input.
		self.status = "RUNNING"

		while true do
			--print "waiting line"
			local newline = coroutine.yield(true, nil):gsub("%s+$", "")
			if newline ~= "" then
			--	print("got line ", newline)
				return newline
			end
		end
	end

	local function NewHistoryFeeder(callback)
		local i = 0

		return function()
			if i < #self.code_pieces then
				i = i + 1
				local piece = self.code_pieces[i]
				if i == 1 and self.preprocessor then
					piece = self.preprocessor(piece)
				end
				return piece .. "\n"
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

	local is_incomplete = false

	local function set_incomplete()
		if self:IsMultiline() then
			is_incomplete = true
		end
	end

	while true do
		--print "loop start"
		is_incomplete = false

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

local function copyCompiler(new, old)
	new.multiline = old.multiline or false

	new.preprocessor = old.preprocessor
	new.processor = old.processor
	
	new.error_handler = old.error_handler or default_error_handler
end

---
-- @description The compiler class.
--
-- @param name User friendly name of the object.
--
-- @class table
local Compiler = Class(function(self, name)
	assert( type(name) == "string" )

	self.name = name

	copyCompiler(self, {})
	
	self.compiler_thread = coroutine.create(compiler_body)

	-- If coroutine.resume fails, it returns false followed
	-- by the error message, so the assert below will print
	-- an informative error, if need be.
	assert( coroutine.resume(self.compiler_thread, self) )
	assert( self.status == "IDLE" )
	assert( self.code_pieces )
end)

function Compiler:Copy(newname)
	local c = Compiler(newname or self.name)
	copyCompiler(c, self)
	return c
end

function Compiler:GetRawChunk()
	return table.concat(self.code_pieces, " ")
end

function Compiler:GetChunk()
	local chunk = self:GetRawChunk()
	if self.preprocessor then
		chunk = self.preprocessor(chunk)
	end
	return chunk
end

function Compiler:GetChunkName()
	return self.chunkname
end

function Compiler:GetMultilineChunk()
	return table.concat(self.code_pieces, "\n")
end

function Compiler:Clear()
	self.code_pieces = {}
end

function Compiler:IsIdle()
	return self.status == "IDLE"
end

function Compiler:IsRunning()
	return self.status == "RUNNING"
end
Compiler.IsHungry = Compiler.IsRunning

function Compiler:GetStatus()
	return self.status
end

function Compiler:IsMultiline()
	return self.multiline
end

function Compiler:SetMultiline(state)
	self.multiline = self.multiline
end

function Compiler:ToggleMultiline()
	self:SetMultiline(not self:IsMultiline())
end

-- Runs over the final chunk.
function Compiler:SetPreprocessor(preprocessor)
	self.preprocessor = preprocessor
end

function Compiler:SetProcessor(processor)
	self.processor = processor
end

function Compiler:SetErrorHandler(handler)
	self.error_handler = handler
end

---
-- @description Compiles a code string.
--
-- @return If it (possibly concatenated with previous input) is a
-- complete, valid Lua chunk, returns true followed by the function
-- corresponding to calling loadstring over the concatenation of such
-- input.
--
-- @return If it is an incomplete chunk and multiline support is enabled,
-- returns true followed by nil.
--
-- @return If it (possibly concatenated with previous input) is an invalid Lua
-- chunk, returns false followed by an error message.
function Compiler:Compile(str)
	if self:IsIdle() then
		coroutine.resume(self.compiler_thread)
		assert( self:IsRunning() )
	end

	local co_status, ok, fn =
		coroutine.resume(self.compiler_thread, str)

	if not co_status then
		-- Then the second return value is the error message.
		error(ok)
	end

	if not ok then
		if self.error_handler then
			self.error_handler(fn, self)
			return true, Nil
		end
		return false, fn
	else
		if fn then
			if self.processor then
				self.processor(fn, self)
			end
			return true, fn
		else
			return true
		end
	end
end

Compiler.__call = Compiler.Compile

return Compiler
