local History = require 'betterconsole.history'


local HistorySaver = Class(function(self, inst)
	self.inst = inst
end)


function HistorySaver:OnSave()
	return History.Save()	
end

function HistorySaver:OnLoad(data)
	History.Load(data)
end


return HistorySaver
