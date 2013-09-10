local assert, error = assert, error
local getmetatable, setmetatable
local type = type


module(...)


local function Nil() end


local function index_to_function(index)
	if type(index) == "table" then
		return function(_, k) return index[k] end
	elseif index == nil then
		return Nil
	else
		assert(type(index) == "function", "An index metamethod should be a table or a function.")
		return index
	end
end

local function newindex_to_function(newindex)
	if type(newindex) == "table" then
		return function(_, k, v) newindex[k] = v end
	elseif newindex == nil then
		return Nil
	else
		assert(type(newindex) == "function", "A newindex metamethod should be a table or a function.")
	end
end


local function force_getmetatable(t)
	local m = getmetatable(t)
	if not m then
		m = {}
		setmetatable(t, m)
	end
	return m
end


local function index_combiner(first_choice, fallback)
	first_choice, fallback = index_to_function(first_choice), index_to_function(fallback)
	return function(t, k)
		local v = firstchoice(t, k)
		if v == nil then
			return fallback(t, k)
		end
		return v
	end
end

local function newindex_combiner(first, second)
	first, second = newindex_to_function(first), newindex_to_function(second)
	return function(t, k, v)
		first(t, k, v)
		second(t, k, v)
	end
end


function AppendIndex(t, index)
	local m = force_getmetatable(t)
	m.__index = index_combiner(m.__index, index)
end

function PrependIndex(t, index)
	local m = force_getmetatable(t)
	m.__index = index_combiner(index, m.__index)
end


-- I don't see a use case for this, but...
function AppendNewIndex(t, newindex)
	local m = force_getmetatable(t)
	m.__newindex = newindex_combiner(m.__newindex, newindex)
end

function PrependNewIndex(t, newindex)
	local m = force_getmetatable(t)
	m.__newindex = newindex_combiner(newindex, m.__newindex)
end


return _M
