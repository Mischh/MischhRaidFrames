--[[]]

local modKey = "Name"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local NameMod, ModOptions = MRF:newModule(modKey , "text", false)

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- TEXT -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --
local patternOpt = MRF:GetOption(ModOptions, "text")
local nametext;

function NameMod:UpdateTextPattern(newPattern)
	if not newPattern then
		patternOpt:Set("%f")
	else
		nametext = newPattern
	end
end
patternOpt:OnUpdate(NameMod, "UpdateTextPattern")


--[[
	%f* = firstName limited to * letters 
	%l* = lastName limited to * letters
	%n* = name limited to * letters
]]--

local t = {} --just a tbl used to help storing the names

local function magic(key, len)
	len = tonumber(len)
		
	local ret = t[key] or key

	if len then
		return ret:sub(1, len)
	end
	return ret;
end

function NameMod:textUpdate(frame, unit)
	t.n = unit:GetName() or "no Name"
	t.f, t.l = t.n:match("(.+)%s(.+)")
	
	--patternmatch the name:
	local val = nametext:gsub("%%(.)(%d?%d?)", magic)
	
	return val
end

function NameMod:InitTextSettings(parent)
	local row = MRF:LoadForm("HalvedRow", parent)
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	
	row:FindChild("Left"):SetText("Pattern:")
	question:SetTooltip([[Within this pattern specific characters will be replaced:
	%f* = firstName limited to * letters 
	%l* = lastName limited to * letters
	%n* = name limited to * letters
	
	* can only use a maximum of 2 numeric letters.
	To get unlimited legths, leave the * empty.]])
	MRF:applyTextbox(row:FindChild("Right"), patternOpt)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

