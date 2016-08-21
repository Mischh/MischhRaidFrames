--[[]]

local modKey = "Disconnect Icon"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local DCMod, ModOptions = MRF:newModule(modKey , "icon", false) --wildstar throws a group-update for online/offline

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

--the 'new' way of sizing icons.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

function DCMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(DCMod, "UpdateActivated")

local floor = math.floor
function DCMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(30)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(DCMod, "UpdateHSize")

function DCMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(30)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(DCMod, "UpdateVSize")

function DCMod:UpdateAllSize()
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
	
	DCMod:UpdateAllSize() --if there are actually some already created.
end

--############ ICON ############
MRF:OnceDocLoaded(function() 
	Apollo.LoadSprites("textures/DCIcon.xml")
end)


function DCMod:iconUpdate(frame, unit)
	if unit:IsDisconnected() or not unit:IsOnline() then
		icons[frame.frame]:SetSprite("DCIcon:DisconnectIcon")
	else
		icons[frame.frame]:SetSprite("")
	end
end

function DCMod:InitIconSettings(parent)
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




