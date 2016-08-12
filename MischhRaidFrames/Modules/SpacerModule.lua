--[[]]

local modKey = "Spacer"
local MRF = Apollo.GetAddon("MischhRaidFrames")
--lol, a bar that only updates on unit updates, never thought this would happen.
local SpacerMod, ModOptions = MRF:newModule(modKey , "bar", false)

local progress = 0
local progressOpt = MRF:GetOption(ModOptions, "p")
progressOpt:OnUpdate(SpacerMod, "ProgressUpdate")
function SpacerMod:ProgressUpdate(p)
	if type(p) ~= "number" or p<0 or p>1 then
		progressOpt:Set(0)
	else
		progress = p
	end
end

function SpacerMod:progressUpdate(frame, unit)
	return progress
end

function SpacerMod:InitBarSettings(parent)
	local L = MRF:Localize({--English
		["ttProgres"] = "You can choose which progress this bar will display."
	}, {--German
		["ttProgres"] = "Hier kann gewählt werden, wie weit diese Bar gefüllt sein wird.",
		["The bars progress:"] = "Gefüllt, bis:",
	}, {--French
	})

	local proRow = MRF:LoadForm("HalvedRow", parent)
	proRow:FindChild("Left"):SetText(L["The bars progress:"])
	MRF:applySlider(proRow:FindChild("Right"), progressOpt, 0, 1, 0.1, true) --textbox: ignore steps
	MRF:LoadForm("QuestionMark", proRow:FindChild("Left")):SetTooltip(L["ttProgres"])
	
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end