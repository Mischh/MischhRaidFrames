--[[]]

local FrameHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
local Options = MRF:GetOption(nil, "Frame Handler")
local dirOption = MRF:GetOption(Options, "direction")
local lenOption = MRF:GetOption(Options, "length")
local xOption = MRF:GetOption(Options, "xOffset")
local yOption = MRF:GetOption(Options, "yOffset")
MRF:AddMainTab("Frame Handler", FrameHandler, "InitSettings")

local ceil = math.ceil

local extendDir = "row" --or "col"
local extendLen = 10

--stuff for :Reposition()
local groups = nil; --gotten before first :Reposition (guaranteed)
local groupFrames = {} --initialized in :InitGroupFrames
local parentFrame = nil
local frames = setmetatable({}, {__index = function(frames, i)
	frames[i] = FrameHandler:CreateNewFrame()
	return frames[i]
end})

dirOption:OnUpdate(function(newVal)
	if newVal == "row" or newVal == "col" then
		extendDir = newVal
		FrameHandler:Reposition()
	else
		dirOption:Set("col")
	end
end)

lenOption:OnUpdate(function(newVal) 
	if type(newVal) == "number" and newVal > 0 then
		extendLen = newVal
		FrameHandler:Reposition()
	else
		lenOption:Set(1)
	end
end)

xOption:OnUpdate(function(newVal)
	if type(newVal) ~= "number" then
		xOption:Set(0)
	elseif parentFrame then
		local _, t = parentFrame:GetAnchorOffsets()
		parentFrame:SetAnchorOffsets(newVal,t,0,0) 
	end
end)

yOption:OnUpdate(function(newVal)
	if type(newVal) ~= "number" then
		yOption:Set(0)
	elseif parentFrame then
		local l, _ = parentFrame:GetAnchorOffsets()
		parentFrame:SetAnchorOffsets(l,newVal,0,0) 
	end
end)

local function max(a, b, ...)
	if not b then
		return a
	end
	return a>b and max(a,...) or max(b,...)
end

local function calcCol_ColExtended()
	local nH, nT, nD, total = #groups.heals, #groups.tanks, #groups.dps, #groups.heals+#groups.tanks+#groups.dps
	local approx = ceil(total/extendLen)
	
	--if we support not enought rows to at least do a row of each to-be-displayed group, the for-loop would not be correct. Instead:
	if extendLen <= (nH>0 and 1 or 0) + (nT>0 and 1 or 0) + (nD>0 and 1 or 0) then
		return max(nH, nT, nD)
	end
	
	for col = approx, total, 1 do --the number of columns cant overgrow the total frames. very rarely this should do more than 2 iterations. Only for very low extendLen its possible
		if ceil(nH/col)+ceil(nT/col)+ceil(nD/col) <= extendLen then --the number of actually needed rows, with this amount of columns
			return col
		end
	end
end

