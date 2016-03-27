local ConsoleEnv = require "betterconsole.environment.console"
local CWDPattern = require "betterconsole.lib.cwdpattern"

module(..., package.seeall)

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

local function default_error_handler(err)
	-- clean up the error message/stack trace
	-- get rid of any part of the stack trace that is irrelevant (the console xpcall trace and below)
	local start_of_console_trace = err:find("%s*=.-%(%d+,%d+%) in main chunk")
	if start_of_console_trace then
		err = err:sub(0, start_of_console_trace)
	end

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

function Processor:Process(fn)
	--print("process ", code)

	assert( type(fn) == "function" )

	setfenv(fn, self.env)

	local run_status, run_rets = split_first(pcall(fn))

	if run_status then
		if self.consumer then
			self.consumer(run_rets, self)
		end
		return true, run_rets
	else
		if self.error_handler then
			self.error_handler(run_rets[1])
		end
		return false, run_rets[1]
	end
end


Processor.__call = Processor.Process


return Processor
