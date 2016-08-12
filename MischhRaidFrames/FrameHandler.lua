--[[]]

local FrameHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
local Options = MRF:GetOption(nil, "Frame Handler")
local dirOption = MRF:GetOption(Options, "direction")
local lenOption = MRF:GetOption(Options, "length")
local xOption = MRF:GetOption(Options, "xOffset")
local yOption = MRF:GetOption(Options, "yOffset")
local hSpFrOpt = MRF:GetOption(Options, "horizonalFrameSpace")
local vSpFrOpt = MRF:GetOption(Options, "verticalFrameSpace")
local tSpHeOpt = MRF:GetOption(Options, "topHeaderSpace")
local bSpHeOpt = MRF:GetOption(Options, "bottomHeaderSpace")

MRF:AddMainTab("Frame Handler")
MRF:AddChildTab("General", "Frame Handler", FrameHandler, "InitGeneralSettings")
MRF:AddChildTab("Position", "Frame Handler", FrameHandler, "InitPositioningSettings")
MRF:AddChildTab("Spaces", "Frame Handler", FrameHandler, "InitSpacingSettings")

local L = MRF:Localize({--[[English]]
	["sFirstTagger"] = "First",
	["sRoundRobin"] = "Round Robin",
	["sFreeForAll"] = "FFA",
	["sNeedBeforeGreed"] = "Need & Greed",
	["sMaster"] = "Master",
	["sInferior"] = "Inferior",
	["sAverage"] = "Average",
	["sGood"] = "Good",
	["sExcellent"] = "Excellent",
	["sSuperb"] = "Superb",
	["sLegendary"] = "Legend",
	["sArtifact"] = "Artifact",
	["sOpen"] = "Open",
	["sNeutral"] = "Neutr.",
	["sClosed"] = "Closed",
	["sNone"] = "None",
	["lFirstTagger"] = "First Tagger",
	["lRoundRobin"] = "Round Robin",
	["lFreeForAll"] = "Free For All",
	["lNeedBeforeGreed"] = "Need Before Greed",
	["lMaster"] = "Master Looter",
	["lAverage"] = "Average",
	["lGood"] = "Good",
	["lExcellent"] = "Excellent",
	["lSuperb"] = "Superb",
	["lLegendary"] = "Legendary",
	["lArtifact"] = "Artifact",
	["lInferior"] = "Inferior",
	["lOpen"] = "Open",
	["lNeutral"] = "Neutral",
	["lClosed"] = "Closed",
	["lNone"] = "None",
	["Above: "] = "Above: ",
	["Threshold: "] = "Threshold: ",
	["Below: "] = "Below: ",
	["Harvests: "] = "Harvests: ",
	["Joins: "] = "Joins: ",
	["Referrals: "] = "Referrals: ",
	["Readycheck"] = "Readycheck",
	["Switch Instance"] = "Switch Instance",
	["To Raid"] = "To Raid",
	["Disband"] = "Disband",
	
}, {--[[German]]
	["sFirstTagger"] = "Erster",
	["sRoundRobin"] = "Jeder",
	["sFreeForAll"] = "FFA",
	["sNeedBeforeGreed"] = "Bedarf/Gier",
	["sMaster"] = "Beutemeister",
	["sInferior"] = "Minderw.",
	["sAverage"] = "Mittel",
	["sGood"] = "Gut",
	["sExcellent"] = "Ausgez.",
	["sSuperb"] = "Hervorr.",
	["sLegendary"] = "Legendär",
	["sArtifact"] = "Artefakt",
	["sOpen"] = "Offen",
	["sNeutral"] = "Neutr.",
	["sClosed"] = "Geschl.",
	["sNone"] = "Keine",
	["lFirstTagger"] = "Erster gewinnt",
	["lRoundRobin"] = "Jeder gegen Jeden",
	["lFreeForAll"] = "Frei für alle",
	["lNeedBeforeGreed"] = "Bedarf vor Gier",
	["lMaster"] = "Beutemeister",
	["lInferior"] = "Minderwertig",
	["lAverage"] = "Mittel",
	["lGood"] = "Gut",
	["lExcellent"] = "Ausgezeichnet",
	["lSuperb"] = "Hervorragend",
	["lLegendary"] = "Legendär",
	["lArtifact"] = "Artefakt",
	["lOpen"] = "Offen",
	["lNeutral"] = "Neutral",
	["lClosed"] = "Geschlossen",
	["lNone"] = "Keine",
	["Above: "] = "Drüber: ",
	["Threshold: "] = "Grenzwert: ",
	["Below: "] = "Drunter: ",
	["Harvests: "] = "Sammeln: ",
	["Joins: "] = "Beitritte: ",
	["Referrals: "] = "Empfehlungen: ",
	["Readycheck"] = "Bereitschaftscheck",
	["Switch Instance"] = "Instanz wechseln",
	["To Raid"] = "Zum Raid",
	["Disband"] = "Auflösen",
}, {--[[French]]
})

