--[[]]
local floor, ceil = math.floor, math.ceil

local modKey = "Consumables"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ConsMod, ModOptions = MRF:newModule(modKey , "icon", true)

local icons = MRF:GetModIcons(modKey)
local iconTables = {}

local activeOption = MRF:GetOption(ModOptions, "activated")

local size = 10
local sizeOpt = MRF:GetOption(ModOptions, "size")

local space = 1
local spaceOpt = MRF:GetOption(ModOptions, "space")

local boxed = true
local boxedOpt = MRF:GetOption(ModOptions, "boxed")

local sorting = {"Fire", "Speed", "Food", "Boost"}
local sortingOpt = MRF:GetOption(ModOptions, "sorting")
MRF:GatherUpdates(sortingOpt)

function ConsMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	end
end
activeOption:OnUpdate(ConsMod, "UpdateActivated")

function ConsMod:UpdateSize(s)
	if type(s) ~= "number" or s<1 then
		sizeOpt:Set(10) --default
	else
		size = s
		self:RelocateAll()
	end
end
sizeOpt:OnUpdate(ConsMod, "UpdateSize")

function ConsMod:UpdateSpace(s)
	if type(s) ~= "number" then
		spaceOpt:Set(1) --default
	else
		space = s
		self:RelocateAll()
	end
end
spaceOpt:OnUpdate(ConsMod, "UpdateSpace")

function ConsMod:UpdateBoxed(b)
	if b == nil then
		boxedOpt:Set(true) --default
	else
		boxed = b
		self:RelocateAll()
	end
end
boxedOpt:OnUpdate(ConsMod, "UpdateBoxed")

function ConsMod:UpdateSorting(sort)
	if type(sort) ~= "table" or #sort<4 then
		sortingOpt:Set({"Fire", "Speed", "Food", "Boost"})
	else
		sorting = sort
		self:RelocateAll()
	end
end
sortingOpt:OnUpdate(ConsMod, "UpdateSorting")

function ConsMod:RelocateSingle(icon)
	if boxed then
		local a, b, c = size, size+space, 2*size+space
		local neg = -floor(c/2)
		local pos = c+neg
		
		icon:SetAnchorOffsets(neg, neg, pos, pos) --left, top, right, bot
		iconTables[icon][sorting[1]]:SetAnchorOffsets(0, 0, a, a)
		iconTables[icon][sorting[2]]:SetAnchorOffsets(b, 0, c, a)
		iconTables[icon][sorting[3]]:SetAnchorOffsets(0, b, a, c)
		iconTables[icon][sorting[4]]:SetAnchorOffsets(b, b, c, c)
	else
		local l1, l2, l3, l4 = 0, size+space, 2*(size+space), 3*(size+space)
		local r1, r2, r3, r4 = size, 2*size+space, 3*size+2*space, 4*size+3*space
		
		local l, t = -floor(r4/2), -floor(size/2)
		local r, b = r4+l, size+t

		icon:SetAnchorOffsets(l, t, r, b)
		iconTables[icon][sorting[1]]:SetAnchorOffsets(l1, 0, r1, size)
		iconTables[icon][sorting[2]]:SetAnchorOffsets(l2, 0, r2, size)
		iconTables[icon][sorting[3]]:SetAnchorOffsets(l3, 0, r3, size)
		iconTables[icon][sorting[4]]:SetAnchorOffsets(l4, 0, r4, size)
	end
end

function ConsMod:RelocateAll()
	if boxed then
		local a, b, c = size, size+space, 2*size+space
		local neg = -floor(c/2)
		local pos = c+neg
		
		for _, icon in pairs(icons) do
			icon:SetAnchorOffsets(neg, neg, pos, pos) --left, top, right, bot
			iconTables[icon][sorting[1]]:SetAnchorOffsets(0, 0, a, a)
			iconTables[icon][sorting[2]]:SetAnchorOffsets(b, 0, c, a)
			iconTables[icon][sorting[3]]:SetAnchorOffsets(0, b, a, c)
			iconTables[icon][sorting[4]]:SetAnchorOffsets(b, b, c, c)
		end
	else 
		local l1, l2, l3, l4 = 0, size+space, 2*(size+space), 3*(size+space)
		local r1, r2, r3, r4 = size, 2*size+space, 3*size+2*space, 4*size+3*space
		
		local l, t = -floor(r4/2), -floor(size/2)
		local r, b = r4+l, size+t
		
		for _, icon in pairs(icons) do
			icon:SetAnchorOffsets(l, t, r, b)
			iconTables[icon][sorting[1]]:SetAnchorOffsets(l1, 0, r1, size)
			iconTables[icon][sorting[2]]:SetAnchorOffsets(l2, 0, r2, size)
			iconTables[icon][sorting[3]]:SetAnchorOffsets(l3, 0, r3, size)
			iconTables[icon][sorting[4]]:SetAnchorOffsets(l4, 0, r4, size)
		end
	end
