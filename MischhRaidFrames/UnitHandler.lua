local MRF = Apollo.GetAddon("MischhRaidFrames")
local UnitHandler = {}
local Options = MRF:GetOption(nil, "Unit Handler")
local unitOpt = MRF:GetOption(Options, "unit")
local freqOpt = MRF:GetOption(Options, "frequent")
local eachOpt = MRF:GetOption(Options, "eachFrame")

MRF:AddMainTab("Updates", UnitHandler, "InitSettings")

local units = {}  --current units [groupIndex] = unit --this is not a WS unit, but acts as one
local frames = MRF:GetFrameTable();

local unitTimer = nil;
local unittime = 1
local freqtime = 1000 --in milliseconds

do
	local f = MRF.OnDocLoaded
	function MRF:OnDocLoaded(...)
		f(self,...)
		Apollo.RegisterEventHandler("Group_Left", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("Group_Join", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("Group_Add", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("Group_Remove", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("Group_MemberFlagsChanged", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("Group_SetMark", "GroupUpdate", UnitHandler)
		Apollo.RegisterEventHandler("NextFrame", "OnUpdate", UnitHandler)
		unitTimer = ApolloTimer.Create(unittime, true, "CheckNextUnit", UnitHandler)
		self:ForceGroupUpdate()
	end
end

unitOpt:OnUpdate(function(newVal) 
	if type(newVal) ~= "number" then
		unitOpt:Set(1)
	else
		unittime = newVal
		if unitTimer then
			unitTimer:Set(newVal, true)
		end
	end
end)

freqOpt:OnUpdate(function(newVal)
	if type(newVal) ~= "number" then
		freqOpt:Set(1)
	else
		freqtime = newVal*1000 --in milliseconds
	end
end)

eachOpt:OnUpdate(function(newVal) 
	if type(newVal) ~= "boolean" then 
		eachOpt:Set(false)
	else
		--UnitHandler.OnUpdate = newVal and UnitHandler.OnUpdate_Every or UnitHandler.OnUpdate_Distant
	end
end)

function MRF:ForceGroupUpdate()
	UnitHandler:GroupUpdate()
end

local lastUnit = 0
function UnitHandler:CheckNextUnit()
	lastUnit = lastUnit+1
	if units[lastUnit] == nil then lastUnit = 1 end
	if not units[lastUnit] then return end
	
	self:UpdateUnit(lastUnit)
end

do
	local floor = math.floor
	local lastUnit = 1
	local lastUpdate = 0
	function UnitHandler:OnUpdate_Distant()
		local max = #units
		if max < 1 then return end
		
		local now = Apollo.GetTickCount()
		local elapsed = now - lastUpdate
		
		local x = elapsed/freqtime * max
		x = x<max and x or max
		local update = floor(x)
		if update>0 then
			local excesstime = (elapsed*max or 0)%freqtime
			lastUpdate = now-excesstime
		 	local start = lastUnit+1
			if lastUnit+update > max then 
				lastUnit = lastUnit+update-max
				for i = start, max, 1 do
					MRF:PushFrequentUpdate(frames[i], units[i])
				end
				for i = 1, lastUnit do
					MRF:PushFrequentUpdate(frames[i], units[i])
				end
			else
				lastUnit = lastUnit+update
				for i = start, lastUnit, 1 do
					MRF:PushFrequentUpdate(frames[i], units[i])
				end
			end
			
		end
	end
	
	function UnitHandler:OnUpdate_Every()
		for i,unit in ipairs(units) do
			MRF:PushFrequentUpdate(frames[i], unit)
		end
	end
	
	UnitHandler.OnUpdate = UnitHandler.OnUpdate_Distant--default
end

local GroupLib_GetUnitForGroupMember = function(...)
	if ... == 1 then --the first Unit is always the player.
		return GameLib.GetPlayerUnit()
	else
		return GroupLib.GetUnitForGroupMember(...)
	end
end

function UnitHandler:UpdateUnit(i)
	local unit = GroupLib_GetUnitForGroupMember(i); 
	local mem = GroupLib.GetGroupMember(i) or {}; --{} only happens, if we are actually not in a group

	if not units[i] then
		units[i] = self:newUnit(mem, unit)
	else
		units[i]:ApplyUnit(mem, unit)
	end

	MRF:PushUnitUpdate(frames[i], units[i])
end

function MRF:MakePlayerAUnit()
	frames[1]:Show(true, true)
	UnitHandler:UpdateUnit(1)
	UnitHandler:Regroup()
	UnitHandler:Reposition()
	UnitHandler:HideAdditionalFrames()
end

function MRF:PushUnitUpdateForFrameIndex(i)
	if units[i] then
		MRF:PushUnitUpdate(frames[i], units[i])
	end
end

function UnitHandler:FullUnitUpdate()
	units = {}
	local num = GroupLib.GetMemberCount()
	for i = 1, num, 1 do
		frames[i]:Show(true, true)
		self:UpdateUnit(i)
	end
	
	for i = num+1, #frames, 1 do
		frames[i]:Show(false, true)
	end
end

function UnitHandler:GroupUpdate()
	self:FullUnitUpdate()
	self:Regroup()
	self:Reposition() -- see FrameHandler:Reposition() for this, we actually apply it there.
	self:HideAdditionalFrames()
end

local FakePrototype = {}
function FakePrototype:ApplyUnit(groupMember, unit) self.tbl = groupMember; self.unit = unit end
function FakePrototype:GetRealUnit() return rawget(self,"unit") end
function FakePrototype:GetTargetMarker() return self.tbl.nMarkerId end
function FakePrototype:GetClassId() return self.tbl.eClassId end
function FakePrototype:GetName() return self.tbl.strCharacterName end
function FakePrototype:GetAbsorptionMax() return self.tbl.nAbsorbtionMax end
function FakePrototype:GetAbsorptionValue() return self.tbl.nAbsorbtion end
function FakePrototype:GetInterruptArmorMax() return self.tbl.nInterruptArmorMax end
function FakePrototype:GetInterruptArmorValue() return self.tbl.nInterruptArmor end
function FakePrototype:GetHealth() return self.tbl.nHealth end
function FakePrototype:GetMaxHealth() return self.tbl.nHealthMax end
function FakePrototype:GetMaxFocus() return self.tbl.nManaMax end
function FakePrototype:GetFocus() return self.tbl.nMana end
function FakePrototype:GetShieldCapacity() return self.tbl.nShield end
function FakePrototype:GetShieldCapacityMax() return self.tbl.nShieldMax end
function FakePrototype:GetLevel() return self.tbl.nLevel end
function FakePrototype:GetRaceId() return self.tbl.eRaceId end
function FakePrototype:GetPlayerPathType() return self.tbl.ePathType end
function FakePrototype:IsHeal() return self.tbl.bHealer end
function FakePrototype:IsTank() return self.tbl.bTank end
function FakePrototype:IsLeader() return self.tbl.bIsLeader end
function FakePrototype:CanInvite() return self.tbl.bCanInvite end
function FakePrototype:CanKick() return self.tbl.bCanKick end
function FakePrototype:IsRaidAssistant() return self.tbl.bRaidAssistant end
function FakePrototype:IsMainAssist() return self.tbl.bMainAssist end
function FakePrototype:IsMainTank() return self.tbl.bMainTank end

local meta_unit = {__index = function(t, fName)
	local f = function(self, ...)
		local ret = nil;
		local unit = rawget(self, "unit") --we want nil to be returned, if there is no Unit - __index would return a function instead.
		if unit and unit[fName] then
			ret = {unit[fName](unit, ...)}
		end
		if (not ret or ret[1] == nil) and FakePrototype[fName] then
			ret = {FakePrototype[fName](self, ...)}
		end
		return unpack(ret or {})
	end
	rawset(t, fName, f)
	return f
end}

function UnitHandler:newUnit(groupMemberTbl, unit)
	local newUnit = setmetatable({}, meta_unit)
	
	newUnit:ApplyUnit(groupMemberTbl, unit)
	
	return newUnit;
end

local function iwipe(tbl)
	for i in ipairs(tbl) do
		tbl[i] = nil
	end
end

local groups = {} --these groups are accessible within the FrameHandler - we pass it to it.
function UnitHandler:Regroup()
	iwipe(groups)
	groups[1] = {name = "Tanks"}
	groups[2] = {name = "Heals"}
	groups[3] = {name = "DPS"}
	
	for i,unit in ipairs(units) do
		if unit:IsTank() then
			groups[1][#groups[1]+1] = i;
		elseif unit:IsHeal() then
			groups[2][#groups[2]+1] = i;
		else
			groups[3][#groups[3]+1] = i;
		end
	end
end

function UnitHandler:Reposition()
	--the first time we pass all informative stuff to the FrameHandler and Apply the real Funtion.
	self.Reposition = MRF:GetFrameHandlersReposition(groups) --defined in FrameHandler
	return self:Reposition()
end

function UnitHandler:HideAdditionalFrames()
	for i = #units+1, #frames, 1 do
		frames[i].frame:Show(false, true)
	end
end


function UnitHandler:InitSettings(parent, name)
	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local unitRow = MRF:LoadForm("HalvedRow", parent)
	unitRow:FindChild("Left"):SetText("Time between two unit updates:")
	MRF:applySlider(unitRow:FindChild("Right"), unitOpt, 0.1, 2, 0.1)
	
	local unitQuest = MRF:LoadForm("QuestionMark", unitRow:FindChild("Left"))
	unitQuest:SetTooltip([[Example for a value of one Second: 
	Between the update of unit1 and unit2 will be (about) one second.
	
	Unit updates are far less useful. These just try to make the unit in the frame the correct one. Frequent updates instead retrieve information from this unit and apply them to the frame.]])
	
	MRF:LoadForm("HalvedRow", parent)
	
	local freqRow = MRF:LoadForm("HalvedRow", parent)
	freqRow:FindChild("Left"):SetText("Time for each frequent update:")
	MRF:applySlider(freqRow:FindChild("Right"), freqOpt, 0.1, 2, 0.1)
	
	local eachRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(eachRow:FindChild("Right"), eachOpt, "Instead update all on each frame")
	
	local freqQuest = MRF:LoadForm("QuestionMark", freqRow:FindChild("Left"))
	freqQuest:SetTooltip([[Example for a value of one Second:
	EVERY unit recieves a update (about) each second.
	
	Tick the Checkbox to replace this functionality and make all units get a update each frame. This results in having all units being updated about 60 times each second at 60fps]])
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30 --we want to display six 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
end