local ceil = math.ceil

local extendDir = "row" --or "col"
local extendLen = 10
local hFrameSpace = 0
local vFrameSpace = 0
local tHeaderSpace = 0
local bHeaderSpace = 0

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

hSpFrOpt:OnUpdate(FrameHandler, "FrameHSpacing")
function FrameHandler:FrameHSpacing(newVal)
	if type(newVal) ~= "number" then
		hSpFrOpt:Set(0)
	elseif newVal ~= hFrameSpace then
		hFrameSpace = newVal
		self:Reposition()
	end
end

vSpFrOpt:OnUpdate(FrameHandler, "FrameVSpacing")
function FrameHandler:FrameVSpacing(newVal) 
	if type(newVal) ~= "number" then
		vSpFrOpt:Set(0)
	elseif newVal ~= vFrameSpace then
		vFrameSpace = newVal
		self:Reposition()
	end
end

tSpHeOpt:OnUpdate(FrameHandler, "HeaderTopSpacing")
function FrameHandler:HeaderTopSpacing(newVal) 
	if type(newVal) ~= "number" then
		tSpHeOpt:Set(0)
	elseif newVal ~= tHeaderSpace then
		tHeaderSpace = newVal
		self:Reposition()
	end
end

bSpHeOpt:OnUpdate(FrameHandler, "HeaderBotSpacing")
function FrameHandler:HeaderBotSpacing(newVal) 
	if type(newVal) ~= "number" then
		bSpHeOpt:Set(0)
	elseif newVal ~= bHeaderSpace then
		bHeaderSpace = newVal
		self:Reposition()
	end
end

local function max(a, b, ...)
	if not b then
		return a
	end
	return a>b and max(a,...) or max(b,...)
end

local function max_tbl(t, i, m)
	i = i or 1
	m = m or #t
	if i>m then
		return 0
	else
		local x = max_tbl(t, i+1, m)
		return x>t[i] and x or t[i]
	end
end

local function divideCeilSum(tbl, divisor)
	local sum = 0
	for _, a in ipairs(tbl) do
		sum = sum + ceil(a/divisor)
	end
	return sum
end

local function numGreater0(tbl)
	local x = 0
	for i,v in ipairs(tbl) do
		if v>0 then x = x+1 end
	end
	return x
end

local function calcCol_ColExtended()
	--local nH, nT, nD, total = #groups.heals, #groups.tanks, #groups.dps, #groups.heals+#groups.tanks+#groups.dps
	
	local nums, total = {}, 0;
	for i, t in ipairs(groups) do
		nums[i] = #t
		total = total+#t
	end
	
	local approx = ceil(total/extendLen)
	
	--if we support not enought rows to at least do a row of each to-be-displayed group, the for-loop would not be correct. Instead:
	if extendLen <= numGreater0(nums) then
		return max_tbl(nums)
	end
	
	for col = approx, total, 1 do --the number of columns cant overgrow the total frames. very rarely this should do more than 2 iterations. Only for very low extendLen its possible
		if divideCeilSum(nums, col) <= extendLen then --the number of actually needed rows, with this amount of columns
			return col
		end
	end
end

local function calcCol_RowExtended()
	--return the size of the biggest group, or extendLen if its smaller.
	local m = 0
	for _, t in ipairs(groups) do
		m = m<#t and #t or m
		if m >= extendLen then 	--okay, this looks very bad in here - why not after the loop? 
								-- because of the nature of Raidframes we assume, that there are many groups,
								-- which are larger than the maximum of columns being set. Possibly the 
								-- first out of 10 groups. Think about it.
			return extendLen
		end
	end
	
	return m
