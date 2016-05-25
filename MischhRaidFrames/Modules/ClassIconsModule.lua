--[[]]

local modKey = "Class Icons"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ClassMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

local width = 10
local height = 10
local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

function ClassMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(ClassMod, "UpdateActivated")

--############ SIZE ############

function ClassMod:UpdateWidth(w)
	if type(w) ~= "number" or w<=0 then
		widthOpt:Set(10) --default
	else
		width = w
		self:UpdateAllSize()
	end
end
widthOpt:OnUpdate(ClassMod, "UpdateWidth")

function ClassMod:UpdateHeight(h)
	if type(h) ~= "number" or h<1 then
		heightOpt:Set(10) --default
	else
		height = h
		self:UpdateAllSize()
	end
end
heightOpt:OnUpdate(ClassMod, "UpdateHeight")

function ClassMod:UpdateAllSize()
	for _, icon in pairs(icons) do
		icon:SetAnchorOffsets(-width, -height, width, height)
	end
end

do
	--apply size on creation of icons.
	local meta = getmetatable(icons)
	local orig = meta.__index
	meta.__index = function(t,k)
		local icon = orig(t,k)
		icon:SetAnchorOffsets(-width, -height, width, height)
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
	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText("Width:")
	hRow:FindChild("Left"):SetText("Height:")
	MRF:applySlider(wRow:FindChild("Right"), widthOpt, 1, 50, 1)
	MRF:applySlider(hRow:FindChild("Right"), heightOpt, 1, 50, 1)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end




