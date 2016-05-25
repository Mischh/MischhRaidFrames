--[[]]

local modKey = "Shield"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ShieldMod, ModuleOptions = MRF:newModule(modKey , "bar", true, "text", true)

local floor = math.floor

local shieldText;

local textOption = MRF:GetOption(ModuleOptions, "text")

function ShieldMod:TextOptionChanged(text)
	if not text then
		textOption:Set("%p%%")
	else
		shieldText = text
	end
end
textOption:OnUpdate(ShieldMod, "TextOptionChanged")

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- BAR -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

function ShieldMod:progressUpdate(frame, unit)
	local max = unit:GetShieldCapacityMax()
	local cur = unit:GetShieldCapacity()
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end

	local val = cur/max
	
	--frame:SetVar("progress", modKey, val)
	return val
end


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- TEXT -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

local function shorten(num)	--stolen from ForgeUI
	local tmp = tostring(num)
    if not num then
        return "0"
    elseif num >= 1000000 then
        tmp = string.sub(tmp, 1, string.len(tmp) - 6) .. "." .. string.sub(tmp, string.len(tmp) - 5, string.len(tmp) - 5) .. "M"
    elseif num >= 1000 then
        tmp = string.sub(tmp, 1, string.len(tmp) - 3) .. "." .. string.sub(tmp, string.len(tmp) - 2, string.len(tmp) - 2) .. "k"    
	else
        tmp = num -- hundreds
    end
    return tmp
end

--[[
	%c = current; %C = current Max
	%s = short; %S = short Max
	%m = missing;
	%n = short missing;
	%p = percent (floored 0-100)
]]--

local tShield = setmetatable({ --makes the text pattern easier & faster
	--[[c and C are supposed to be given]]
	_s = function(tbl) return shorten(tbl.c); end, -- if you want to add a %x , just add a function _x to this table.
	_S = function(tbl) return shorten(tbl.C); end,
	_m = function(tbl) return tbl.C - tbl.c; end,
	_n = function(tbl) return shorten(tbl.m); end,
	_p = function(tbl) return floor(100* tbl.c / tbl.C); end,
} , { __index = function(tbl, key)
	--[[key = c C s S m n, while c&C will be set (and never get called) ]]
	local f = rawget(tbl, "_"..key) -- see functions above. 
	if f then
		return f(tbl)
	else
		rawset(tbl, key, key) --invalid stuff will stay invalid - just save this funcs return.
		return key;-- if ppl do invalid stuff, the key will be returned (this will make %% work aswell)
	end
end})

function ShieldMod:textUpdate(frame, unit)
	local max = unit:GetShieldCapacityMax()
	local cur = unit:GetShieldCapacity()
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end
	
	tShield["C"] = max
	tShield["c"] = cur
		
	local val = shieldText:gsub("%%(.)", tShield) --replace any %* with the requested value.
	
	return val
end

function ShieldMod:InitTextSettings(parent)
	local row = MRF:LoadForm("HalvedRow", parent)
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	
	row:FindChild("Left"):SetText("Pattern:")
	question:SetTooltip([[Within this pattern specific characters will be replaced:
	%c = current value 
	%C = current maximum
	%s = shortened value 
	%S = shortened maximum
	%m = missing till maximum
	%n = shortened missing
	%p = percent (floored 0-100)]]) --i know this doesnt look like a String in houston, but it is. Love this Editor...	
	MRF:applyTextbox(row:FindChild("Right"), textOption)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end


