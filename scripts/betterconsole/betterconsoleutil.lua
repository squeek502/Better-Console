local M = {}

local function GetScaledTextSize( max_size, min_size )
	if not min_size then min_size = max_size / 2 end

	local min_screenw = 632 -- this seems to be the case
	local screenw = TheSim:GetScreenSize()

	local screenscale = screenw / min_screenw - 1
	local textscale = (max_size - min_size) / 3

	local new_size = max_size - screenscale * textscale
	new_size = math.floor(new_size + 0.5) -- round it
	new_size = math.max( new_size, min_size )

	--print(screenw, screenscale, textscale, new_size)

	return new_size
end
M.GetScaledTextSize = GetScaledTextSize

return M
