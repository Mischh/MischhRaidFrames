--[[]]

local MRF = Apollo.GetAddon("MischhRaidFrames")

local ClampCeilMod, ModOptions = MRF:newModule("Health Clamp Ceil" , "bar", true)
local ClampFloorMod, ModOptions = MRF:newModule("Health Clamp Floor" , "bar", true)

local floor = math.floor

local pattern;

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- BAR -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

function ClampCeilMod:progressUpdate(frame, unit)
	local max = unit:GetMaxHealth()
	local cur = unit:GetHealthCeiling() or max --this ceiling is not supported by GroupLibs GroupMember.
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end

	local val = cur/max
	
	return val
end

function ClampFloorMod:progressUpdate(frame, unit)
	local max = unit:GetMaxHealth()
	local cur = unit:GetHealthFloor() or 0
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end

	local val = cur/max
	
	return val
end