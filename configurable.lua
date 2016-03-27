local _G = _G

local assert = _G.assert
local error = _G.error
local type = _G.type
local rawset = _G.rawset
local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable
local tostring = _G.tostring
local tonumber = _G.tonumber
local setfenv = _G.setfenv
local table = _G.table
local pairs = _G.pairs
local ipairs = _G.ipairs

---

local CFG_TABLE

function SetConfigTable(t)
	CFG_TABLE = t
end

---

local ETC = {}

---

local publish_meta = {}
local function is_publish(x)
	return getmetatable(x) == publish_meta
end

local published = {}
local public_options = {}

-- Fits a value in a linear range with minimal error.
local function linfit(y, x0, dx)
	local q = math.floor(0.5 + (y - x0)/dx)
	return x0 + dx*q, q
end

local function shave(x)
	local x_int = math.floor(0.5 + x)

	if math.abs(x - x_int) < 1e-3 then
		return x_int
	else
		return x
	end
end

local SMALL_SAMPLE_ERROR = "Can't ETC with a sample smaller than 2."

local function parse_range(default, range, count)
	local sample = {}
	local flags = {}

	local function retvals()
		return sample, flags
	end

	local insert = table.insert

	local nrange = #range
	local expand_left = false
	local expand_right = false
	local i = 1

	--[[
	-- Parses the range looking for ETCs.
	--]]
	while i <= nrange do
		local v = range[i]
		if v ~= ETC then
			insert(sample, v)
		else
			if #sample < 2 then
				flags.expand_left = true

				if #sample > 0 then
					error(SMALL_SAMPLE_ERROR)
				end

				i = i + 1
				while i <= nrange do
					local w = range[i]
					if w == ETC then
						flags.expand_right = true
						break
					end
					insert( sample, w )
					i = i + 1
				end
				assert( i == nrange )

				if #sample < 2 then
					error(SMALL_SAMPLE_ERROR)
				end
			else
				flags.expand_right = true
			end
		end

		i = i + 1
	end

	return retvals()
end

--[[
-- Expands a range, which may be either explicit, be an arithmetical
-- progression or be a geometrical progression.
--]]
local function expand_range(default, range, count)
	local sample, flags = parse_range(default, range, count)

	local nsample = #sample

	-- No range expansion.
	if not (flags.expand_left or flags.expand_right) then
		-- TODO: best fit
		return sample, default
	end

	assert( nsample >= 2 )
	for _, v in ipairs(sample) do
		assert( type(v) == "number" )
	end

	local range_type
	local advance
	if nsample == 2 or (sample[2] - sample[1]) == (sample[3] - sample[2]) then
		range_type = "linear"

		local diff = sample[2] - sample[1]

		local function linadvance(x, steps)
			return x + steps*diff
		end
		advance = linadvance
	else
		assert(sample[2]/sample[1] == sample[3]/sample[2], "Geometric progression expected.")
		range_type = "geometric"

		local ratio = sample[2]/sample[1]

		local powers = {[0] = 1, [1] = ratio}
		local function compute_power(n)
			local ret = powers[n]
			if ret == nil then
				if n < 0 then
					ret = 1/compute_power(-n)
				else
					ret = ratio*compute_power(n - 1)
				end
				powers[steps] = ret
			end
		end

		local function geoadvance(x, steps)
			return x*compute_power(steps)
		end
		advance = geoadvance
	end

	if range_type == "linear" then
		default = linfit(default, sample[1], sample[2] - sample[1])
	else
		default = math.log(default)

		default = linfit(default, math.log(sample[1]), math.log(sample[2]/sample[1]))

		default = math.exp(default)
	end

	default = shave(default)

	if flags.expand_left and flags.expand_right then
		print"Shrunk sample"
		sample = {default}
		nsample = 1
	end

	local ret = {}
	do
		-- Values remaining.
		local rem = count - nsample
		if rem <= 0 then
			return sample, default
		end

		local on_the_left, on_the_right = 0, 0
		if flags.expand_left and flags.expand_right then
			print "even split"
			on_the_left = math.floor(rem/2)
			on_the_right = math.ceil(rem/2)
		elseif flags.expand_left then
			print "left slant"
			on_the_left = rem
		else
			print "right slant"
			on_the_right = rem
		end

		for i, v in ipairs(sample) do
			ret[i + on_the_left] = v
		end

		for i = on_the_left, 1, -1 do
			ret[i] = advance(ret[i + 1], -1)
		end
		for i = on_the_left + nsample + 1, on_the_left + nsample + on_the_right do
			ret[i] = advance(ret[i - 1], 1)
		end
	end
	return ret, default
