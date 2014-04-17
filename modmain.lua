-- improve the console

-------------------------------------------
-- load config
-------------------------------------------

modimport 'configurable.lua'

LoadConfig 'config.default.lua'
LoadConfig 'config.lua'


-------------------------------------------
-- bootstrap
-------------------------------------------

GLOBAL.require('betterconsole.main')(env)
