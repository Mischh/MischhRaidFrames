local MRF = Apollo.GetAddon("MischhRaidFrames")
local UnitHandler = {}
Apollo.LinkAddon(MRF, UnitHandler)
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

function MRF:GetUnits()
	return units, UnitHandler
end

MRF:OnceDocLoaded(function()
	Apollo.RegisterEventHandler("Group_Left", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("Group_Join", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("Group_Add", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("Group_Remove", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("Group_MemberFlagsChanged", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("Group_SetMark", "GroupUpdate", UnitHandler)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", UnitHandler)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", UnitHandler)
	Apollo.RegisterEventHandler("NextFrame", "OnUpdate", UnitHandler)
	unitTimer = ApolloTimer.Create(unittime, true, "CheckNextUnit", UnitHandler)
	UnitHandler:GroupUpdate()
end)

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
		UnitHandler.OnUpdate = newVal and UnitHandler.OnUpdate_Every or UnitHandler.OnUpdate_Distant
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
		if lastUnit > max then lastUnit = max end
		
		local now = Apollo.GetTickCount()
		local elapsed = now - lastUpdate
		
		local x = elapsed/freqtime * max
		x = x<max and x or max
		local update = floor(x)
		if update>0 then
			local excesstime = elapsed%(freqtime/max)
			lastUpdate = now-excesstime
		 	local start = lastUnit+1
			if lastUnit+update > max then 
				lastUnit = lastUnit+update-max
				for i = start, max, 1 do
					MRF:PushFrequentUpdate(frames[i], units[i])
				end
				for i = 1, lastUnit, 1 do
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
	local mem = GroupLib.GetGroupMember(i); --can be nil, if we are not in a group, but are testing

	if not units[i] then
		units[i] = self:newUnit(mem, unit) --handles nil-mem by replacing with {}
	else
		units[i]:ApplyUnit(mem, unit) --hanldes nil-mem by staying at the old one.
	end

	self:UpdateIdxName(i, units[i]:GetName())
	
	MRF:PushUnitUpdate(frames[i], units[i])
end

function MRF:PushUnitUpdateForFrameIndex(i)
	if units[i] then
		MRF:PushUnitUpdate(frames[i], units[i])
	end
end

local function iwipe(tbl)
	for i in ipairs(tbl) do
		tbl[i] = nil
	end
end

function UnitHandler:FullUnitUpdate()
	iwipe(units)
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
function FakePrototype:ApplyUnit(groupMember, unit) self.tbl = groupMember or self.tbl; self.unit = unit end
function FakePrototype:UpdateUnit() UnitHandler:UpdateUnit(self:GetMemberIdx()) end
function FakePrototype:GetRealUnit() return rawget(self,"unit") end
function FakePrototype:GetMemberIdx() return self.tbl.nMemberIdx or 1 end
function FakePrototype:GetTargetMarker() return self.tbl.nMarkerId end
function FakePrototype:GetClassId() return self.tbl.eClassId end
function FakePrototype:GetName() return self.tbl.strCharacterName end
function FakePrototype:GetMemberName() return self.tbl.strCharacterName or self:GetName() end
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
function FakePrototype:GetHealingAbsorptionValue() return self.tbl.nHealingAbsorb end
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
function FakePrototype:IsReady() return self.tbl.bReady end
function FakePrototype:HasSetReady() return self.tbl.bHasSetReady end
function FakePrototype:IsDisconnected() return self.tbl.bDisconnected end
function FakePrototype:IsOnline() return self.tbl.bIsOnline end
function FakePrototype:GetPosition() return self.tbl.fakePos end --faked by test-mode!

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
	
	newUnit:ApplyUnit(groupMemberTbl or {}, unit)
	
	return newUnit;
end

local groups = {} --these groups are accessible within the FrameHandler&GroupHandler - we pass it into them.
function UnitHandler:Reposition()
	--the first time we pass all informative stuff to the FrameHandler and Apply the real Funtion.
	self.Reposition = MRF:GetFrameHandlersReposition(groups) --defined in FrameHandler
	return self:Reposition()
end

function UnitHandler:Regroup()
	--with the first call we pass cross-file references into the GroupHandler to recieve the Regroup Method.
	self.Regroup = MRF:GetGroupHandlersRegroup(groups, units, self)
	return self:Regroup()
end

function UnitHandler:HideAdditionalFrames()
	for i = #units+1, #frames, 1 do
		frames[i].frame:Show(false, true)
	end
end

do
	local groupIdx2Name = {} -- [idx] = UnitName and [UnitName] = Idx

	function UnitHandler:UpdateIdxName(idx, name)
		if groupIdx2Name[idx] then
			groupIdx2Name[groupIdx2Name[idx]] = nil
		end
		groupIdx2Name[idx] = name
		groupIdx2Name[name] = idx
	end
	
	function UnitHandler:OnUnitCreated(unit)
		local idx = groupIdx2Name[unit:GetName() or false]
		if idx and units[idx] then
			local member = GroupLib.GetGroupMember(idx)
			units[idx]:ApplyUnit(member, unit)
			MRF:PushUnitUpdateForFrameIndex(idx)
		end
	end
	
	function UnitHandler:OnUnitDestroyed(unit)
		local idx = groupIdx2Name[unit:GetName() or false]
		if idx and units[idx] then
			self:UpdateUnit(idx)
		end
	end

end

function UnitHandler:InitSettings(parent, name)
	local L = MRF:Localize({--English
		["Time between two unit updates:"] = "Time between two unit updates:",
		["ttUnit"] = [[Example for a value of one Second: 
			Between the update of unit1 and unit2 will be (about) one second.
			
			Unit updates are far less useful. These just try to make the unit in the frame the correct one. Frequent updates instead retrieve information from this unit and apply them to the frame.]],
		["Time for each frequent update:"] = "Time for each frequent update:",
		["ttFreq"] = [[Example for a value of one Second:
			EVERY unit recieves a update (about) each second.
			
			Tick the Checkbox to replace this functionality and make all units get a update each frame. This results in having all units being updated about 60 times each second at 60fps]],
		["Instead update all on each frame"] = "Instead update all on each frame",
		
		["ttDebug"] = [[Pushing this Button will add some lines to both of the Update-Types. The first Gathered Error will be entered on the Right of this Button. A Chat-Message will inform you.]],
		["errMsg"] = "MRF: A Update-Error was Catched! See Textbox.",
	}, {--German
		["Time between two unit updates:"] = "Zeit zwischen zwei Spieler-Aktualisierungen",
		["ttUnit"] = [[Beispiel für einen Wert von einer Sekunde: 
			Zwischen den Aktualisierungen von Spieler1 und Spieler2 liegt (etwa) eine Sekunde.
			
			Spieler-Aktualisierungen sind weit uninteressanter, als die regelmäßigen Aktualisierungen, denn Spieler-Aktualisierungen versuchen nur immer den korrekten Spieler seinem Frame zugewiesen zu haben. Regelmäßige Aktualisierungen lesen Informationen aus diesen Spielern aus und weisen diese dem Frame zu.]],
		["Time for each frequent update:"] = "Zeit für jede regelmäßige Aktualisierung:",
		["ttFreq"] = [[Beispiel für einen Wert von einer Sekunde:
			JEDES Frame wird einmal die Sekunde mit Informationen aus dem Spieler aktualisiert.
			
			Platziere den Haken um diese Funktionalität zu entfernen und einfach alle immer zu aktualisieren. Bsp: Bei 60fps würde jedes Frame 60 mal die Sekunde aktualisiert.]],
		["Instead update all on each frame"] = "Stattdessen permanent aktualisieren.",
		
		["ttDebug"] = [[Nach dem drücken dieses Knopfes werden beide Aktualisierungstypen etwas erweitert, um den ersten gefundenen Fehler in die Textbox rechts zu schreiben. Eine Nachricht wird einen Fund Informieren.]],
		["errMsg"] = "MRF: Aktualisierungsfehler gefunden! Siehe Textbox.",
	}, {--French
	})

	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local unitRow = MRF:LoadForm("HalvedRow", parent)
	unitRow:FindChild("Left"):SetText(L["Time between two unit updates:"])
	MRF:applySlider(unitRow:FindChild("Right"), unitOpt, 0.1, 2, 0.1, true, false, true) --textbox: ignore steps, no pos limit
	
	local unitQuest = MRF:LoadForm("QuestionMark", unitRow:FindChild("Left"))
	unitQuest:SetTooltip(L["ttUnit"])
	
	MRF:LoadForm("HalvedRow", parent)
	
	local freqRow = MRF:LoadForm("HalvedRow", parent)
	freqRow:FindChild("Left"):SetText(L["Time for each frequent update:"])
	MRF:applySlider(freqRow:FindChild("Right"), freqOpt, 0.1, 2, 0.1, true, false, true)
	
	local eachRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(eachRow:FindChild("Right"), eachOpt, L["Instead update all on each frame"])
	
	local freqQuest = MRF:LoadForm("QuestionMark", freqRow:FindChild("Left"))
	freqQuest:SetTooltip(L["ttFreq"])
	
	MRF:LoadForm("HalvedRow", parent)
	
	local debugRow = MRF:LoadForm("HalvedRow", parent)
	
	local optDebugBox = MRF:GetOption("DebugText")
	optDebugBox:Set(L["Errors end up here."])
	MRF:applyTextbox(debugRow:FindChild("Right"), optDebugBox)
	optDebugBox:ForceUpdate()
	
	local dbgBtn = MRF:LoadForm("Button", debugRow:FindChild("Left"), {
		ButtonClick = function(self, wndHandler)
			wndHandler:Enable(false)
			
			local unitUpd, freqUpd = MRF.PushUnitUpdate, MRF.PushFrequentUpdate
			MRF.PushUnitUpdate = function(self, frame, unit)
				xpcall(function()
					unitUpd(self, frame, unit)
				end, function(err)
					self.PushUnitUpdate = unitUpd
					self.PushFrequentUpdate = freqUpd
					Print(L["errMsg"])
					optDebugBox:Set(debug.traceback(err))
				end)
			end
			
			MRF.PushFrequentUpdate = function(self, frame, unit)
				xpcall(function()
					freqUpd(self, frame, unit)
				end, function(err)
					self.PushUnitUpdate = unitUpd
					self.PushFrequentUpdate = freqUpd
					Print(L["errMsg"])
					optDebugBox:Set(debug.traceback(err))
				end)
			end
		end
	})
	dbgBtn:SetText(L["Debug"])
	dbgBtn:SetTooltip(L["ttDebug"])
	
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30 --we want to display six 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
end
