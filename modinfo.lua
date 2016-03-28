-- This information tells other players more about the mod
name = "Better Console"
description = "A few improvements to the console"
author = "simplex and squeek"
version = "2.0.0"

dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
dst_compatible = true

client_only_mod = true
all_clients_require_mod = false

forumthread = "/files/file/1467-dst-better-console/"

api_version = 6
api_version_dst = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- Load before absolutely everything
priority = 2^10

---

configuration_options = {
{
    name = "HISTORY_LINES_SAVED",
    default = 64,
    options = {{description="56", data=56},{description="58", data=58},{description="60", data=60},{description="62", data=62},{description="64", data=64},{description="66", data=66},{description="68", data=68},{description="70", data=70},{description="72", data=72},{description="74", data=74},},
    label = "History size",
},{
    name = "HIDE_LOG_ON_CLOSE",
    default = true,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Hide on close",
},{
    name = "ENABLE_FONT_SCALING",
    default = true,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Font scaling",
},{
    name = "MAX_LINES_IN_CONSOLE_LOG_HISTORY",
    default = 500,
    options = {{description="100", data=100},{description="200", data=200},{description="300", data=300},{description="400", data=400},{description="500", data=500},{description="600", data=600},{description="700", data=700},{description="800", data=800},{description="900", data=900},{description="1000", data=1000},},
    label = "Log history size",
},{
    name = "ENABLE_BLACK_OVERLAY",
    default = true,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Black overlay",
},{
    name = "BLACK_OVERLAY_OPACITY",
    default = 0.5,
    options = {{description="0", data=0},{description="0.1", data=0.1},{description="0.2", data=0.2},{description="0.3", data=0.3},{description="0.4", data=0.4},{description="0.5", data=0.5},{description="0.6", data=0.6},{description="0.7", data=0.7},{description="0.8", data=0.8},{description="0.9", data=0.9},},
    label = "Overlay opacity",
},{
    name = "ENABLE_CONSOLE_COMMAND_AUTOEXEC",
    default = true,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Command autoexec",
},{
    name = "ENABLE_VARIABLE_AUTOPRINT",
    default = true,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Variable autoprint",
},{
    name = "MULTILINE_INPUT",
    default = false,
    options = {{description="true", data=true},{description="false", data=false},},
    label = "Multiline input",
},
}

