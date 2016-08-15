--[[]]

local modKey = "Role Icons"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local RoleMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

--the 'new' way of sizing icons.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

function RoleMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(RoleMod, "UpdateActivated")

local floor = math.floor
function RoleMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(RoleMod, "UpdateHSize")

function RoleMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(RoleMod, "UpdateVSize")

function RoleMod:UpdateAllSize()
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
	
	RoleMod:UpdateAllSize() --if there are actually some already created.
end

-- ## THE ICONS:

MRF:OnceDocLoaded(function()
	Apollo.LoadSprites("textures/RoleIcons.xml")
end)

local _iconTblRoles = {
	"MRF_DpsIcon",
	"MRF_HealIcon",
	"MRF_TankIcon",
}

local _iconTblFilled = {
	"WhiteFill",
	"WhiteFill",
	"WhiteFill",
}

local iconTbl = setmetatable({}, {__index = _iconTblRoles}) --the table we actually look up.

local fillInstOpt = MRF:GetOption(ModOptions, "fill")
fillInstOpt:OnUpdate(function(fill)
	if fill == nil then
		fillInstOpt:Set(false)
	elseif fill then
		setmetatable(iconTbl, {__index = _iconTblFilled})
	else
		setmetatable(iconTbl, {__index = _iconTblRoles})
	end
end)

local showIconsOpt = MRF:GetOption(ModOptions, "show") -- = {showDps, showHeal, showTank}
MRF:GatherUpdates(showIconsOpt) --make all updates on children get passed up.
showIconsOpt:OnUpdate(function(tbl) 
	if type(tbl) ~= "table" or #tbl < 3 then
		showIconsOpt:Set({true, true, true})
	else
		iconTbl[1] = not tbl[1] and "" or nil
		iconTbl[2] = not tbl[2] and "" or nil
		iconTbl[3] = not tbl[3] and "" or nil
	end
end)

-- ## THE COLORS:

local colorTbl = {
	ApolloColor.new("FFFFFFFF"), --Dps
	ApolloColor.new("FFFFFFFF"), --Heal
	ApolloColor.new("FFFFFFFF"), --Tank
}

local iconColorOpt = MRF:GetOption(ModOptions, "colors") -- = {colorDps, colorHeal, colorTank}
MRF:GatherUpdates(iconColorOpt) --make all updates on children get passed up.
iconColorOpt:OnUpdate(function(tbl) 
	if type(tbl) ~= "table" or #tbl < 3  then
		iconColorOpt:Set({"FFFFFFFF", "FFFFFFFF", "FFFFFFFF"})
	else
		colorTbl[1] = ApolloColor.new(tbl[1])
		colorTbl[2] = ApolloColor.new(tbl[2])
		colorTbl[3] = ApolloColor.new(tbl[3])
	end
end)

function RoleMod:iconUpdate(frame, unit)
	local idx = 1 --dps
	if unit:IsHeal() then idx = 2
	elseif unit:IsTank() then idx = 3 end
	
	
	icons[frame.frame]:SetSprite(iconTbl[idx])
	icons[frame.frame]:SetBGColor(colorTbl[idx])
end


function RoleMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
	}, {--German
		["Width:"] = "Breite:",
		["Height:"] = "Höhe:",
		["Show for dps"] = "Zeige für DDs",
		["Show for heals"] = "Zeige für Heiler",
		["Show for tanks"] = "Zeige für Tanks",
		["Boxes instead of icons"] = "Gefärbte Box, statt Icon",
		["Dps color:"] = "DD-Farbe:",
		["Heal color:"] = "Heiler-Farbe:",
		["Tank color:"] = "Tank-Farbe:",
	}, {--French
	})
	
	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText(L["Width:"])
	hRow:FindChild("Left"):SetText(L["Height:"])
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1, false, false, true) --textbox: positive unlimited
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1, false, false, true)
	
	local dShowRow = MRF:LoadForm("HalvedRow", parent)
	local hShowRow = MRF:LoadForm("HalvedRow", parent)
	local tShowRow = MRF:LoadForm("HalvedRow", parent)
	
	MRF:applyCheckbox(dShowRow:FindChild("Right") , MRF:GetOption(showIconsOpt, 1), L["Show for dps"])
	MRF:applyCheckbox(hShowRow:FindChild("Right") , MRF:GetOption(showIconsOpt, 2), L["Show for heals"])
	MRF:applyCheckbox(tShowRow:FindChild("Right") , MRF:GetOption(showIconsOpt, 3), L["Show for tanks"])
	
	local dIcon = MRF:LoadForm("IconTemplate", dShowRow:FindChild("Left"))
	local hIcon = MRF:LoadForm("IconTemplate", hShowRow:FindChild("Left"))
	local tIcon = MRF:LoadForm("IconTemplate", tShowRow:FindChild("Left"))
	
	dIcon:SetAnchorPoints(0.5, 0 , 0.5, 1); dIcon:SetAnchorOffsets(-15, 0, 15, 0); dIcon:SetSprite("MRF_DpsIcon")
	hIcon:SetAnchorPoints(0.5, 0 , 0.5, 1); hIcon:SetAnchorOffsets(-15, 0, 15, 0); hIcon:SetSprite("MRF_HealIcon")
	tIcon:SetAnchorPoints(0.5, 0 , 0.5, 1); tIcon:SetAnchorOffsets(-15, 0, 15, 0); tIcon:SetSprite("MRF_TankIcon")
	
	iconColorOpt:OnUpdate(function(tbl)
		if type(tbl) == "table" and #tbl == 3 then
			dIcon:SetBGColor(ApolloColor.new(tbl[1]))
			hIcon:SetBGColor(ApolloColor.new(tbl[2]))
			tIcon:SetBGColor(ApolloColor.new(tbl[3]))
		end
	end)
	
	local fillRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(fillRow:FindChild("Right"), fillInstOpt, L["Boxes instead of icons"])
	
	local dColRow = MRF:LoadForm("HalvedRow", parent)
	local hColRow = MRF:LoadForm("HalvedRow", parent)
	local tColRow = MRF:LoadForm("HalvedRow", parent)
	
	dColRow:FindChild("Left"):SetText(L["Dps color:"])
	hColRow:FindChild("Left"):SetText(L["Heal color:"])
	tColRow:FindChild("Left"):SetText(L["Tank color:"])
	
	MRF:applyColorbutton(dColRow:FindChild("Right"), MRF:GetOption(iconColorOpt, 1))
	MRF:applyColorbutton(hColRow:FindChild("Right"), MRF:GetOption(iconColorOpt, 2))
	MRF:applyColorbutton(tColRow:FindChild("Right"), MRF:GetOption(iconColorOpt, 3))

	local anchor = {parent:GetAnchorOffsets()}
	local children = parent:GetChildren()
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

