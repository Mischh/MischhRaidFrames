--[[]]

local modKey = "Lead Marker"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local LeadMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

local width = 3
local height = 15
local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

function LeadMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(LeadMod, "UpdateActivated")

--############ SIZE ############

function LeadMod:UpdateWidth(w)
	if type(w) ~= "number" or w<=0 then
		widthOpt:Set(3) --default
	else
		width = w
		self:UpdateAllSize()
	end
end
widthOpt:OnUpdate(LeadMod, "UpdateWidth")

function LeadMod:UpdateHeight(h)
	if type(h) ~= "number" or h<1 then
		heightOpt:Set(15) --default
	else
		height = h
		self:UpdateAllSize()
	end
end
heightOpt:OnUpdate(LeadMod, "UpdateHeight")

function LeadMod:UpdateAllSize()
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
	
	LeadMod:UpdateAllSize() --if there are actually some already created.
end

--############ ICON ############

local icon_lead = "Crafting_CircuitSprites:sprCircuit_Laser_Vertical_Red"
local icon_inv = "Crafting_CircuitSprites:sprCircuit_Laser_Vertical_Blue"


--[[]]

function LeadMod:iconUpdate(frame, unit)
	if unit:IsLeader() then
		icons[frame.frame]:SetSprite(icon_lead)
	elseif unit:CanInvite() then
		icons[frame.frame]:SetSprite(icon_inv)
	else
		icons[frame.frame]:SetSprite("")
	end
end


function LeadMod:InitIconSettings(parent)
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

