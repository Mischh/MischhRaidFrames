--[[]]

local modKey = "Readycheck"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ReadyMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)

local activeOption = MRF:GetOption(ModOptions, "activated")

local widthOpt = MRF:GetOption(ModOptions, "width")
local heightOpt = MRF:GetOption(ModOptions, "height")

--the 'new' way of sizing icons.
local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

local timer = nil
local interval = 20
local intervalOpt = MRF:GetOption(ModOptions, "interval")

local tick = "Crafting_CoordSprites:sprCoord_Checkmark"
local cross = "ClientSprites:LootCloseBox_Holo"

function ReadyMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(ReadyMod, "UpdateActivated")

MRF:OnceDocLoaded(function()
	Apollo.RegisterEventHandler("Group_ReadyCheck", "OnReadyCheck", ReadyMod)
	timer = ApolloTimer.Create(interval, false, "TimerExceeded", ReadyMod)
	timer:Stop()
end)

--############ SIZE ############

function ReadyMod:UpdateWidth(w)
	if type(w) == "number" and w>0 then
		hSizeOpt:Set(2*w)
		widthOpt:Set(nil)
	end
end
widthOpt:OnUpdate(ReadyMod, "UpdateWidth")

function ReadyMod:UpdateHeight(h)
	if type(h) == "number" and h>0 then
		vSizeOpt:Set(2*h)
		heightOpt:Set(nil)
	end
end
heightOpt:OnUpdate(ReadyMod, "UpdateHeight")

local floor = math.floor
function ReadyMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAllSize()
	end
end
hSizeOpt:OnUpdate(ReadyMod, "UpdateHSize")

function ReadyMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAllSize()
	end
end
vSizeOpt:OnUpdate(ReadyMod, "UpdateVSize")

function ReadyMod:UpdateAllSize()
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
	
	ReadyMod:UpdateAllSize() --if there are actually some already created.
end

--### Timer + Updates ###

function ReadyMod:UpdateInterval(int)
	if type(int) ~= "number" or int<1 then
		intervalOpt:Set(20) --default
	else
		interval = int
	end
end
intervalOpt:OnUpdate(ReadyMod, "UpdateInterval")

do
	local show = false
	
	function ReadyMod:OnReadyCheck()
		show = true
		timer:Stop()
		timer:Set(interval, false, "TimerExceeded", self)
		timer:Start()
	end
	
	function ReadyMod:TimerExceeded()
		show = false
		self:RemoveAllIcons()
	end
	
	function ReadyMod:iconUpdate(frame, unit)
		local set = unit:HasSetReady()
		local ready = unit:IsReady()
		
		if set and show then
			if ready then
				icons[frame.frame]:SetSprite(tick)
			else
				icons[frame.frame]:SetSprite(cross)
			end	
		else
			icons[frame.frame]:SetSprite("")
		end
	end
	
	function ReadyMod:RemoveAllIcons()
		for _, icon in pairs(icons) do
			icon:SetSprite("")
		end
	end
end

function ReadyMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["Width:"] = "Width:",
		["Height:"] = "Height:",
	}, {--German
		["Width:"] = "Breite:",
		["Height:"] = "Höhe:",
		["Duration to be shown:"] = "Angezeigte Zeitspanne:",
	}, {--French
	})

	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	local tRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText(L["Width:"])
	hRow:FindChild("Left"):SetText(L["Height:"])
	tRow:FindChild("Left"):SetText(L["Duration to be shown:"])
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1)
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1)
	MRF:applySlider(tRow:FindChild("Right"), intervalOpt, 1, 60, 1)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 3*30 --we want to display three 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end