end

local DEFAULT_COUNT = 10

local function NewDataFetcher(data)
	local i = 1
	return function(k)
		local v = data[k]
		if v == nil then
			v = data[i]
			i = i + 1
		end
		return v
	end
end

local function expand_options(range)
	local opts = {}
	for i, v in ipairs(range) do
		opts[i] = {description = tostring(v), data = v}
	end
	return opts
end

local function publish(data, ...)
	if type(data) ~= "table" then
		data = {data, ...}
	end

	local fetch = NewDataFetcher(data)

	local default = fetch "default"
	local label = assert( fetch "label" )
	assert(type(label) == "string")
	local range = fetch "range"
	if type(default) == "boolean" and range == nil then
		range = {true, false}
	end
	assert(type(range) == "table")
	local count = fetch "n" or DEFAULT_COUNT
	assert(type(count) == "number")

	print("Publishing "..label)

	range, default = expand_range(default, range, count)

	return setmetatable({
		name = nil,
		label = label,
		options = expand_options(range),
		default = default,
	}, publish_meta)
end

local new_cfg_env = (function()
	local template = {
		ETC = ETC,
		publish = publish,

		TUNING = TUNING,
		math = math,
		table = table,
		string = string,
		tostring = tostring,
		tonumber = tonumber,
	}

	return function(can_publish)
		local env = {}
		for k, v in pairs(template) do
			env[k] = v
		end

		local meta = {
			__index = CFG_TABLE,
		}

		function meta:__newindex(k, v)
			if is_publish(v) then
				if can_publish then
					local data = {}
					for l, w in pairs(v) do
						data[l] = w
					end
					data.name = k
					table.insert(published, data)
					public_options[k] = data
				end

				v = v.default
			end
			CFG_TABLE[k] = v
		end

		return setmetatable(env, meta)
	end
end)()

function GetPublicOptions()
	return pairs(public_options)
end
local GetPublicOptions = GetPublicOptions

function LoadModConfig()
	for optname in GetPublicOptions() do
		CFG_TABLE[optname] = GetModConfigData(optname, true)
	end
end

local function putatom(x)
	if type(x) == "string" then
		return ("%q"):format(x)
	else
		return tostring(x)
	end
end

function GenerateModConfigString()
	local pieces = {"configuration_options = {\n"}
	for _, data in ipairs(published) do
		local name = data.name
		table.insert(pieces, "{\n")
		for k, v in pairs(data) do
			table.insert(pieces, "    "..tostring(k).." = ")
			if type(v) == "table" then
				-- Assume it's array (.options)
				assert(k == "options")
				table.insert(pieces, "{")
				for _, item in ipairs(v) do
					table.insert(pieces, "{description=")
					table.insert(pieces, putatom(item.description))
					table.insert(pieces, ", data=")
					table.insert(pieces, putatom(item.data))
					table.insert(pieces, "},")
				end
				table.insert(pieces, "}")
			else
				table.insert(pieces, putatom(v))
			end
			table.insert(pieces, ",\n")
		end
		table.insert(pieces, "},")
	end
	table.insert(pieces, "\n}\n")
	return table.concat(pieces)
end

-- _G.GMCS = GenerateModConfigString

-- modified (stripped down) version of the LoadConfigs function written by simplex for the Blackhouse mod
-- see: https://github.com/nsimplex/Blackhouse/blob/master/src/customizability.lua
function LoadConfig(file, can_publish)
	local cfg = _G.kleiloadlua(MODROOT .. file)
	if type(cfg) ~= "function" then 
		local msg = cfg
		if not msg then
			msg ="(Better Console) Unable to load " .. file .. ' (does it exist?)'
		end
		if can_publish then
			error(msg)
		else
			print(msg)
		end
		return
	end

	assert( CFG_TABLE )

	-- A sandbox inside a sandbox!
	setfenv(cfg, new_cfg_env(can_publish))

	cfg()
end