end


local showFood = true
local showSpeed = true
local showBoost = true
local showFire = true
local optShowF = MRF:GetOption(ModOptions, "showFood")
local optShowS = MRF:GetOption(ModOptions, "showSpeed")
local optShowB = MRF:GetOption(ModOptions, "showBoost")
local optShowT = MRF:GetOption(ModOptions, "showFire")

local nocombat = true
local optCombat = MRF:GetOption(ModOptions, "nocombat")

function ConsMod:UpdateShowFood(show)
	if show == nil then
		optShowF:Set(true)
	else
		showFood = show
		ConsMod:RehideAll()
	end
end
optShowF:OnUpdate(ConsMod, "UpdateShowFood")

function ConsMod:UpdateShowSpeed(show)
	if show == nil then
		optShowS:Set(true)
	else
		showSpeed = show
		ConsMod:RehideAll()
	end
end
optShowS:OnUpdate(ConsMod, "UpdateShowSpeed")

function ConsMod:UpdateShowBoost(show)
	if show == nil then
		optShowB:Set(true)
	else
		showBoost = show
		ConsMod:RehideAll()
	end
end
optShowB:OnUpdate(ConsMod, "UpdateShowBoost")

function ConsMod:UpdateShowFire(show)
	if show == nil then
		optShowT:Set(true)
	else
		showFire = show
		ConsMod:RehideAll()
	end
end
optShowT:OnUpdate(ConsMod, "UpdateShowFire")

function ConsMod:UpdateNoCombat(b)
	if b == nil then
		optCombat:Set(true)
	else
		nocombat = b
	end
end
optCombat:OnUpdate(ConsMod, "UpdateNoCombat")

function ConsMod:RehideAll()
	for _, icon in pairs(icons) do
		self:RehideSingle(icon)
	end
end

function ConsMod:RehideSingle(icon)
	if not showFood then
		iconTables[icon].Food:Show(false)
	end
	if not showSpeed then
		iconTables[icon].Speed:Show(false)
	end
	if not showBoost then
		iconTables[icon].Boost:Show(false)
	end
	if not showFire then
		iconTables[icon].Fire:Show(false)
	end
end

do
	--apply form on creation of icons.
	local meta = getmetatable(icons)
	local orig = meta.__index
	meta.__index = function(t,k)
		local icon = orig(t,k)
		local form = MRF:LoadForm("ConsumableForm", icon)
		iconTables[icon] = {
			Food = form:FindChild("Food"),
			Speed = form:FindChild("Speed"),
			Boost = form:FindChild("Boost"),
			Fire = form:FindChild("Fire"),
		}
		ConsMod:RelocateSingle(icon)
		ConsMod:RehideSingle(icon)
		return icon
	end
	setmetatable(icons, meta)
	
	--if there are actually some already created.
	for _, icon in pairs(icons) do
		local form = MRF:LoadForm("ConsumableForm", icon)
		iconTables[icon] = {
			Food = form:FindChild("Food"),
			Speed = form:FindChild("Speed"),
			Boost = form:FindChild("Boost"),
			Fire = form:FindChild("Fire"),
		}
	end
	ConsMod:RelocateAll()
	ConsMod:RehideAll()
end


