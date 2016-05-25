--[[]]

local modKey = "Raid Markers"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local MarkerMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

local width = 10
local height = 10
local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

function MarkerMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(MarkerMod, "UpdateActivated")

--############ SIZE ############

function MarkerMod:UpdateWidth(w)
	if type(w) ~= "number" or w<=0 then
		widthOpt:Set(10) --default
	else
		width = w
		self:UpdateAllSize()
	end
end
widthOpt:OnUpdate(MarkerMod, "UpdateWidth")

function MarkerMod:UpdateHeight(h)
	if type(h) ~= "number" or h<1 then
		heightOpt:Set(10) --default
	else
		height = h
		self:UpdateAllSize()
	end
end
heightOpt:OnUpdate(MarkerMod, "UpdateHeight")

function MarkerMod:UpdateAllSize()
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