local function calcCol_RowExtended()
	--get the bigges of #healers, #tanks, #dps
	local m = max(#groups.heals, #groups.tanks, #groups.dps)
	return extendLen<m and extendLen or m
end

local function addFrames(uTbl, col, top, height, width)
	local bot = top+height
	local i = 1
	while true do
		local left = 0
		for c = 1, col, 1 do
			if not uTbl[i] then return c==1 and top or bot end
			frames[uTbl[i]].frame:SetAnchorOffsets(left, top, left+width, bot)
			left = left + width
			i =  i+1
		end
		top = bot
		bot = top+height
	end
end

function FrameHandler:Reposition()
	if not groups then return end --just ignore any reposition-request, when never have gotten any groupings.

	FrameHandler:InitGroupFrames() --DO NOT CHANGE TO self - self WILL ALWAYS BE UnitHandler.
	self.Reposition = function(self)
		local col = (extendDir == "row" and calcCol_RowExtended or extendDir == "col" and calcCol_ColExtended)()
		local top = 0
		
		local fHeight = frames[1].frame:GetHeight()
		local fWidth = frames[1].frame:GetWidth()
		local hHeight = groupFrames.healHeader:GetHeight()

		if groups.tanks[1] then
			--add the header
			groupFrames.tankHeader:SetAnchorOffsets(0, top, col*fWidth, top+hHeight)
			groupFrames.tankHeader:Show(true, false)
			groupFrames.tankText:SetText("("..#groups.tanks..") Tanks:")
			--top = top+hHeight <- done within the addFrames call - see 3rd Parameter
			
			top = addFrames(groups.tanks, col, top+hHeight, fHeight, fWidth)
		else
			--hide header.
			groupFrames.tankHeader:Show(false, false)
		end
		if groups.heals[1] then
			--add the header
			groupFrames.healHeader:SetAnchorOffsets(0, top, col*fWidth, top+hHeight)
			groupFrames.healHeader:Show(true, false)
			groupFrames.healText:SetText("("..#groups.heals..") Heals:")
			--top = top+hHeight <- done within the addFrames call - see 3rd Parameter
			
			top = addFrames(groups.heals, col, top+hHeight, fHeight, fWidth)
		else
			--hide header.
			groupFrames.healHeader:Show(false, false)
		end
		if groups.dps[1] then
			--add the header
			groupFrames.dpsHeader:SetAnchorOffsets(0, top, col*fWidth, top+hHeight)
			groupFrames.dpsHeader:Show(true, false)
			groupFrames.dpsText:SetText("("..#groups.dps..") DPS:")
			--top = top+hHeight <- done within the addFrames call - see 3rd Parameter
			
			top = addFrames(groups.dps, col, top+hHeight, fHeight, fWidth)
		else
			--hide header.
			groupFrames.dpsHeader:Show(false, false)
		end
	end
	return self:Reposition()
end

function MRF:GetFrameHandlersReposition(unithandler_groups)
	groups = unithandler_groups
	--we need these groups to do all the stuff in :Reposition()
	return FrameHandler.Reposition
end

function MRF:GetFrameTable()
	return frames;
end

local frameTmp = nil

local frameOpt = MRF:GetOption(nil, "frame")
MRF:GatherUpdates(frameOpt)
frameOpt:OnUpdate( function(newTemplate) 
	frameTmp = newTemplate;
	for i,frame in ipairs(frames) do
		frame:UpdateOptions(newTemplate)
		
		MRF:PushUnitUpdateForFrameIndex(i) 
	end
	FrameHandler:Reposition()
end)

function FrameHandler:InitGroupFrames()
	if parentFrame then return end --already done.
	parentFrame =  MRF:LoadForm("Raid-Container", nil, self)
	groupFrames.healHeader = MRF:LoadForm("GroupHeader", parentFrame, self)
	groupFrames.tankHeader = MRF:LoadForm("GroupHeader", parentFrame, self)
	groupFrames.dpsHeader  = MRF:LoadForm("GroupHeader", parentFrame, self)
	groupFrames.healText = groupFrames.healHeader:FindChild("text")
	groupFrames.tankText = groupFrames.tankHeader:FindChild("text")
	groupFrames.dpsText  = groupFrames.dpsHeader:FindChild("text")
	
	local l = xOption:Get() or 0
	local t = yOption:Get() or 0
	parentFrame:SetAnchorOffsets(l,t,0,0)
end

function FrameHandler:CreateNewFrame()
	self:InitGroupFrames()--only wanna do this once.
	self.CreateNewFrame = function() 
		return MRF:newFrame(parentFrame, frameTmp)
	end
	return self:CreateNewFrame()
end

function FrameHandler:OnClickHeader(wndHandler, wndControl, eMouseButton)
	if wndControl:GetName() == "GroupHeader" and eMouseButton == GameLib.CodeEnumInputMouse.Right then
		MRF:ShowFastMenu(wndControl)
	end
end

do --FastMenu
	local RClickHandler = {}
	local Loot_Harvest = {"FirstTagger", "RoundRobin"}
	local Inv_Harvest = {[GroupLib.HarvestLootRule.FirstTagger] = "FirstTagger", 
		[GroupLib.HarvestLootRule.RoundRobin] = "RoundRobin"}
		
	local Loot_Rule = {"FreeForAll", "RoundRobin", "NeedBeforeGreed", "Master"}
	local Inv_Rule = {[GroupLib.LootRule.FreeForAll] = "FreeForAll",
		[GroupLib.LootRule.RoundRobin] = "RoundRobin",
		[GroupLib.LootRule.NeedBeforeGreed] = "NeedBeforeGreed",
		[GroupLib.LootRule.Master] = "Master"}
		
	local Loot_Threshold = {"Inferior", "Average", "Good", "Excellent", "Superb", "Legendary", "Artifact"}
	local Inv_Threshold = {[GroupLib.LootThreshold.Inferior] = "Inferior",
		[GroupLib.LootThreshold.Average] = "Average",
		[GroupLib.LootThreshold.Good] = "Good",
		[GroupLib.LootThreshold.Excellent] = "Excellent",
		[GroupLib.LootThreshold.Superb] = "Superb",
		[GroupLib.LootThreshold.Legendary] = "Legendary",
		[GroupLib.LootThreshold.Artifact] = "Artifact"}
	
	local shorts = { FirstTagger = "First", RoundRobin = "Round Robin", FreeForAll = "FFA", NeedBeforeGreed = "Need & Greed", Master = "Master",
		Average = "Average", Good = "Good", Excellent = "Excellent", Superb = "Superb", Legendary = "Legend", Artifact = "Artifact", Inferior = "Inferior" }
	local longer = { FirstTagger = "First Tagger", RoundRobin = "Round Robin", FreeForAll = "Free For All", 
		NeedBeforeGreed = "Need Before Greed ", Master = "Master Looter", Average = "Average", Good = "Good", 
		Excellent = "Excellent", Superb = "Superb", Legendary = "Legendary", Artifact = "Artifact", Inferior = "Inferior"}
	
	local function trans(str)
		if not str or not longer[str] then
			return str or ""
		elseif type(str) == "string" then
			return longer[str]
		else
			return "" --not permanent value, dont even build a string.
		end
	end
	
	local oAbove = MRF:GetOption("FastMenu", "above")
	local oBelow = MRF:GetOption("FastMenu", "below")
	local oThreshold = MRF:GetOption("FastMenu", "threshold")
	local oHarvest = MRF:GetOption("FastMenu", "harvest")
	
	oAbove:OnUpdate(RClickHandler, "SetAbove")
	oBelow:OnUpdate(RClickHandler, "SetBelow")
	oThreshold:OnUpdate(RClickHandler, "SetThreshold")
	oHarvest:OnUpdate(RClickHandler, "SetHarvest")
	
	local function applyLoot(above, thres, below, harvest)
		local tbl = GroupLib.GetLootRules()
		GroupLib.SetLootRules(below or tbl.eNormalRule, above or tbl.eThresholdRule,
			thres or tbl.eThresholdQuality, harvest or tbl.eHarvestRule)
	end
	
	function RClickHandler:SetAbove(val)
		if type(val) == "number" then --only apply String
			oAbove:Set("Above: "..shorts[Inv_Rule[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(GroupLib.LootRule[val], nil, nil, nil)
			oAbove:Set("Above: "..shorts[val])
		end
	end
	
	function RClickHandler:SetBelow(val)
		if type(val) == "number" then --only apply String
			oBelow:Set("Below: "..shorts[Inv_Rule[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(nil, nil, GroupLib.LootRule[val], nil)
			oBelow:Set("Below: "..shorts[val])
		end
	end
	
	function RClickHandler:SetThreshold(val)
		if type(val) == "number" then --only apply String
			oThreshold:Set("Threshold: "..shorts[Inv_Threshold[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(nil, GroupLib.LootThreshold[val], nil, nil)
			oThreshold:Set("Threshold: "..shorts[val])
		end
	end
	
	function RClickHandler:SetHarvest(val)
		if type(val) == "number" then --only apply String
			oHarvest:Set("Harvests: "..shorts[Inv_Harvest[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(nil, nil, nil, GroupLib.HarvestLootRule[val])
			oHarvest:Set("Harvests: "..shorts[val])
		end
	end
	
	function RClickHandler:SelectRoleTank( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		GroupLib.SetRoleTank(1, true) 
		--GroupLib.SetRoleHealer(1, false)
		--GroupLib.SetRoleDPS(1, false)
	end

	function RClickHandler:SelectRoleHeal( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		--GroupLib.SetRoleTank(1, false) 
		GroupLib.SetRoleHealer(1, true)
		--GroupLib.SetRoleDPS(1, false)
	end

	function RClickHandler:SelectRoleDPS( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		--GroupLib.SetRoleTank(1, false) 
		--GroupLib.SetRoleHealer(1, false)
		GroupLib.SetRoleDPS(1, true)
	end

	--this is not MRF:ShowFastMenu(), this is the OnShow of the FastMenu
	function RClickHandler:ShowFastMenu( wndHandler, wndControl )
		if wndHandler ~= wndControl then return end
		local unit = GroupLib.GetGroupMember(1) or {} --the first member is always you.
		local noInst = not GroupLib.InInstance()
		
		--Roles
		self.btnTank:SetCheck(unit.bTank == true)
		self.btnHeal:SetCheck(unit.bHealer == true)
		self.btnDps:SetCheck(unit.bDPS == true)
		self.btnTank:Enable(noInst)
		self.btnHeal:Enable(noInst)
		self.btnDps:Enable(noInst)
		
		--Additional Buttons
		self.btnReady:Enable((GroupLib.GetGroupMember(1) or {}).bCanMark and noInst or false )
		self.btnRaid:Enable(GroupLib.AmILeader() and not GroupLib.InRaid() and noInst or false )
		self.btnDisband:Enable(GroupLib.AmILeader() and noInst or false)
		
		--Dropdowns / Loot-Stuff
		local tbl = GroupLib.GetLootRules()			
		oBelow:Set(tbl.eNormalRule)
		oAbove:Set(tbl.eThresholdRule)
		oThreshold:Set(tbl.eThresholdQuality)
		oHarvest:Set(tbl.eHarvestRule)
		
		if GroupLib.AmILeader() and noInst  then
			self.dropAbove:Enable(true); self.dropThres:Enable(true); self.dropBelow:Enable(true); self.dropHarvest:Enable(true);
		else
			self.dropAbove:Enable(false); self.dropThres:Enable(false); self.dropBelow:Enable(false); self.dropHarvest:Enable(false);
		end
		
	end
	
	function RClickHandler:Readycheck( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		if not GroupLib.IsReadyCheckOnCooldown() then
			GroupLib.ReadyCheck()
		end
	end
	
	function RClickHandler:ConvertToRaid( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		if GroupLib.AmILeader() then
			GroupLib.ConvertToRaid()
		end
	end
	
	function RClickHandler:Disband( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		if GroupLib.AmILeader() then
			GroupLib.DisbandGroup()
		end
	end
	
	function RClickHandler:OnHideMenu( wndHandler, wndControl )
		if wndHandler ~= wndControl then return end
		self.spacer:Show(false, false)
	end
	
	function RClickHandler:OnShowSpacer( wndHandler, wndControl )
		if wndHandler ~= wndControl then return end
		self.frame:Show(true, false)
	end
	
	function RClickHandler:InitFastMenu()
		FrameHandler:InitGroupFrames() --to be sure parentFrame exists - should not be needed.
		self.spacer = MRF:LoadForm("FastMenuTemplate", parentFrame, self)
		self.frame = self.spacer:FindChild("FastMenu")
		self.btnTank = self.frame:FindChild("Button_Tank")
		self.btnHeal = self.frame:FindChild("Button_Healer")
		self.btnDps = self.frame:FindChild("Button_Dps")
		self.btnReady = self.frame:FindChild("Button_Ready")
		self.btnRaid = self.frame:FindChild("Button_2Raid")
		self.btnDisband = self.frame:FindChild("Button_Disband")
		--parent, choices, selector, translator, ..
		self.dropAbove = MRF:applyDropdown(self.frame:FindChild("Loot_Above"), Loot_Rule, oAbove, trans).drop:FindChild("DropdownButton")
		self.dropThres = MRF:applyDropdown(self.frame:FindChild("Loot_Threshold"), Loot_Threshold, oThreshold, trans).drop:FindChild("DropdownButton")
		self.dropBelow = MRF:applyDropdown(self.frame:FindChild("Loot_Below"), Loot_Rule, oBelow, trans).drop:FindChild("DropdownButton")
		self.dropHarvest = MRF:applyDropdown(self.frame:FindChild("Loot_Harvest"), Loot_Harvest, oHarvest, trans).drop:FindChild("DropdownButton")
	end
	
	function MRF:ShowFastMenu(...)
		RClickHandler:InitFastMenu()
		self.ShowFastMenu = function(self, parent)
			local _, t, r, _ = parent:GetAnchorOffsets()
			RClickHandler.spacer:SetAnchorOffsets(0,t,r,0) --only set top and right, the rest should be ignorable
			RClickHandler.spacer:Show(true, false)
		end
		return self:ShowFastMenu(...)
	end
end

local function check(self)
	if not self.slider:IsThumbDragging() then
		Apollo.RemoveEventHandler("NextFrame", self)
		local x = self.opt:Get()
		local l = x>100 and x-100 or 0
		local r = l+200
		self:SetMinMax(l,r)
		self.slider:SetValue(x)
		return true
		
	else
		return false
	end
end

function FrameHandler:BuildLimitlessSlider(slider)	
	slider.CheckDraggingThumb = check
	
	slider.opt:OnUpdate(function(newVal) 
		if not slider:CheckDraggingThumb() then
			Apollo.RegisterEventHandler("NextFrame", "CheckDraggingThumb", slider)
		end
	end)
end

function FrameHandler:InitSettings(parent, name)
	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local xRow = MRF:LoadForm("HalvedRow", parent)
	xRow:FindChild("Left"):SetText("Anchor Left Offset:")
	self:BuildLimitlessSlider(MRF:applySlider(xRow:FindChild("Right"), xOption, 0, 100, 1))
	
	local yRow = MRF:LoadForm("HalvedRow", parent)
	yRow:FindChild("Left"):SetText("Anchor Top Offset:")
	self:BuildLimitlessSlider(MRF:applySlider(yRow:FindChild("Right"), yOption, 0, 100, 1))
	
	MRF:LoadForm("HalvedRow", parent)
	
	local wOpt = MRF:GetOption(frameOpt, "size", 3)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	wRow:FindChild("Left"):SetText("Frame Width:")
	self:BuildLimitlessSlider(MRF:applySlider(wRow:FindChild("Right"), wOpt, 0, 100, 1))
		
	local hOpt = MRF:GetOption(frameOpt, "size", 4)
	local hRow = MRF:LoadForm("HalvedRow", parent)
	hRow:FindChild("Left"):SetText("Frame Height:")
	self:BuildLimitlessSlider(MRF:applySlider(hRow:FindChild("Right"), hOpt, 0, 100, 1))
	
	MRF:LoadForm("HalvedRow", parent)
	
	local dirRow = MRF:LoadForm("HalvedRow", parent)
	dirRow:FindChild("Left"):SetText("Fill-Direction:")
	MRF:applyDropdown(dirRow:FindChild("Right"), {"row", "col"}, dirOption, function(x) 
		if x == "row" then return "First right"
		elseif x == "col" then return "First down"
		else return "" end
	end)
	
	local lenRow = MRF:LoadForm("HalvedRow", parent)
	lenRow:FindChild("Left"):SetText("Fill-Until:")
	MRF:applySlider(lenRow:FindChild("Right"), lenOption, 1, 40, 1)
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30 --we want to display six 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
	wOpt:ForceUpdate(); hOpt:ForceUpdate()
end

