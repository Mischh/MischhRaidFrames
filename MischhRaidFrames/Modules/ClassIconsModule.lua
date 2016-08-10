--[[]]

local modKey = "Class Icons"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ClassMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

--the 'new' way of sizing icons.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

function ClassMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(ClassMod, "UpdateActivated")

--############ SIZE ############
function ClassMod:UpdateWidth(w)
	if type(w) == "number" and w>0 then
		hSizeOpt:Set(2*w)
		widthOpt:Set(nil)
	end
end
widthOpt:OnUpdate(ClassMod, "UpdateWidth")

function ClassMod:UpdateHeight(h)
	if type(h) == "number" and h>0 then
		vSizeOpt:Set(2*h)
		heightOpt:Set(nil)
	end
end
heightOpt:OnUpdate(ClassMod, "UpdateHeight")

local floor = math.floor
function ClassMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(ClassMod, "UpdateHSize")

function ClassMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(ClassMod, "UpdateVSize")

function ClassMod:UpdateAllSize()
	for _, icon in pairs(icons) do
		icon:SetAnchorOffsets(lOff, tOff, rOff, bOff)
	end
end

do
	--apply size on creation of icons.
	local meta = getmetatable(icons)
	local orig = meta.__index
	meta.__index = function(t,k)
		local icon = orig(t,k)
		icon:SetAnchorOffsets(lOff, tOff, rOff, bOff)
		return icon
	end
	setmetatable(icons, meta)
	
	ClassMod:UpdateAllSize() --if there are actually some already created.
end

--############ ICON ############

local classIcons = {
	[GameLib.CodeEnumClass.Warrior] = "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	[GameLib.CodeEnumClass.Engineer] = "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	[GameLib.CodeEnumClass.Esper] = "BK3:UI_Icon_CharacterCreate_Class_Esper",
	[GameLib.CodeEnumClass.Medic] = "BK3:UI_Icon_CharacterCreate_Class_Medic",
	[GameLib.CodeEnumClass.Stalker] = "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	[GameLib.CodeEnumClass.Spellslinger] = "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}
--[[]]

function ClassMod:iconUpdate(frame, unit)
	local c = unit:GetClassId()
	if c then
		icons[frame.frame]:SetSprite(classIcons[c])
	else
		icons[frame.frame]:SetSprite("")
	end
end

function ClassMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["Width:"] = "Width:",
		["Height:"] = "Height:",
	}, {--German
		["Width:"] = "Breite:",
		["Height:"] = "Höhe:",
	}, {--French
	})

	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText(L["Width:"])
	hRow:FindChild("Left"):SetText(L["Height:"])
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1, false, false, true) --textbox: pos no limit
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1, false, false, true)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end




