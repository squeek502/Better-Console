local _M = {}
local Pred = _M

Pred.IsDST = (function()
    local is_dst
    return function()
        if is_dst == nil then
            is_dst = _G.kleifileexists("scripts/networking.lua") and true or false
        end
        return is_dst
    end 
end)()

return _M
