
-------------------------------------------
-- Default settings
-------------------------------------------
-- Copy this file and name it config.lua
-- to modify the settings
-------------------------------------------

-- when true, scales the font sizes of the console input and log based on your current resolution (while making them a bit smaller overall)
ENABLE_FONT_SCALING = true

-- max lines to keep in the console log history
MAX_LINES_IN_CONSOLE_LOG_HISTORY = 1000

-- when true, adds a partially transparent black background to the console screen
ENABLE_BLACK_OVERLAY = true
-- controls the opacity of the black background; 0 = fully transparent, 1 = fully opaque
BLACK_OVERLAY_OPACITY = .5

-- when true, automatically runs console commands when they are inputted to the console (example: 'c_select' will be translated to 'return c_select())
ENABLE_CONSOLE_COMMAND_AUTOEXEC = true
-- console commands must have this prefix to be included in the automatic execution
CONSOLE_COMMAND_PREFIX = "c_"

-- when true, automatically prints back the value of a variable when only a variable name is input to the console (example: 'TUNING' will be translated to 'return TUNING')
ENABLE_VARIABLE_AUTOPRINT = true

-- how many lines of console history to save across game sessions.
-- the save is done on a per-slot bases, and setting it to 0 disables it.
HISTORY_LINES_SAVED = 16
