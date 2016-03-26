---
-- Defines the console environment and related utilities.
--
-- The actual environment is the field "env" in the returned module.


local env_utils = require "betterconsole.environment.utils"


module(..., package.seeall)


local _G = _G


env = {}
meta = {__index = _G}
setmetatable(env, meta)


function env.print(...)
	return nolineprint(...)
end


function SlurpTable(t, overwrite)
	for k, v in pairs(t) do
		if type(k) == "string" and not k:match("^_") then
			if rawget(env, k) == nil or overwrite then
				rawset(env, k, v)
			end
		end
	end
end


for _, metamethod in ipairs{"Index", "NewIndex"} do
	for _, order in ipairs{"Prepend", "Append"} do
		local fullname = order .. metamethod
		local primitive = env_utils[fullname]
		assert( type(primitive) == "function" )

		_M[fullname] = function(fn)
			return primitive(env, fn)
		end
	end
end


return _M
