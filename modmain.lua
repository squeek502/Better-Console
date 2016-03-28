-- improve the console

_G = GLOBAL
require = _G.require

Pred = require "betterconsole.lib.pred"

-------------------------------------------
-- load config
-------------------------------------------

modimport 'configurable.lua'

SetConfigTable( _G.require "betterconsole.cfg_table" )

LoadConfig('config.default.lua', true)
LoadModConfig()
LoadConfig('config.lua')

-- print("Better-Console MOD CONFIG STRING\n"..GenerateModConfigString())

-------------------------------------------
-- bootstrap
-------------------------------------------

_G.require('betterconsole.main')(env)