local SpeedID = 53218
local FoodName = GameLib.GetSpell(48443):GetName()
local FireName = GameLib.GetSpell(32778):GetName()
local Boosts = { --Credit to VinceRaidFrames
	[36594] = true, -- Expert Insight Boost
	[38157] = true, -- Expert Grit Boost
	[36588] = true, -- Expert Moxie Boost
	[35028] = true, -- Expert Brutality Boost
	[36579] = true, -- Expert Tech Boost
	[36573] = true, -- Expert Finesse Boost
	
	-- OLD Adventus Potions IDs
	[36595] = true, -- Adventus Insight Boost
	[38158] = true, -- Adventus Grit Boost
	[36589] = true, -- Adventus Moxie Boost
	[35029] = true, -- Adventus Brutality Boost
	[36580] = true, -- Adventus Tech Boost
	[36574] = true, -- Adventus Finesse Boost

	-- NEW Adventus Potions IDs
	[35022] = true, -- Adventus Critical Hit Rating Boost
	[35122] = true, -- Adventus Enduro Boost
	[38153] = true, -- Adventus Critical Mitigation Boost
	[36590] = true, -- Adventus Focus Recovery Boost
	[39715] = true, -- Adventus Crit Boost
	[36575] = true, -- Adventus Glance Boost
	[36584] = true, -- Adventus Multi-Hit Boost
	[35053] = true, -- Adventus Strikethrough Boost
	[36557] = true, -- Adventus Deflect Boost
}


local checks = {
	Food = function(buff)
		return buff.splEffect:GetName() == FoodName
	end,
	Speed = function(buff)
		return buff.splEffect:GetId() == SpeedID
	end,
	Boost = function(buff)
		return Boosts[buff.splEffect:GetId()] or false
	end,
	Fire = function(buff)
		return buff.splEffect:GetName() == FireName
	end
}

function ConsMod:iconUpdate(frame, unit)
	local icon = icons[frame.frame]
	local shows = {
		showFood and "Food" or nil, 
		showSpeed and "Speed" or nil,
		showBoost and "Boost" or nil,
		showFire and "Fire" or nil,
	}
	
	local buffs = unit:GetBuffs()
	if buffs then
		local num = (showFood and 1 or 0) + (showSpeed and 1 or 0) + (showBoost and 1 or 0) + (showFire and 1 or 0)
		local incombat = nocombat
		if incombat then
			local player = GameLib.GetPlayerUnit()
			incombat = player and player:IsInCombat() or false
		end
		
		if not incombat then 
			for _, buff in ipairs(buffs.arBeneficial) do	
				if num == 0 then break; end
				for i, con in pairs(shows) do
					if checks[con](buff) then
						iconTables[icon][con]:Show(true)
						shows[i] = nil
						num = num-1
						break;
					end
				end
			end
		end
	end
	for _, con in pairs(shows) do --hide all left consumables.
		iconTables[icon][con]:Show(false)
	end
end

function ConsMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["Food"] = "Food",
		["Speed"] = "Speedflask",
		["Boost"] = "Boost",
		["Fire"] = "Firebuff",
	}, {--German
		["Size:"] = "Größe:",
		["Space:"] = "Zwischenraum:",
		["Box instead of Row"] = "Als Box, statt in Reihe",
		["Show Food"] = "Zeige Essen",
		["Show Speedflask"] = "Zeige Geschwindigkeits-Flasche",
		["Show Boost"] = "Zeige Boosts",
		["Show Firebuff"] = "Zeige Feuerbuff",
		["Hide in Combat"] = "Im Kampf Verstecken",
		["Sorting:"] = "Sortierung:",
		["Down"] = "Runter",
		["Up"] = "Hoch",
		["Food"] = "Essen",
		["Speed"] = "Geschwindigkeits-Flasche",
		["Boost"] = "Boosts",
		["Fire"] = "Feuerbuff",
	}, {--French
	})

	local boxedRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(boxedRow:FindChild("Left"), boxedOpt, L["Box instead of Row"])
	MRF:applyCheckbox(boxedRow:FindChild("Right"), optCombat, L["Hide in Combat"])
	
	local sizeRow = MRF:LoadForm("HalvedRow", parent)
	sizeRow:FindChild("Left"):SetText(L["Size:"])
	MRF:applySlider(sizeRow:FindChild("Right"), sizeOpt, 1, 50, 1, false, false, true) --textbox: no positive limit
	
	local spaceRow = MRF:LoadForm("HalvedRow", parent)
	spaceRow:FindChild("Left"):SetText(L["Space:"])
	MRF:applySlider(spaceRow:FindChild("Right"), spaceOpt, -10, 40, 1, false, true) --textbox: limitless

	
	local showRow1 = MRF:LoadForm("HalvedRow", parent)
	local showRow2 = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(showRow1:FindChild("Left"), optShowF, L["Show Food"])
	MRF:applyCheckbox(showRow1:FindChild("Right"), optShowS, L["Show Speedflask"])
	MRF:applyCheckbox(showRow2:FindChild("Left"), optShowB, L["Show Boost"])
	MRF:applyCheckbox(showRow2:FindChild("Right"), optShowT, L["Show Firebuff"])

	MRF:LoadForm("HalvedRow", parent):SetText(L["Sorting:"])
	
	local sortRow1 = MRF:LoadForm("HalvedRow", parent)
	local sortRow2 = MRF:LoadForm("HalvedRow", parent)
	local sortRow3 = MRF:LoadForm("HalvedRow", parent)
	local sortRow4 = MRF:LoadForm("HalvedRow", parent)
	
	local lblRow1 = sortRow1:FindChild("Left")
	local lblRow2 = sortRow2:FindChild("Left")
	local lblRow3 = sortRow3:FindChild("Left")
	local lblRow4 = sortRow4:FindChild("Left")
	
	MRF:GetOption(sortingOpt, 1):OnUpdate(function(new) lblRow1:SetText(L[new or ""]) end)
	MRF:GetOption(sortingOpt, 2):OnUpdate(function(new) lblRow2:SetText(L[new or ""]) end)
	MRF:GetOption(sortingOpt, 3):OnUpdate(function(new) lblRow3:SetText(L[new or ""]) end)
	MRF:GetOption(sortingOpt, 4):OnUpdate(function(new) lblRow4:SetText(L[new or ""]) end)
	
	local btnRow1 = MRF:LoadForm("HalvedRow", sortRow1:FindChild("Right"))
	local btnRow2 = MRF:LoadForm("HalvedRow", sortRow2:FindChild("Right"))
	local btnRow3 = MRF:LoadForm("HalvedRow", sortRow3:FindChild("Right"))
	local btnRow4 = MRF:LoadForm("HalvedRow", sortRow4:FindChild("Right"))
	
	--Down-Buttons:
	MRF:LoadForm("Button", btnRow1:FindChild("Right"), {ButtonClick = function()
		local down = sorting[1]
		local up = sorting[2]
		sorting[1] = up
		sorting[2] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Down"])
	
	MRF:LoadForm("Button", btnRow2:FindChild("Right"), {ButtonClick = function() 
		local down = sorting[2]
		local up = sorting[3]
		sorting[2] = up
		sorting[3] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Down"])
	
	MRF:LoadForm("Button", btnRow3:FindChild("Right"), {ButtonClick = function() 
		local down = sorting[3]
		local up = sorting[4]
		sorting[3] = up
		sorting[4] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Down"])
	
	local disabled = MRF:LoadForm("Button", btnRow4:FindChild("Right"))
	disabled:SetText(L["Down"])
	disabled:Enable(false)
	
	--Up-Buttons:
	disabled = MRF:LoadForm("Button", btnRow1:FindChild("Left"))
	disabled:SetText(L["Up"])
	disabled:Enable(false)
	
	MRF:LoadForm("Button", btnRow2:FindChild("Left"), {ButtonClick = function() 
		local down = sorting[1]
		local up = sorting[2]
		sorting[1] = up
		sorting[2] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Up"])
	
	MRF:LoadForm("Button", btnRow3:FindChild("Left"), {ButtonClick = function() 
		local down = sorting[2]
		local up = sorting[3]
		sorting[2] = up
		sorting[3] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Up"])
	
	MRF:LoadForm("Button", btnRow4:FindChild("Left"), {ButtonClick = function() 
		local down = sorting[3]
		local up = sorting[4]
		sorting[3] = up
		sorting[4] = down
		sortingOpt:ForceUpdate()
	end}):SetText(L["Up"])
	
	local anchor = {parent:GetAnchorOffsets()}
	local children = parent:GetChildren()
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end




