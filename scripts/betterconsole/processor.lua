local ConsoleEnv = require "betterconsole.environment.console"
local CWDPattern = require "betterconsole.lib.cwdpattern"

require "stacktrace"

module(..., package.seeall)

local function Nil() return end


local function default_consumer(run_rets)
	local pieces = {}

	local ret_size = run_rets.n or #run_rets
	if ret_size > 0 then
		for i = 1, ret_size do
			table.insert(pieces, tostring(run_rets[i]))
		end
		nolineprint( table.concat(pieces, "\t") )
	end
end

local function elim_lines(msg, n)
	local patt_block = "[^\n\r]*[\n\r][\n\r]-"

	local patt = "^"
	for i = 1, n do
		patt = patt..patt_block
	end

	return msg:gsub(patt, "")
end

local function traceback(err, level, tracefilter)
	level = level + 1

	local function fake_getdebuglocals(res)
		return res
	end

	local old_getdebuglocals = assert( getdebuglocals )
	_G.getdebuglocals = fake_getdebuglocals

	local raw = StackTrace(err)

	_G.getdebuglocals = old_getdebuglocals

	local trace = elim_lines(raw, level)
	if tracefilter then
		trace = tracefilter(trace)
	end

	return tostring(err).."\nstack traceback:\n"..tostring(trace)
end

local function default_error_handler(err)
	nolineprint(err)
end

---
-- @description The processor class.
--
-- @param env Environment in which to run the code.
--
-- @class table
local Processor = Class(function(self, env)
	env = env or ConsoleEnv.env

	assert( type(env) == "table" )

	self.env = env

	self.consumer = default_consumer
	self.error_handler = default_error_handler
end)

function Processor:SetConsumer(consumer)
	self.consumer = consumer
end

function Processor:SetErrorHandler(handler)
	self.error_handler = handler
end

local function split_first(x, ...)
	return x, {n = select("#", ...), ...}
end

local function NewErrorFilter(gcc)
	local gcc_filter
	if gcc then
		local chunkname = assert(gcc:GetChunkName())
		local line_patt = "^@"..chunkname..":.+$"
		gcc_filter = function(trace)

			local lines = {}
			local last_owned_chunk_idx = nil
			for line in trace:gmatch("[^\n\r]+") do
				table.insert(lines, line)

				if line:find(line_patt) then
					last_owned_chunk_idx = #lines
				end
			end

			if last_owned_chunk_idx then
				for i = last_owned_chunk_idx + 1, #lines do
					lines[i] = nil
				end
			end

			return table.concat(lines, "\n")
		end
	end

	return function(err)
		local status
		status, err = pcall(traceback, err, 4, gcc_filter)
		if not status then
			return "error in error handling\n"..tostring(err)
		end

		-- clean up the error message/stack trace
		-- get rid of any part of the stack trace that is irrelevant (the console xpcall trace and below)
		--
		
		--[[

		-- either make all paths relative to the game dir
		-- or get rid of the stack trace entirely if it's now empty
		local start_of_traceback, traceback_header_len = err:find("LUA ERROR stack traceback:")
		if start_of_traceback then
			if err:sub(start_of_traceback+traceback_header_len):len() > 0 then
				err = err:gsub(CWDPattern, "")
			else
				err = err:sub(0, start_of_traceback-1)
			end
		end

		]]--

		return err
	end
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

function Processor:Process(fn, gcc)
	--print("process ", code)

	assert( type(fn) == "function" )

	setfenv(fn, self.env)
	
	local run_status, run_rets = split_first(xpcall(fn, NewErrorFilter(gcc)))

	if run_status then
		if self.consumer then
			self.consumer(run_rets, self)
		end
		return true, run_rets
	else
		if self.error_handler then
			self.error_handler(run_rets[1], self)
		end
		return false, run_rets[1]
	end
end


Processor.__call = Processor.Process


return Processor
