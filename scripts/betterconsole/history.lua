--[[
-- Command history.
--]]

module(..., package.seeall)


local CFG = require 'betterconsole.cfg_table'
local CircularQueue = require 'betterconsole.circularqueueview'
local CircularQueueView = require 'betterconsole.circularqueueview'


history = CircularQueueView( CFG.CONSOLE_HISTORY or 128 )


function Save()
	local howmany = CFG.HISTORY_LINES_SAVED or history.size
	if howmany <= 0 then return end

	return CircularQueue.Tail(history, howmany)
end

function Load(data)
	if type(data) ~= "table" then return end

	local howmany = math.min(#data, history.maxsize)

	history:Clear()

	for i, v in ipairs(data) do
		history:Insert(v)
	end
end


return _M
