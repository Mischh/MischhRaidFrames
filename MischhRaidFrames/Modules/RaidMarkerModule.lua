--[[]]

local modKey = "Raid Markers"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local MarkerMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

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
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1)
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

