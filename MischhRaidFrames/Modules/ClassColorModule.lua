--[[
--]]

local modKey = "Class Colors"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ClassCMod, ModuleOptions = MRF:newModule(modKey , "color", false)

local ref = nil; --saves the reference to the classcolor-Object.
local classes = { --Defaults - these will change, when InitModule is called.
	[0] = ApolloColor.new("FFFFFFFF"), --White, this will stay.
	[GameLib.CodeEnumClass.Warrior] = ApolloColor.new("FFF54F4F"),		
	[GameLib.CodeEnumClass.Engineer] = ApolloColor.new("FFFFC830"),
	[GameLib.CodeEnumClass.Esper] = ApolloColor.new("FF1591DB"),
	[GameLib.CodeEnumClass.Medic] = ApolloColor.new("FF00D030"),
	[GameLib.CodeEnumClass.Stalker] = ApolloColor.new("FFD23EF4"),
	[GameLib.CodeEnumClass.Spellslinger] = ApolloColor.new("FFF47E2F"),
};

local classIds = {	
	GameLib.CodeEnumClass.Warrior,
	GameLib.CodeEnumClass.Engineer,
	GameLib.CodeEnumClass.Esper,
	GameLib.CodeEnumClass.Medic,
	GameLib.CodeEnumClass.Stalker,
	GameLib.CodeEnumClass.Spellslinger,
}

local defaultColors = {
	[GameLib.CodeEnumClass.Warrior] = "FFF54F4F",		
	[GameLib.CodeEnumClass.Engineer] = "FFFFC830",
	[GameLib.CodeEnumClass.Esper] = "FF1591DB",
	[GameLib.CodeEnumClass.Medic] = "FF00D030",
	[GameLib.CodeEnumClass.Stalker] = "FFD23EF4",
	[GameLib.CodeEnumClass.Spellslinger] = "FFF47E2F",
}

local function getColor(_, unit)
	enum = unit:GetClassId()
	return classes[enum or 0];
end



local refOpt = MRF:GetOption(ModuleOptions, "ref")
refOpt:OnUpdate(function(newRef)
	if not newRef then
		refOpt:Set({}) --will call this function again.
	else
		ref = newRef
		ref.Get = getColor
		ref.frequent = false
		ref.name = "Class Color"
	end
end)


local classOpt = {}
for _, cId in ipairs(classIds) do
	classOpt[cId] = MRF:GetOption(ModuleOptions, cId)
	classOpt[cId]:OnUpdate(function(newColor)
		if not newColor then
			classOpt[cId]:Set(defaultColors[cId])
		else
			classes[cId] = ApolloColor.new(newColor)
		end
	end)
end

function ClassCMod:GetColorTable()
	return {ref or {Get = getColor, frequent = false, name = "Class Color"}};
end

function ClassCMod:InitColorSettings(parent)	
	local rowWarr = MRF:LoadForm("HalvedRow", parent)
	local rowEngi = MRF:LoadForm("HalvedRow", parent)
	local rowEspe = MRF:LoadForm("HalvedRow", parent)
	local rowMedi = MRF:LoadForm("HalvedRow", parent)
	local rowStal = MRF:LoadForm("HalvedRow", parent)
	local rowSpel = MRF:LoadForm("HalvedRow", parent)
	
	
	rowWarr:FindChild("Left"):SetText("Warrior:")
	rowEngi:FindChild("Left"):SetText("Engineer:")
	rowEspe:FindChild("Left"):SetText("Esper:")
	rowMedi:FindChild("Left"):SetText("Medic:")
	rowStal:FindChild("Left"):SetText("Stalker:")
	rowSpel:FindChild("Left"):SetText("Spellslinger:")
	
	MRF:applyColorbutton(rowWarr:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Warrior])
	MRF:applyColorbutton(rowEngi:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Engineer])
	MRF:applyColorbutton(rowEspe:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Esper])
	MRF:applyColorbutton(rowMedi:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Medic])
	MRF:applyColorbutton(rowStal:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Stalker])
	MRF:applyColorbutton(rowSpel:FindChild("Right"), classOpt[GameLib.CodeEnumClass.Spellslinger])
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 6*30 --we want to display six 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

