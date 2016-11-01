--[[]]
local modKey = "Paths"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local PathMod, ModOptions = MRF:newModule(modKey , "icon", false, "color", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated") --activation of icon.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

function PathMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(PathMod, "UpdateActivated")

--############ SIZE ############
local floor = math.floor
function PathMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(PathMod, "UpdateHSize")

function PathMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(PathMod, "UpdateVSize")

function PathMod:UpdateAllSize()
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
	
	PathMod:UpdateAllSize() --if there are actually some already created.
end

--############ ICON ############

local pathIcons = {
	[PlayerPathLib.PlayerPathType_Soldier] 		= "Icon_Windows_UI_CRB_Soldier",
	[PlayerPathLib.PlayerPathType_Settler] 		= "Icon_Windows_UI_CRB_Colonist",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "Icon_Windows_UI_CRB_Scientist",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "Icon_Windows_UI_CRB_Explorer",
}
--[[]]

function PathMod:iconUpdate(frame, unit)
	local t = unit:GetPlayerPathType()
	if t then
		icons[frame.frame]:SetSprite(pathIcons[t])
	else
		icons[frame.frame]:SetSprite("")
	end
end


function PathMod:InitIconSettings(parent)
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
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1, false, false, true) --textbox: positive unlimited
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1, false, false, true)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end


--############ COLOR ############

local ref, refOpt = nil, MRF:GetOption(ModOptions, "colorReference")
local colTblOpt = MRF:GetOption(ModOptions, "colorTable")

local paths = {
	Soldier = PlayerPathLib.PlayerPathType_Soldier,
	Settler = PlayerPathLib.PlayerPathType_Settler,
	Scientist = PlayerPathLib.PlayerPathType_Scientist,
	Explorer = PlayerPathLib.PlayerPathType_Explorer,
}

local defaults = {
	[false] = "FFFFFFFF",
	[PlayerPathLib.PlayerPathType_Soldier] 		= "FFFFFFFF",
	[PlayerPathLib.PlayerPathType_Settler] 		= "FFFFFFFF",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "FFFFFFFF",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "FFFFFFFF",
}

local colTbl = {
	[false] = ApolloColor.new("FFFFFFFF"),
	[PlayerPathLib.PlayerPathType_Soldier] 		= ApolloColor.new("FFFFFFFF"),
	[PlayerPathLib.PlayerPathType_Settler] 		= ApolloColor.new("FFFFFFFF"),
	[PlayerPathLib.PlayerPathType_Scientist] 	= ApolloColor.new("FFFFFFFF"),
	[PlayerPathLib.PlayerPathType_Explorer] 	= ApolloColor.new("FFFFFFFF"),
}

local getColor = function(_, unit)
	local t = unit:GetPlayerPathType()
	return colTbl[t or false]
end

function PathMod:GetColorTable()
	return {ref or {Get = getColor, frequent = false, name = "Path"}};
end

refOpt:OnUpdate(function(newRef)
	if not newRef then
		refOpt:Set({}) --will call this function again.
	else
		ref = newRef
		ref.Get = getColor
		ref.frequent = false
		ref.name = "Path"
	end
end)

for name, i in pairs(paths) do
	local opt = MRF:GetOption(colTblOpt, i)
	opt:OnUpdate(function(colStr)
		if not colStr then
			opt:Set(defaults[i])
		else
			colTbl[i] = ApolloColor.new(colStr)
		end
	end)
end
do
	local i = false
	local opt = MRF:GetOption(colTblOpt, i)
	opt:OnUpdate(function(colStr)
		if not colStr then
			opt:Set(defaults[i])
		else
			colTbl[i] = ApolloColor.new(colStr)
		end
	end)
end

function PathMod:InitColorSettings(parent)
	local L = MRF:Localize({--English
	}, {--German
		["No Path:"] = "Ohne Pfad:",
	}, {--French
	})
	
	local pathIcons = {
		[PlayerPathLib.PlayerPathType_Soldier] 		= "Icon_Windows_UI_CRB_Soldier",
		[PlayerPathLib.PlayerPathType_Settler] 		= "Icon_Windows_UI_CRB_Colonist",
		[PlayerPathLib.PlayerPathType_Scientist] 	= "Icon_Windows_UI_CRB_Scientist",
		[PlayerPathLib.PlayerPathType_Explorer] 	= "Icon_Windows_UI_CRB_Explorer",
	}
	
	local rowDef = MRF:LoadForm("HalvedRow", parent)
	rowDef:FindChild("Left"):SetText(L["No Path:"])
	MRF:applyColorbutton(rowDef:FindChild("Right"), MRF:GetOption(colTblOpt, false))
	
	for name, i in pairs(paths) do
		local row = MRF:LoadForm("HalvedRow", parent)
		local icon = MRF:LoadForm("IconTemplate", row:FindChild("Left"))
		icon:SetAnchorPoints(0.5, 0 , 0.5, 1)
		icon:SetAnchorOffsets(-15, 0, 15, 0)
		icon:SetSprite(pathIcons[i])
		MRF:applyColorbutton(row:FindChild("Right"), MRF:GetOption(colTblOpt, i))
	end
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 5*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
