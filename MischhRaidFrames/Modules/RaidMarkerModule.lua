--[[]]

local modKey = "Raid Markers"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local MarkerMod, ModOptions = MRF:newModule(modKey , "icon", false, "color", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated") --activation of icon.

local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

--the 'new' way of sizing icons.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

function MarkerMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(MarkerMod, "UpdateActivated")

--############ SIZE ############
function MarkerMod:UpdateWidth(w)
	if type(w) == "number" and w>0 then
		hSizeOpt:Set(2*w)
		widthOpt:Set(nil)
	end
end
widthOpt:OnUpdate(MarkerMod, "UpdateWidth")

function MarkerMod:UpdateHeight(h)
	if type(h) == "number" and h>0 then
		vSizeOpt:Set(2*h)
		heightOpt:Set(nil)
	end
end
heightOpt:OnUpdate(MarkerMod, "UpdateHeight")

local floor = math.floor
function MarkerMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(MarkerMod, "UpdateHSize")

function MarkerMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(MarkerMod, "UpdateVSize")

function MarkerMod:UpdateAllSize()
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
	
	MarkerMod:UpdateAllSize() --if there are actually some already created.
end

--############ ICON ############

local markers =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
}
--[[]]

function MarkerMod:iconUpdate(frame, unit)
	local t = unit:GetTargetMarker()
	if t then
		icons[frame.frame]:SetSprite(markers[t])
	else
		icons[frame.frame]:SetSprite("")
	end
end


function MarkerMod:InitIconSettings(parent)
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

local defaults = {
	[0] = "FFFFFFFF",
	"FFCC0003",				-- "Icon_Windows_UI_CRB_Marker_Bomb",
	"FF00E5FF",				-- "Icon_Windows_UI_CRB_Marker_Ghost",
	"FF14C800",				-- "Icon_Windows_UI_CRB_Marker_Mask",
	"FF6600FF",				-- "Icon_Windows_UI_CRB_Marker_Octopus",
	"FFFF86E1",				-- "Icon_Windows_UI_CRB_Marker_Pig",
	"FFFFFF00",				-- "Icon_Windows_UI_CRB_Marker_Chicken",
	"FF999999",				-- "Icon_Windows_UI_CRB_Marker_Toaster",
	"FF0017E8",				-- "Icon_Windows_UI_CRB_Marker_UFO",
}

local colTbl = {
	[0] = ApolloColor.new("FFFFFFFF"),
	ApolloColor.new("FFCC0003"),				-- "Icon_Windows_UI_CRB_Marker_Bomb",
	ApolloColor.new("FF00E5FF"),				-- "Icon_Windows_UI_CRB_Marker_Ghost",
	ApolloColor.new("FF14C800"),				-- "Icon_Windows_UI_CRB_Marker_Mask",
	ApolloColor.new("FF6600FF"),				-- "Icon_Windows_UI_CRB_Marker_Octopus",
	ApolloColor.new("FFFF86E1"),				-- "Icon_Windows_UI_CRB_Marker_Pig",
	ApolloColor.new("FFFFFF00"),				-- "Icon_Windows_UI_CRB_Marker_Chicken",
	ApolloColor.new("FF999999"),				-- "Icon_Windows_UI_CRB_Marker_Toaster",
	ApolloColor.new("FF0017E8"),				-- "Icon_Windows_UI_CRB_Marker_UFO",
}

local getColor = function(_, unit)
	local t = unit:GetTargetMarker()
	return colTbl[t or 0]
end

function MarkerMod:GetColorTable()
	return {ref or {Get = getColor, frequent = false, name = "Raid Marker"}};
end

refOpt:OnUpdate(function(newRef)
	if not newRef then
		refOpt:Set({}) --will call this function again.
	else
		ref = newRef
		ref.Get = getColor
		ref.frequent = false
		ref.name = "Raid Marker"
	end
end)

for i=0,8,1 do
	local opt = MRF:GetOption(colTblOpt, i)
	opt:OnUpdate(function(colStr)
		if not colStr then
			opt:Set(defaults[i])
		else
			colTbl[i] = ApolloColor.new(colStr)
		end
	end)
end

function MarkerMod:InitColorSettings(parent)
	local L = MRF:Localize({--English
	}, {--German
		["Not marked:"] = "Nicht markiert:",
	}, {--French
	})
	
	local icons = {
		"Icon_Windows_UI_CRB_Marker_Bomb",
		"Icon_Windows_UI_CRB_Marker_Ghost",
		"Icon_Windows_UI_CRB_Marker_Mask",
		"Icon_Windows_UI_CRB_Marker_Octopus",
		"Icon_Windows_UI_CRB_Marker_Pig",
		"Icon_Windows_UI_CRB_Marker_Chicken",
		"Icon_Windows_UI_CRB_Marker_Toaster",
		"Icon_Windows_UI_CRB_Marker_UFO",
	}
	
	local rowDef = MRF:LoadForm("HalvedRow", parent)
	rowDef:FindChild("Left"):SetText(L["Not marked:"])
	MRF:applyColorbutton(rowDef:FindChild("Right"), MRF:GetOption(colTblOpt, 0))
	
	for i = 1, 8, 1 do
		local row = MRF:LoadForm("HalvedRow", parent)
		local icon = MRF:LoadForm("IconTemplate", row:FindChild("Left"))
		icon:SetAnchorPoints(0.5, 0 , 0.5, 1)
		icon:SetAnchorOffsets(-15, 0, 15, 0)
		icon:SetSprite(icons[i])
		MRF:applyColorbutton(row:FindChild("Right"), MRF:GetOption(colTblOpt, i))
	end
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 9*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
