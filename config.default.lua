
-------------------------------------------
-- Default settings
-------------------------------------------
-- Copy this file and name it config.lua
-- to modify the settings
-------------------------------------------


-- how many lines of console history to save across game sessions.
-- the save is done on a per-slot bases, and setting it to 0 disables it.
HISTORY_LINES_SAVED = publish(24, "History size", {ETC, 1, 3, ETC})

-- when true, hides the console log when the console it closed.
HIDE_LOG_ON_CLOSE = publish(true, "Hide on close")

-- when true, scales the font sizes of the console input and log based on your current resolution (while making them a bit smaller overall)
ENABLE_FONT_SCALING = publish(true, "Font scaling")

-- max lines to keep in the console log history
MAX_LINES_IN_CONSOLE_LOG_HISTORY = publish(500, "Log history size", {100, 200, ETC})

-- when true, adds a partially transparent black background to the console screen
ENABLE_BLACK_OVERLAY = publish(true, "Black overlay")
-- controls the opacity of the black background; 0 = fully transparent, 1 = fully opaque
BLACK_OVERLAY_OPACITY = publish(.5, "Overlay opacity", {n = 11, 0, .1, ETC})

-- when true, automatically runs console commands when they are inputted to the console (example: 'c_select' will be translated to 'return c_select())
ENABLE_CONSOLE_COMMAND_AUTOEXEC = publish(true, "Command autoexec")

-- when true, automatically prints back the value of a variable when only a variable name is input to the console (example: 'TUNING' will be translated to 'return TUNING')
ENABLE_VARIABLE_AUTOPRINT = publish(true, "Variable autoprint")

-- when true, enables multiline console input support by default (can be toggled on/off ingame)
MULTILINE_INPUT = publish(false, "Multiline input")
