--[[]]

local modKey = "Lead Marker"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local LeadMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icon_lead = "Crafting_CircuitSprites:sprCircuit_Laser_Vertical_Red"
local icon_inv = "Crafting_CircuitSprites:sprCircuit_Laser_Vertical_Blue"
local color_white = ApolloColor.new("FFFFFFFF")
local color_lead = ApolloColor.new("FFFFFFFF")
local color_inv = ApolloColor.new("FFFFFFFF")
local fillInstead = false

local icons = MRF:GetModIcons(modKey)
local state = {} --[frame] = true/false/nil for Lead/canMark/none

local activeOption = MRF:GetOption(ModOptions, "activated")

local width = 3
local height = 15
local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")
local colLeadOpt = MRF:GetOption(ModOptions, "leadColor")
local colInvOpt = MRF:GetOption(ModOptions, "invColor")
local fillOpt = MRF:GetOption(ModOptions, "fill")

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

function LeadMod:UpdateColLead(newVal)
	if not newVal then
		colLeadOpt:Set("FFEA0000");
	else
		color_lead = ApolloColor.new(newVal)
		self:UpdateAllIcon()
	end
end
colLeadOpt:OnUpdate(LeadMod, "UpdateColLead")

function LeadMod:UpdateColInv(newVal)
	if not newVal then
		colInvOpt:Set("FF41B8FF");
	else
		color_inv = ApolloColor.new(newVal)
		self:UpdateAllIcon()
	end
end
colInvOpt:OnUpdate(LeadMod, "UpdateColInv")

function LeadMod:UpdateFill(newVal)
	if type(newVal) ~= "boolean" then
		fillOpt:Set(false)
	else
		fillInstead = newVal
		LeadMod.iconUpdate = newVal and LeadMod.iconUpdate_fill or LeadMod.iconUpdate_icon
		self:UpdateAllIcon()
	end
end
fillOpt:OnUpdate(LeadMod, "UpdateFill")

function LeadMod:UpdateAllIcon()
	for frame, icon in pairs(icons) do
		if state[frame] == true then
			icon:SetSprite(fillInstead and "WhiteFill" or icon_lead)
			icon:SetBGColor(fillInstead and color_lead or color_white)
		elseif state[frame] == false then
			icon:SetSprite(fillInstead and "WhiteFill" or icon_inv)
			icon:SetBGColor(fillInstead and color_inv or color_white)
		end
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

--[[]]

function LeadMod:iconUpdate_icon(frame, unit)
	if unit:IsLeader() then
		icons[frame.frame]:SetSprite(icon_lead)
		state[frame.frame] = true
	elseif unit:CanInvite() then
		icons[frame.frame]:SetSprite(icon_inv)
		state[frame.frame] = false
	else
		icons[frame.frame]:SetSprite("")
		state[frame.frame] = nil
	end
end

function LeadMod:iconUpdate_fill(frame, unit)
	if unit:IsLeader() then
		icons[frame.frame]:SetSprite("WhiteFill")
		icons[frame.frame]:SetBGColor(color_lead)
		state[frame.frame] = true
	elseif unit:CanInvite() then
		icons[frame.frame]:SetSprite("WhiteFill")
		icons[frame.frame]:SetBGColor(color_mark)
		state[frame.frame] = false
	else
		icons[frame.frame]:SetSprite("")
		icons[frame.frame]:SetBGColor(color_white)
		state[frame.frame] = nil
	end
end

LeadMod.iconUpdate = LeadMod.iconUpdate_icon


function LeadMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["Width:"] = "Width:",
		["Height:"] = "Height:",
	}, {--German
		["Width:"] = "Breite:",
		["Height:"] = "Höhe:",
		["Fill the Icon instead with a Color"] = "Stattdessen mit Farbe füllen",
		["Color for the Lead:"] = "Farbe für Gruppenleiter:",
		["Color for Inviters:"] = "Farbe für Einladeberechtigte:",
	}, {--French
	})

	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText(L["Width:"])
	hRow:FindChild("Left"):SetText(L["Height:"])
	MRF:applySlider(wRow:FindChild("Right"), widthOpt, 1, 50, 1)
	MRF:applySlider(hRow:FindChild("Right"), heightOpt, 1, 50, 1)

	local fillRow = MRF:LoadForm("HalvedRow", parent)
	local leadRow = MRF:LoadForm("HalvedRow", parent)
	local invRow = MRF:LoadForm("HalvedRow", parent)
	
	MRF:applyCheckbox(fillRow:FindChild("Left"),fillOpt, L["Fill the Icon instead with a Color"])
	leadRow:FindChild("Left"):SetText(L["Color for the Lead:"])
	invRow:FindChild("Left"):SetText(L["Color for Inviters:"])
	MRF:applyColorbutton(leadRow:FindChild("Right"), colLeadOpt)
	MRF:applyColorbutton(invRow:FindChild("Right"), colInvOpt)
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 5*30 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

