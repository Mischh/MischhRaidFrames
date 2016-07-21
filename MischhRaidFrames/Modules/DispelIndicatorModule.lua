--[[]]

local modKey = "Dispel Indicator"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local DispelMod, ModOptions = MRF:newModule(modKey , "misc", true)

local lOpt = MRF:GetOption(ModOptions, "leftOffset")
local tOpt = MRF:GetOption(ModOptions, "topOffset")
local rOpt = MRF:GetOption(ModOptions, "rightOffset")
local bOpt = MRF:GetOption(ModOptions, "bottomOffset")
local l,t,r,b = -2,2,2,-2
lOpt:OnUpdate(DispelMod, "NewLeft")
tOpt:OnUpdate(DispelMod, "NewTop")
rOpt:OnUpdate(DispelMod, "NewRight")
bOpt:OnUpdate(DispelMod, "NewBottom")
function DispelMod:NewLeft(val)
	if not val then
		lOpt:Set(-2)
	else
		l = val; self:UpdateAll()
	end
end
function DispelMod:NewTop(val)
	if not val then
		tOpt:Set(2)
	else
		t = val; self:UpdateAll()
	end
end
function DispelMod:NewRight(val)
	if not val then
		rOpt:Set(2)
	else
		r = val; self:UpdateAll()
	end
end
function DispelMod:NewBottom(val)
	if not val then
		bOpt:Set(-2)
	else
		b = val; self:UpdateAll()
	end
end

local cOpt = MRF:GetOption(ModOptions, "color")
local c = ApolloColor.new("FFA100FE")
cOpt:OnUpdate(DispelMod, "NewColor")
function DispelMod:NewColor(col)
	if not col then
		cOpt:Set("FFA100FE")
	else
		c = ApolloColor.new(col); self:UpdateAll()
	end
end


local actOpt = MRF:GetOption(ModOptions, "activated")
actOpt:OnUpdate(DispelMod, "Activated")
function DispelMod:Activated(isActive)
	if isActive == nil then
		actOpt:Set(true)
	elseif not isActive then
		self:HideAll()
	end
end

local frames = setmetatable({}, {__index = function(tbl, parent) 
	local frame = MRF:LoadForm("Window", parent)
	frame:SetAnchorPoints(0,0,1,1);
	frame:SetAnchorOffsets(l,t,r,b);
	parent:SendChildToBottom(frame)
	
	frame:SetSprite("WhiteFill")
	frame:SetBGColor(c)
	
	rawset(tbl, parent, frame)
	return frame
end})

function DispelMod:HideAll()
	for i,frame in pairs(frames) do
		frame:Show(false)
	end
end
function DispelMod:UpdateAll()
	for i,frame in pairs(frames) do
		frame:SetAnchorOffsets(l,t,r,b)
		frame:SetBGColor(c)
	end
end

function DispelMod:miscUpdate(frame, unit)
	local tDebuffs = unit:GetBuffs() --really dont need another variable to name it tBuffs...
	if tDebuffs then
		tDebuffs = tDebuffs.arHarmful
	
		for _, debuff in pairs(tDebuffs) do
			if debuff.splEffect:GetClass() == Spell.CodeEnumSpellClass.DebuffDispellable then
				return frames[frame.frame]:Show(true)
			end
		end
	end
	frames[frame.frame]:Show(false)
end

function DispelMod:InitMiscSettings(parent)
	local L = MRF:Localize({--English
		["ttOffset"] = [[These Offsets are always from the Edge of each frame. Going positive moves the edges right/bottom.]],
	}, {--German
		["ttMouse"] = [[Diese Abstände sind immer relativ zum jeweiligen Rand. Positive Werte verschieben dabei nach rechts bzw. unten.]],
		["Indicators Color:"] = "Farbe des Indikators:",
		["Offset Left:"] = "Abstand Links:",
		["Offset Right:"] = "Abstand Rechts:",
		["Offset Top:"] = "Abstand Oben:",
		["Offset Bottom:"] = "Abstand Unten:",
	}, {--French
	})

	local rowC = MRF:LoadForm("HalvedRow", parent)
	local rowL = MRF:LoadForm("HalvedRow", parent)
	local rowR = MRF:LoadForm("HalvedRow", parent)
	local rowT = MRF:LoadForm("HalvedRow", parent)
	local rowB = MRF:LoadForm("HalvedRow", parent)
	
	local question = MRF:LoadForm("QuestionMark", rowL:FindChild("Left"))
	question:SetTooltip(L["ttMouse"])
	
	rowC:FindChild("Left"):SetText(L["Indicators Color:"])
	rowL:FindChild("Left"):SetText(L["Offset Left:"])
	rowR:FindChild("Left"):SetText(L["Offset Right:"])
	rowT:FindChild("Left"):SetText(L["Offset Top:"])
	rowB:FindChild("Left"):SetText(L["Offset Bottom:"])
	
	MRF:applyColorbutton(rowC:FindChild("Right"), cOpt)
	MRF:applySlider(rowL:FindChild("Right"), lOpt, -25, 25, 1)
	MRF:applySlider(rowR:FindChild("Right"), rOpt, -25, 25, 1)
	MRF:applySlider(rowT:FindChild("Right"), tOpt, -25, 25, 1)
	MRF:applySlider(rowB:FindChild("Right"), bOpt, -25, 25, 1)
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 5*30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