end

local function addFrames(uTbl, col, top, height, width)
	top = top + bHeaderSpace --space all Frames from the Header above

	local bot = top+height
	local i = 1
	while true do
		local left = 0
		for c = 1, col, 1 do
			if not uTbl[i] then
				if c==1 then
					return top + tHeaderSpace --space all Frames from the Header below
				else
					return bot + tHeaderSpace
				end
			end
			frames[uTbl[i]].frame:SetAnchorOffsets(left, top, left+width, bot)
			left = left + width + hFrameSpace
			i =  i+1
		end
		top = bot + vFrameSpace
		bot = top+height
	end
end

function FrameHandler:Reposition()
	if not groups then return end --just ignore any reposition-request, when never have gotten any groupings.

	FrameHandler:InitGroupFrames() --DO NOT CHANGE TO self - self WILL ALWAYS BE UnitHandler.
	self.Reposition = function(self)
		local col = (extendDir == "row" and calcCol_RowExtended or extendDir == "col" and calcCol_ColExtended)()
		local top = 0
		
		local fHeight = frames[1].frame:GetHeight() --even if neither of both are created yet - they will be hidden on load.
		local fWidth = frames[1].frame:GetWidth()
		local hHeight = groupFrames.headers[1]:GetHeight()
		
		local totalWidth = col*fWidth + (col-1)*hFrameSpace

		for i, tbl in ipairs(groups) do
			if tbl[1] then
				--add header (i)
				groupFrames.headers[i]:Show(true, false)
				--configure header
				groupFrames.headers[i]:SetAnchorOffsets(0, top, totalWidth, top+hHeight)
				groupFrames.headers[i]:FindChild("text"):SetText("("..#tbl..") "..tbl.name..":")
				
				--add all units
				top = addFrames(tbl, col, top+hHeight, fHeight, fWidth)
			else
				--hide Header
				groupFrames.headers[i]:Show(false, false)
			end
		end
		
		--hide all headers above #groups
		for i = #groups+1, #groupFrames.headers, 1 do
			groupFrames.headers[i]:Show(false, false)
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
	
	local l = xOption:Get() or 0
	local t = yOption:Get() or 0
	parentFrame:SetAnchorOffsets(l,t,0,0)
	
	groupFrames.headers = setmetatable({}, {__index = function(t,k) 
		local h = MRF:LoadForm("GroupHeader", parentFrame, self)
		rawset(t,k,h)
		return h
	end})
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
	
	local shorts = { FirstTagger = L["sFirstTagger"], RoundRobin = L["sRoundRobin"], FreeForAll = L["sFreeForAll"], 
		NeedBeforeGreed = L["sNeedBeforeGreed"], Master = L["sMaster"], Average = L["sAverage"], Good = L["sGood"], 
		Excellent = L["sExcellent"], Superb = L["sSuperb"], Legendary = L["sLegendary"], Artifact = L["sArtifact"], 
		Inferior = L["sInferior"], Open = L["sOpen"], Neutral = L["sNeutral"], Closed = L["sClosed"], None = L["sNone"]}
	local longer = { FirstTagger = L["lFirstTagger"], RoundRobin = L["lRoundRobin"], FreeForAll = L["lFreeForAll"], 
		NeedBeforeGreed = L["lNeedBeforeGreed"], Master = L["lMaster"], Average = L["lAverage"], Good = L["lGood"], 
		Excellent = L["lExcellent"], Superb = L["lSuperb"], Legendary = L["lLegendary"], Artifact = L["lArtifact"], 
		Inferior = L["lInferior"], Open = L["lOpen"], Neutral = L["lNeutral"], Closed = L["lClosed"], None = L["lNone"]}
	
	local Inv_Invite = {
		[GroupLib.InvitationMethod.Open] = "Open",
		[GroupLib.InvitationMethod.Neutral] = "Neutral",
		[GroupLib.InvitationMethod.Closed] = "Closed",
		[3] = "None", --this value you get, when not in Group.
	}
	local Rule_Invite = {"Open", "Neutral", "Closed"}
		
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
	local oJoin = MRF:GetOption("FastMenu", "join")
	local oRefer = MRF:GetOption("FastMenu", "referral")
	
	oAbove:OnUpdate(RClickHandler, "SetAbove")
	oBelow:OnUpdate(RClickHandler, "SetBelow")
	oThreshold:OnUpdate(RClickHandler, "SetThreshold")
	oHarvest:OnUpdate(RClickHandler, "SetHarvest")
	oJoin:OnUpdate(RClickHandler, "SetJoin")
	oRefer:OnUpdate(RClickHandler, "SetReferral")
	
	local function applyLoot(above, thres, below, harvest)
		local tbl = GroupLib.GetLootRules()
		GroupLib.SetLootRules(below or tbl.eNormalRule, above or tbl.eThresholdRule,
			thres or tbl.eThresholdQuality, harvest or tbl.eHarvestRule)
	end
	
	function RClickHandler:SetAbove(val)
		if type(val) == "number" then --only apply String
			oAbove:Set(L["Above: "]..shorts[Inv_Rule[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(GroupLib.LootRule[val], nil, nil, nil)
			oAbove:Set(L["Above: "]..shorts[val])
		end
	end
	
	function RClickHandler:SetBelow(val)
		if type(val) == "number" then --only apply String
			oBelow:Set(L["Below: "]..shorts[Inv_Rule[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(nil, nil, GroupLib.LootRule[val], nil)
			oBelow:Set(L["Below: "]..shorts[val])
		end
	end
	
	function RClickHandler:SetThreshold(val)
		if type(val) == "number" then --only apply String
			oThreshold:Set(L["Threshold: "]..shorts[Inv_Threshold[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			
			oThreshold:Set(L["Threshold: "]..shorts[val])
		end
	end
	
	function RClickHandler:SetHarvest(val)
		if type(val) == "number" then --only apply String
			oHarvest:Set(L["Harvests: "]..shorts[Inv_Harvest[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			applyLoot(nil, nil, nil, GroupLib.HarvestLootRule[val])
			oHarvest:Set(L["Harvests: "]..shorts[val])
		end
	end
	
	function RClickHandler:SetJoin(val)
		if type(val) == "number" then --only apply String
			oJoin:Set(L["Joins: "]..shorts[Inv_Invite[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			GroupLib.SetJoinRequestMethod(GroupLib.InvitationMethod[val])
			oJoin:Set(L["Joins: "]..shorts[val])
		end
	end
	
	function RClickHandler:SetReferral(val)
		if type(val) == "number" then --only apply String
			oRefer:Set(L["Referrals: "]..shorts[Inv_Invite[val]])
		elseif val and shorts[val] then --the dropdown had selected something
			GroupLib.SetReferralMethod(GroupLib.InvitationMethod[val])
			oRefer:Set(L["Referrals: "]..shorts[val])
		end
	end
	
	function RClickHandler:OpenSettings(...)
		MRF:InitSettings()
	end
	
	function RClickHandler:OpenGroups()
		MRF:InitGroupForm()
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
		local isRaid = GroupLib.InRaid()
		local isLead = GroupLib.AmILeader() or false
		
		--Roles
		self.btnTank:SetCheck(unit.bTank == true)
		self.btnHeal:SetCheck(unit.bHealer == true)
		self.btnDps:SetCheck(unit.bDPS == true)
		self.btnTank:Enable(noInst or isRaid)
		self.btnHeal:Enable(noInst or isRaid)
		self.btnDps:Enable(noInst or isRaid)
		
		--Additional Buttons		
		self.btnReady:Enable(isRaid and (GroupLib.GetGroupMember(1) or {}).bCanMark or noInst and isLead or false)
		self.btnInstance:Enable(GroupLib.CanGotoGroupInstance())
		self.btnRaid:Enable(isLead and not isRaid and noInst or false )
		self.btnDisband:Enable(isLead and noInst or false)
		
		--Dropdowns / Loot-Stuff
		local tbl = GroupLib.GetLootRules()			
		oBelow:Set(tbl.eNormalRule)
		oAbove:Set(tbl.eThresholdRule)
		oThreshold:Set(tbl.eThresholdQuality)
		oHarvest:Set(tbl.eHarvestRule)
		
		if isLead and noInst then
			self.dropAbove:Enable(true);  self.dropThres:Enable(true);  self.dropBelow:Enable(true);  self.dropHarvest:Enable(true);
		else
			self.dropAbove:Enable(false); self.dropThres:Enable(false); self.dropBelow:Enable(false); self.dropHarvest:Enable(false);
		end
		
		--Dropdowns / Invitations
		oJoin:Set(GroupLib.GetJoinRequestMethod())
		oRefer:Set(GroupLib.GetReferralMethod())
		
		if isLead and noInst then
			self.dropJoin:Enable(true);  self.dropRefer:Enable(true)
		else
			self.dropJoin:Enable(false); self.dropRefer:Enable(false)
		end
	end
	
	function RClickHandler:SwitchInstance( wndHandler, wndControl, eMouseButton )
		if wndHandler ~= wndControl then return end
		if GroupLib.CanGotoGroupInstance() then
			GroupLib.GotoGroupInstance()
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
		self.btnInstance = self.frame:FindChild("Button_Instance")
		self.btnRaid = self.frame:FindChild("Button_2Raid")
		self.btnDisband = self.frame:FindChild("Button_Disband")
		
		self.btnInstance:SetText(L["Switch Instance"])
		self.btnReady:SetText(L["Readycheck"])
		self.btnRaid:SetText(L["To Raid"])
		self.btnDisband:SetText(L["Disband"])
		
		self.dropAbove = MRF:applyDropdown(self.frame:FindChild("Loot_Above"), Loot_Rule, oAbove, trans).drop:FindChild("DropdownButton")
		self.dropThres = MRF:applyDropdown(self.frame:FindChild("Loot_Threshold"), Loot_Threshold, oThreshold, trans).drop:FindChild("DropdownButton")
		self.dropBelow = MRF:applyDropdown(self.frame:FindChild("Loot_Below"), Loot_Rule, oBelow, trans).drop:FindChild("DropdownButton")
		self.dropHarvest = MRF:applyDropdown(self.frame:FindChild("Loot_Harvest"), Loot_Harvest, oHarvest, trans).drop:FindChild("DropdownButton")
		
		self.dropJoin = MRF:applyDropdown(self.frame:FindChild("Request_Join"), Rule_Invite, oJoin, trans).drop:FindChild("DropdownButton")
		self.dropRefer = MRF:applyDropdown(self.frame:FindChild("Request_Referral"), Rule_Invite, oRefer, trans).drop:FindChild("DropdownButton")
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
		local x = self.opt:Get() or 0
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

function FrameHandler:InitGeneralSettings(parent, name)
	local L = MRF:Localize({--English
		["Frame Width:"] = "Frame Width:",
		["Frame Height:"] = "Frame Height:",
		["qSize"] = [[These Sliders set the size of each unit-frame inside your group.]],
		["Frame Inset:"] = "Frame Inset:",
		["qInset"] = [[This Option lets you select how far the actual bars are inset from each of the frames edges.]],
	}, {--German
		["Frame Width:"] = "Frame Breite:",
		["Frame Height:"] = "Frame Höhe:",
		["qSize"] = [[Diese Schieberegler bestimmen die Größe eines jeden Frames in dem Raid.]],
		["Frame Inset:"] = "Innenseitiger Abstand:",
		["qInset"] = [[Diese Option erlaubt es die Bars weiter vom Rand des Frames zu entfernen.]],
		["Background Color:"] = "Hintergrund Farbe:",
	}, {--French
	})

	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local prev = MRF:LoadForm("PreviewSlot", parent)
	MRF:applyPreview(prev, false, "none")
	
	local wOpt = MRF:GetOption(frameOpt, "size", 3)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	wRow:FindChild("Left"):SetText(L["Frame Width:"])
	self:BuildLimitlessSlider(MRF:applySlider(wRow:FindChild("Right"), wOpt, 0, 100, 1, false, true))--textbox: use steps, ignore limits
		
	local hOpt = MRF:GetOption(frameOpt, "size", 4)
	local hRow = MRF:LoadForm("HalvedRow", parent)
	hRow:FindChild("Left"):SetText(L["Frame Height:"])
	self:BuildLimitlessSlider(MRF:applySlider(hRow:FindChild("Right"), hOpt, 0, 100, 1, false, true))
	
	local whQuest = MRF:LoadForm("QuestionMark", wRow:FindChild("Left"))
	whQuest:SetTooltip(L["qSize"])
	
	local iOpt = MRF:GetOption(frameOpt, "inset")
	local iRow = MRF:LoadForm("HalvedRow", parent)
	iRow:FindChild("Left"):SetText(L["Frame Inset:"])
	MRF:applySlider(iRow:FindChild("Right"), iOpt, 0, 20, 1, false, false, true) --textbox: no pos limit
	
	local iQuest = MRF:LoadForm("QuestionMark", iRow:FindChild("Left"))
	iQuest:SetTooltip(L["qInset"])
	
	local bOpt = MRF:GetOption(frameOpt, "backcolor")
	local bRow = MRF:LoadForm("HalvedRow", parent)
	bRow:FindChild("Left"):SetText(L["Background Color:"])
	MRF:applyColorbutton(bRow:FindChild("Right"), bOpt)
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30+50
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
	frameOpt:ForceUpdate()
end

function FrameHandler:InitPositioningSettings(parent, name)
	local L = MRF:Localize({--English
		["Anchor Left Offset:"] = "Anchor Left Offset:",
		["Anchor Top Offset:"] = "Anchor Top Offset:",
		["qOffset"] = [[These two sliders define where the top-left corner of the raid will be.]],
		["Fill-Direction:"] = "Fill-Direction:",
		["First right"] = "First right",
		["First down"] = "First down",
		["Fill-Until:"] = "Fill-Until:",
		["qFill"] = [[These Options define which direction the addon should fill your raid first and how many its maximally allowed to display in that direction.
				Note that if the addon is allowed to display less downside than there are groups(tanks, heals, dps), he will still display a row for each group.]],
	}, {--German
		["Anchor Left Offset:"] = "Ankerpunkt Links:",
		["Anchor Top Offset:"] = "Ankerpunkt Oben:",
		["qOffset"] = [[Diese Schieberegler ermöglichen es die obere linke Ecke des Raids zu verschieben.]],
		["Fill-Direction:"] = "Füll-Richtung:",
		["First right"] = "Rechts zuerst",
		["First down"] = "Runter zuerst",
		["Fill-Until:"] = "Füllen, bis:",
		["qFill"] = [[Diese Optionen definieren, in welche Richtung das Addon zunächst den Raid füllen soll und wieviele Frames es maximal in diese Richtung platzieren darf.]],
	}, {--French
	})
	
	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local xRow = MRF:LoadForm("HalvedRow", parent)
	xRow:FindChild("Left"):SetText(L["Anchor Left Offset:"])
	self:BuildLimitlessSlider(MRF:applySlider(xRow:FindChild("Right"), xOption, 0, 100, 1, false, true))
	
	local yRow = MRF:LoadForm("HalvedRow", parent)
	yRow:FindChild("Left"):SetText(L["Anchor Top Offset:"])
	self:BuildLimitlessSlider(MRF:applySlider(yRow:FindChild("Right"), yOption, 0, 100, 1, false, true))
	
	local aQuest = MRF:LoadForm("QuestionMark", xRow:FindChild("Left"))
	aQuest:SetTooltip(L["qOffset"])
	
	local dirRow = MRF:LoadForm("HalvedRow", parent)
	dirRow:FindChild("Left"):SetText(L["Fill-Direction:"])
	MRF:applyDropdown(dirRow:FindChild("Right"), {"row", "col"}, dirOption, function(x) 
		if x == "row" then return L["First right"]
		elseif x == "col" then return L["First down"]
		else return "" end
	end)
	
	local lenRow = MRF:LoadForm("HalvedRow", parent)
	lenRow:FindChild("Left"):SetText(L["Fill-Until:"])
	MRF:applySlider(lenRow:FindChild("Right"), lenOption, 1, 40, 1)
	
	local fQuest = MRF:LoadForm("QuestionMark", dirRow:FindChild("Left"))
	fQuest:SetTooltip(L["qFill"])
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
	frameOpt:ForceUpdate()
end

function FrameHandler:InitSpacingSettings(parent, name)
	local L = MRF:Localize({--English
		["qPreview"] = [[Preview:
			This picture is supposed to help undestand whats changing, when adding spaces.
			Its not accurate by how many frames are shown in a column/row. There will always be four frames and two headers.
			Green is the visible part of the headers.
			Blue/Red outlines a frame.]],
		["Frame Spaces - Horizontal:"] = "Frame Spaces - Horizontal:",
		["Frame Spaces - Vertical:"] = "Frame Spaces - Vertical:",
		["qFSpace"] = [[With these sliders you can apply additional spaces between the Frames. No space will be added left of the left-most frame, top of the top-most frame, ...]],
		["Header Spaces - Top:"] = "Header Spaces - Top:",
		["Header Spaces - Bottom:"] = "Header Spaces - Bottom:",
		["qHSpace"] = [[These allow you to make space above and below the group-headers (tank, heal, dps). No space will be added top of the first header]],
	}, {--German
		["qPreview"] = [[Vorschau:
			Dieses Bild soll helfen klarzustellen, welche Änderungen Abstände mit sich bringen.
			Die Anzahl von Frames stimmen nicht mit den Einstellungen aus anderen Teilen des Addons überein. Hier werden immer vier Frames und zwei Überschriften in dieser Sortierung gezeigt.
			Grün ist der sichtbare Teil von Überschriften.
			Blau/Rot sind Frames.]],
		["Frame Spaces - Horizontal:"] = "Frame Abstände - Horizontal:",
		["Frame Spaces - Vertical:"] = "Frame Abstände - Vertikal:",
		["qFSpace"] = [[Mit diesen Schiebereglern kann mehr Platz zwischen den einzelnen Frames geschaffen werden. Oberhalb des obersten, unterhalb des untersten(, ...) wird kein zusätzlicher Abstand eingefügt.]],
		["Header Spaces - Top:"] = "Überschriften-Abstand - Oberhalb:",
		["Header Spaces - Bottom:"] = "Überschriften-Abstand - Unterhalb:",
		["qHSpace"] = [[Hier kann mehr Platz über/unter den Gruppen-Überschriften geschaffen werden.]],
	}, {--French
	})
	
	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local prev = self:PreviewSpacing(parent)
	MRF:LoadForm("QuestionMark", prev):SetTooltip(L["qPreview"])
	
	local hRow = MRF:LoadForm("HalvedRow", parent)
	hRow:FindChild("Left"):SetText(L["Frame Spaces - Horizontal:"])
	MRF:applySlider(hRow:FindChild("Right"), hSpFrOpt, -20, 80, 1)
	
	local vRow = MRF:LoadForm("HalvedRow", parent)
	vRow:FindChild("Left"):SetText(L["Frame Spaces - Vertical:"])
	MRF:applySlider(vRow:FindChild("Right"), vSpFrOpt, -20, 80, 1)
	
	local sfQuest = MRF:LoadForm("QuestionMark", hRow:FindChild("Left"))
	sfQuest:SetTooltip(L["qFSpace"])
	
	local tRow = MRF:LoadForm("HalvedRow", parent)
	tRow:FindChild("Left"):SetText(L["Header Spaces - Top:"])
	MRF:applySlider(tRow:FindChild("Right"), tSpHeOpt, -20, 80, 1)
	
	local bRow = MRF:LoadForm("HalvedRow", parent)
	bRow:FindChild("Left"):SetText(L["Header Spaces - Bottom:"])
	MRF:applySlider(bRow:FindChild("Right"), bSpHeOpt, -20, 80, 1)
	
	local shQuest = MRF:LoadForm("QuestionMark", tRow:FindChild("Left"))
	shQuest:SetTooltip(L["qHSpace"])
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30+200
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
	frameOpt:ForceUpdate()
end

function FrameHandler:PreviewSpacing(parent)
	local floor, ceil = math.floor, math.ceil
	local cBlue = ApolloColor.new("A000A0FF")
	local cGreen = ApolloColor.new("A000FF00")
	local cRed = ApolloColor.new("A0FF0000")
	
	local tl, tr, bl, br, th, bh; --top-left, ..., bottom-right, top-header, bottom-header
	
	local templateOpt = MRF:GetOption(nil, "frame")
	local template = templateOpt:Get();
	
	local hFSpace = hFrameSpace
	local vFSpace = vFrameSpace
	local tHSpace = tHeaderSpace
	local bHSpace = bHeaderSpace
	
	local function recolor(frame)
		frame:SetVar("backcolor", nil, cBlue)
		for _, modKey in ipairs(frame.oldTemp) do
			frame:SetVar("progress", modKey, 1)
			frame:SetVar("barcolor", modKey, cRed, cRed)
		end
	end
	
	local function reposition()		
		--from above:
		--local hFrameSpace = 0
		--local vFrameSpace = 0
		--local tHeaderSpace = 0
		--local bHeaderSpace = 0
		
		local width = tl.frame:GetWidth()
		local height = tl.frame:GetHeight()
		local heightHead = th:GetHeight()
		
		local leftStart = -floor(hFSpace/2)
		local rightStart = ceil(hFSpace/2)
		local leftEnd = leftStart - width
		local rightEnd = rightStart + width
		
		local topFrameStart = -floor(vFSpace/2)
		local botFrameStart = ceil(vFSpace/2)
		local topFrameEnd = topFrameStart - height
		local botFrameEnd = botFrameStart + height
		
		local topHeaderStart = topFrameEnd - bHSpace
		local botHeaderStart = botFrameEnd + tHSpace
		local topHeaderEnd = topHeaderStart - heightHead
		local botHeaderEnd = botHeaderStart + heightHead
		
		--lleft,top,right,bottom
		tl.frame:SetAnchorOffsets(leftEnd, topFrameEnd, leftStart, topFrameStart)
		tr.frame:SetAnchorOffsets(rightStart, topFrameEnd, rightEnd, topFrameStart)
		bl.frame:SetAnchorOffsets(leftEnd, botFrameStart, leftStart, botFrameEnd)
		br.frame:SetAnchorOffsets(rightStart, botFrameStart, rightEnd, botFrameEnd)
		
		th:SetAnchorOffsets(leftEnd, topHeaderEnd, rightEnd, topHeaderStart)
		bh:SetAnchorOffsets(leftEnd, botHeaderStart, rightEnd, botHeaderEnd)
	end
	
	templateOpt:OnUpdate(function(newTemplate)
		template = newTemplate;
		
		tl:UpdateOptions(newTemplate); tl.frame:SetAnchorPoints(0.5,0.5,0.5,0.5)
		tr:UpdateOptions(newTemplate); tr.frame:SetAnchorPoints(0.5,0.5,0.5,0.5)
		bl:UpdateOptions(newTemplate); bl.frame:SetAnchorPoints(0.5,0.5,0.5,0.5)
		br:UpdateOptions(newTemplate); br.frame:SetAnchorPoints(0.5,0.5,0.5,0.5)
		--reposition all frames.
		
		recolor(tl); recolor(tr); recolor(bl); recolor(br);
		reposition()
	end)
	
	hSpFrOpt:OnUpdate(function(val) hFSpace= val or 0; reposition() end);
	vSpFrOpt:OnUpdate(function(val) vFSpace= val or 0; reposition() end);
	tSpHeOpt:OnUpdate(function(val) tHSpace= val or 0; reposition() end);
	bSpHeOpt:OnUpdate(function(val) bHSpace= val or 0; reposition() end);
	
	local parent = MRF:LoadForm("PreviewSlot", parent)
	parent:SetAnchorOffsets(0,0,0,230)
	
	tl, tr, bl, br = MRF:newFrame(parent, template), MRF:newFrame(parent, template), MRF:newFrame(parent, template), MRF:newFrame(parent, template)
	th, bh = MRF:LoadForm("GroupHeader", parent), MRF:LoadForm("GroupHeader", parent)
	
	recolor(tl); recolor(tr); recolor(bl); recolor(br);
	th:FindChild("line"):SetBGColor(cGreen); bh:FindChild("line"):SetBGColor(cGreen);
	th:FindChild("text"):SetText("Text"); bh:FindChild("text"):SetText("Text")
	th:SetAnchorPoints(0.5,0.5,0.5,0.5); bh:SetAnchorPoints(0.5,0.5,0.5,0.5)
	th:Show(true); bh:Show(true);
	
	return parent
end