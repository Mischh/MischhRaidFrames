--[[]]
require "ICComm"

local GroupHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
MRF.GroupHandler = GroupHandler
Apollo.LinkAddon(MRF, GroupHandler)
local groups = {} --applied in GetGroupHandlersRegroup
local units = {} --applied in GetGroupHandlersRegroup
local tinsert = table.insert

local function deprecated(opt, ...)
	for _, key in ipairs({...}) do
		local opt = MRF:GetOption(opt, key)
		opt:OnUpdate(function(val)
			if val == nil then return end
			opt:Set(nil)
		end)
	end
end

local Options = MRF:GetOption(nil, "Group Handler")
local CharOpt = MRF:GetOption(true, "Groupings")
deprecated(Options, "cache", "saved", "use", "accept", "lead", "publish", "republish") --all of these are deprecated and not anymore in use.
--Possibly remove this with upcoming updates ? What are the chances of somebody still having values, and even if, its 'only' dead data ^^
local optSavedDef = MRF:GetOption(CharOpt, "cache")
local optPermSave = MRF:GetOption(CharOpt, "saved")
local optUse = MRF:GetOption(CharOpt, "use")
local optAcc = MRF:GetOption(CharOpt, "accept")
local optAccFrom = MRF:GetOption(CharOpt, "acceptFrom")
local optPublish = MRF:GetOption(CharOpt, "publish")
local optRepublish = MRF:GetOption(CharOpt, "republish")
local optSortUI = MRF:GetOption(CharOpt, "sortGroupUI")

local optResort = MRF:GetOption(Options, "resort")
local optActAcc = MRF:GetOption(Options, "activationAccept")
local optDeactGrp = MRF:GetOption(Options, "decativationGroup")
MRF:AddMainTab("Group Handler", GroupHandler, "InitSettings")

local L = MRF:Localize({--English
	["Ungrouped"] = "Ungrouped",
	["Tanks"] = "Tanks",
	["Heals"] = "Heals",
	["DPS"] = "DPS",
	["None"] = "None",
	["Role"] = "Role",
	["Class"] = "Class",
	["Name"] = "Name",
	["Sort-method for groups:"] = "Sort-method for groups:",
	["New Group"] = "New Group",
	["Activate grouping on accept from chat"] = "Activate grouping on accept from chat",
	["Deactivate grouping on new group"] = "Deactivate grouping on new group",
	["ttActAccept"] = [[Tick this to make the Addon activate the custom grouping whenever it has recieved a grouping from chat. 
		This respects the options 'Accept' and 'Only Leader' options from within the groupings options!]],
	["ttDeactGrp"] = "Choose this to make the addon decativate custom grouping automatically whenever you join (or create) a group.",
}, {--German
	["Ungrouped"] = "Ungruppiert",
	["Tanks"] = "Tanks",
	["Heals"] = "Heiler",
	["DPS"] = "DDs",
	["None"] = "Keine",
	["Role"] = "Rolle",
	["Class"] = "Klasse",
	["Name"] = "Name",
	["Sort-method for groups:"] = "Gruppen-Sortierungsmethode:",
	["New Group"] = "Neue Gruppe",
	["Activate grouping on accept from chat"] = "Aktiviere bei akzeptierter Publikation",
	["Deactivate grouping on new group"] = "Deaktiviere bei Gruppenbeitritt",
	["ttActAccept"] = [[Setze dies um dem Addon zu erlauben die Gruppierungen zu aktivieren, sobalt es eine Gruppierung aus dem Chat erhalten hat.
		Dies respektiert die Optionen 'Akzeptiere' und 'Nur Leiter' aus den Gruppierungsoptionen!]],
	["ttDeactGrp"] = "Wählen, um jedes mal, wie der Spieler einer neuen Gruppe beitritt (oder eine eröffnet), die Gruppierung zu deaktivieren.",
}, {--French
})

local accept = true --do we accept the leaders groupings?
local activateAccept = false --true is default
local groupDeactivate = false --true is default
local acceptFrom = "lead"
local useUserDef = false
local publishing = false
local republishing = false
local permData = {}
local userdef = {
	--[1] = "Group1" --these Names NEED to be unique, the UI gets problems in other cases.
	--[2] = "Group2" --this Group will end up empty -> not shown.
	--[3] = "Group3"
	--[5] = "Group5" --this Group cant be filled with stuff, scince [4] is missing. ->keep in mind.
	--["PlayerName1"] = 1 --ref to Group1
	--["PlayerName2"] = 1 --the Sort-Order of these is dependant on carbines sorting of units within groups
	--["PlayerName3"] = 3
	--["PlayerName4"] = 4 --this unit will end up in 'Ungrouped', because its Group doesnt exist
	--["PlayerName5"] = 5 --this unit will end up in 'Ungrouped', because its Group wasnt correctly defined.
}

local function wipe(tbl)
	for i in pairs(tbl) do
		tbl[i] = nil
	end
end

local function iwipe(tbl)
	for i in ipairs(tbl) do
		tbl[i] = nil
	end
end


function GroupHandler:Reposition() --overwritten in GetGroupHandlersRegroup
end

function GroupHandler:Regroup()
	if not groups then return end
	if useUserDef then
		GroupHandler:Regroup_User() --dont change to self!
	else
		GroupHandler:Regroup_Default() --dont change to self!
	end
	GroupHandler:Resort()
	if self ~= GroupHandler then
		GroupHandler:DistantUpdate() --far below within the Grouping Settings.
	end
end

function GroupHandler:Regroup_User()
	iwipe(groups)
	for i, name in ipairs(userdef) do
		groups[i] = {["name"] = name}
	end
	local unI = #userdef+1 --ungrouped Index
	groups[unI] = {name = L["Ungrouped"]}
	
	for i, unit in ipairs(units) do
		local n = unit:GetMemberName()
		local grI = userdef[n] or unI --group = the user-defenition, or ungrouped
		local gr = groups[grI] or groups[unI]
		gr[#gr+1] = i
	end
end

function GroupHandler:Regroup_Default()
	iwipe(groups)
	groups[1] = {name = L["Tanks"]}
	groups[2] = {name = L["Heals"]}
	groups[3] = {name = L["DPS"]}
	
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

optPermSave:OnUpdate(GroupHandler, "NewPermanentSaves")
function GroupHandler:NewPermanentSaves(new)
	if type(new) ~= "table" then
		optPermSave:Set({})
	else
		permData = new
	end
end

optSavedDef:OnUpdate(GroupHandler, "NewSavedDef")
function GroupHandler:NewSavedDef(new)
	if type(new) ~= "table" then
		optSavedDef:Set(userdef)
	else
		userdef = new
		self:Regroup()
		self:Reposition() 
		self:DistantUpdate()
	end
end

optAccFrom:OnUpdate(GroupHandler, "UpdateRecieveAccFrom")
function GroupHandler:UpdateRecieveAccFrom(new)
	if new == nil then
		optAccFrom:Set("lead")
	elseif type(new) == "boolean" then --old values
		optAccFrom:Set(new and "lead" or "all")
	else
		if acceptFrom ~= nil and acceptFrom~=new then
			acceptFrom = new
			self:ICCommShareVersion()
		else
			acceptFrom = new
		end
	end
end

optPublish:OnUpdate(GroupHandler, "UpdatePublishing")
function GroupHandler:UpdatePublishing(new)
	if new == nil then
		optPublish:Set(false)
	else
		if publishing == false and new == true then
			publishing = new
			if useUserDef then
				self:ICCommShareGroup()
			else
				self:ICCommShareDeact()
			end
		else
			publishing = new
		end
	end
end

optRepublish:OnUpdate(GroupHandler, "UpdateRepublishing")
function GroupHandler:UpdateRepublishing(new)
	if new == nil then
		optRepublish:Set(false)
	else
		republishing = new
	end
end

optActAcc:OnUpdate(GroupHandler, "UpdateActivateAccept")
function GroupHandler:UpdateActivateAccept(val)
	if type(val) ~= "boolean" then
		optActAcc:Set(true)
	else
		activateAccept = val
	end
end


optDeactGrp:OnUpdate(GroupHandler, "UpdateDeactivateGroup")
function GroupHandler:UpdateDeactivateGroup(val)
	if type(val) ~= "boolean" then
		optDeactGrp:Set(true)
	else
		groupDeactivate = val
	end
end

function GroupHandler:VRFSerialize(t) --use VinceRaidFrames Serializing and Deserializing to be compatible.
	local type = type(t)
	if type == "string" then
		return ("%q"):format(t)
	elseif type == "table" then
		local tbl = {"{"}
		local indexed = #t > 0
		local hasValues = false
		for k, v in pairs(t) do
			hasValues = true
			tinsert(tbl, indexed and self:VRFSerialize(v) or "[" .. self:VRFSerialize(k) .. "]=" .. self:VRFSerialize(v) )
			tinsert(tbl, ",")
		end
		if hasValues then
			tbl[#tbl] = nil
		end
		tinsert(tbl, "}")
		return table.concat(tbl)
	end
	return tostring(t)
end

function GroupHandler:VRFDeserialize(str)
	if type(str) ~= "string" then
		return nil
	end
	local func = loadstring("return " .. str)
	if not func then
		return nil
	end
	setfenv(func, {}) --not sure about this one... might not be needed.
	local success, value = pcall(func)
	return value	
end

function GroupHandler:GetNameIdTable() --VinceRaidFrames (adapted)
	local memberNames = {}
	local memberNameToId = {}
	for _, unit in ipairs(units) do
		tinsert(memberNames, unit:GetMemberName())
	end
	-- Sorted member names for short unique ids across clients!
	table.sort(memberNames)
	for i, name in ipairs(memberNames) do --this is just a array -> map method.
		memberNameToId[name] = i
	end
	
	return memberNameToId, memberNames
end

function GroupHandler:GetVRFLayout()
	local idTbl = self:GetNameIdTable()
	
	local groups = setmetatable({}, {__index = function(t,k) t[k] = {}; return t[k] end})
	for i, v in pairs(userdef) do --group all members into their groups.
		if type(i) == "number" then
			groups[i][0] = v
		else
			tinsert(groups[v], i)
		end
	end
	
	local layout = {}
	for _, grp in ipairs(groups) do --add the groups in the correct order into the layout - replace the names with IDs.
		if grp[0] then --if the Group has a name, we will publish it.
			tinsert(layout, grp[0])
			for _, name in ipairs(grp) do
				if idTbl[name] then --if the name does not have a ID -> scrap the name.
					tinsert(layout, idTbl[name])
				end
			end
		end
	end
	
	return layout
end

local shareKey = "}=>"
function GroupHandler:PublishGroup()
	local layout = self:GetVRFLayout()
	local str = shareKey..self:VRFSerialize(layout)
	ChatSystemLib.GetChannels()[ChatSystemLib.ChatChannel_Party]:Send(str)
end

function GroupHandler:PublishReadable()
	local _, idTbl = self:GetNameIdTable()
	local channel = ChatSystemLib.GetChannels()[ChatSystemLib.ChatChannel_Party]
	
	local layout = self:GetVRFLayout()
	--this layout looks like this:
	--	{"GroupName", 5, 3, 7, "GroupName2", "GroupName3", 1}
	--where the numbers are IDs translating to names.
	
	--We want to output: (continuing Example, each Comment is a line.)
		-- 'GroupName: MembrName5, MembrName3, MembrName7.'
		-- 'GorupName3: MembrName1.
	--as you see: 'GroupName2' was not output.
	
	--Split the layout, leaving a table with all Members of the next published Group.
	--Once we find a new GroupName, we push out the last Group. (if it wasnt empty)
	local grpName = nil
	local grp = {}
	for i, v in ipairs(layout) do
		if type(v) == "number" and idTbl[v] then
			table.insert(grp, idTbl[v])
		elseif type(v) == "string" then --next Group -> push old, if not empty.
			if #grp>0 and grpName then
				channel:Send(grpName..": "..table.concat(grp, ", ")..".")
			end
			--start next group:
			grp = {}
			grpName = v
		end
	end
	
	--the last group was not pushed, if its not empty -> do so.
	if #grp>0 and grpName then
		channel:Send(grpName..": "..table.concat(grp, ", ")..".")
	end
end

function GroupHandler:ChangedGroupLayout()
	if useUserDef and publishing then
		self:ICCommShareGroup()
	end
end

do
	local shareTimer = nil
	local shareRequested = false
	function GroupHandler:ICCommShareGroup(srcName)
		if self.channel and publishing then
			if srcName then
				local msg = self:VRFSerialize({layout = self:GetVRFLayout(), source = srcName})
				self.channel:SendMessage(msg)
			elseif not shareTimer then
				local msg = self:VRFSerialize({layout = self:GetVRFLayout()})
				self.channel:SendMessage(msg)
				shareTimer = ApolloTimer.Create(3, false, "OnShareTimer", self)
			else
				shareRequested = true
			end
		end
	end

	function GroupHandler:ICCommShareDeact(srcName)
		if self.channel and publishing then
			if srcName then
				self.channel:SendMessage(self:VRFSerialize({defaultGroups = true, source = srcName}))
			elseif not shareTimer then
				self.channel:SendMessage(self:VRFSerialize({defaultGroups = true}))
				shareTimer = ApolloTimer.Create(3, false, "OnShareTimer", self)
			else
				shareRequested = true
			end
		end
	end
	
	function GroupHandler:OnShareTimer()
		shareTimer = nil
		if shareRequested then
			shareRequested = false
			if useUserDef then --share group
				local msg = self:VRFSerialize({layout = self:GetVRFLayout()})
				self.channel:SendMessage(msg)
			else -- share deactivation
				self.channel:SendMessage(self:VRFSerialize({defaultGroups = true}))
			end
		end
	end
	
	optPublish:OnUpdate(function(publish) 
		if shareTimer and not publish then
			shareTimer:Stop()
			GroupHandler:OnShareTimer()
		end	
	end)
end

function GroupHandler:ICCommShareVersion()
	self.addonVersionAnnounceTimer = nil
	
	if self.channel and accept then --only ask for stuff, if we actually accept stuff, duh?
		if acceptFrom == "lead" then --if we only accept messages from our leader -> send him private message.
			local leader = self:GetLead()
			if not leader then return end
			local leadName = leader:GetMemberName()
			if not leadName then return end
			--we are compatible with this version of VRF, dont use any other.
			self.channel:SendPrivateMessage(leadName, self:VRFSerialize({version = "0.17.2"}))
		else --might want to remove this later, this could fuck up stuff rly bad.
			self.channel:SendMessage(self:VRFSerialize({version = "0.17.2"}))
		end
	end
end

-- tbl = {"GroupName1", idOfMemberInGroup1, "GroupName2", idOfMemberInGroup2, idOfMemberInGroup2, ...}
function GroupHandler:ImportGroup(tbl) 
	local _, idTbl = self:GetNameIdTable()
	wipe(userdef)
	
	local grId = 0
	
	for _, v in ipairs(tbl) do
		if type(v) == "string" then
			grId = grId+1
			userdef[grId] = v
		else --number (aka ID)
			local n = idTbl[v]
			if n then
				userdef[n] = grId
			end
		end
	end
end

local matchString = "^"..shareKey.."(.+)$"
function GroupHandler:OnChatMessage(channelSource, tMessageInfo)
	if not accept then
		return
	end
	
	if channelSource:GetType() ~= ChatSystemLib.ChatChannel_Party then
		return
	end
	
	local msg = {}
	for i, segment in ipairs(tMessageInfo.arMessageSegments) do
		tinsert(msg, segment.strText)
	end
	local strMsg = table.concat(msg, "")
	strMsg = strMsg:match(matchString)
	if not strMsg then
		return
	end
	
	local layout = self:VRFDeserialize(strMsg)
	
	self:RecievedGroupLayout(tMessageInfo.strSender, layout)
end

function GroupHandler:RecievedGroupLayout(srcName, layout)
	if not self:CheckAccepting(srcName) then
		return
	end	

	local old = publishing
	publishing = false --prevent the addon from re-publishing at this point (done seperate)
	
	self:ImportGroup(layout)
	
	if useUserDef then
		self:Regroup()
		self:Reposition()
		self:DistantUpdate()
	elseif activateAccept then
		optUse:Set(true) 
		--[[contains:
			useUserDef = true
			self:DistantUpdate()
			self:Regroup()
			self:Reposition()
		--]]
	else
		self:DistantUpdate() --at least update GroupDisplay
	end
	
	publishing = old
end

function GroupHandler:RecievedDeactRequest(srcName)
	if activateAccept and self:CheckAccepting(srcName) then
		local old = publishing
		publishing = false --prevent the addon from re-publishing at this point (done seperate)
	
		optUse:Set(false)
		
		publishing = old
	end
end

function GroupHandler:GroupJoined()
	if groupDeactivate then
		optUse:Set(false)
	end
	if accept then
		if not self.addonVersionAnnounceTimer then
			self.addonVersionAnnounceTimer = ApolloTimer.Create(1, false, "ICCommShareVersion", self)
		end
	end
end

MRF:OnceDocLoaded(function()
	GroupHandler:JoinICCommChannel() --VRF had a 5sec timer here, removed it..
	Apollo.RegisterEventHandler("Group_Join", "GroupJoined", GroupHandler)
	Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", GroupHandler)
end)

function MRF:GroupHandler_OnICCommJoin(...)
end
function MRF:GroupHandler_OnICCommSendMessageResult(...)
end
function MRF:GroupHandler_OnICCommThrottled(...)
end

function GroupHandler:JoinICCommChannel()
	self.timerJoinICCommChannel = nil
	--we want to sync with VRF
	self.channel = ICCommLib.JoinChannel("VinceRF", ICCommLib.CodeEnumICCommChannelType.Group)
	self.channel:SetJoinResultFunction("GroupHandler_OnICCommJoin", MRF)
	
	if not self.channel:IsReady() then
		self.timerJoinICCommChannel = ApolloTimer.Create(3, false, "JoinICCommChannel", self)
	else
		self.channel:SetReceivedMessageFunction("GroupHandler_OnICCommMessageReceived", MRF)
		self.channel:SetSendMessageResultFunction("GroupHandler_OnICCommSendMessageResult", MRF)
		self.channel:SetThrottledFunction("GroupHandler_OnICCommThrottled", MRF)
		
		self.addonVersionAnnounceTimer = ApolloTimer.Create(2, false, "ICCommShareVersion", self)
	end
end

function MRF:GroupHandler_OnICCommMessageReceived(...)
	GroupHandler:OnICCommMessageReceived(...)
end

do
	local delayTable = {} --table of all messages fired while unable to properly handle them.
	function GroupHandler:OnICCommMessageDelayTimer()
		self.ICCommmMessageDelayTimer = nil
		local copy = delayTable
		delayTable = {}
		for _, t in ipairs(delayTable) do
			self:OnICCommMessageReceived(t[1], t[2], t[3])
		end
	end
	
	function GroupHandler:OnICCommMessageReceived(channel, strMessage, idMessage) --idMessage a Name?	
		local player = GameLib.GetPlayerUnit()
		if not player then
			table.insert(delayTable, {channel, strMessage, idMessage})
			self.ICCommmMessageDelayTimer = self.ICCommmMessageDelayTimer or ApolloTimer.Create(0.5, false, "OnICCommMessageDelayTimer", self)
			return
		end
		local playerName = player:GetName()
		local message = self:VRFDeserialize(strMessage)
		if type(message) ~= "table" or message.source == playerName then
			return
		end
		if type(message.rw) == "table" and #message.rw > 0 and self:IsLead(idMessage) then
			--a RaidWarning? Well - okay.... Do whatever VRF defines xD
			Event_FireGenericEvent("StoryPanelDialog_Show", GameLib.CodeEnumStoryPanel.Urgent, message.rw, 6)
		end
		
		if message.version then
			--we dont save the version, because i do not know what would change..
			--but VRF shares its GroupLayout, whenever somebody shares his version with him.
			if publishing and useUserDef then
				self:ICCommShareGroup()
			end
			return
		end
		
		if not accept then 
			return 
		end
		
		if message.layout then
			self:RecievedGroupLayout(idMessage, message.layout)
			if republishing and self:IsLead(playerName) then
				self:ICCommShareGroup(idMessage)
			end
		elseif message.defaultGroups then
			self:RecievedDeactRequest(idMessage)
			if republishing and self:IsLead(playerName) then
				self:ICCommShareDeact(idMessage)
			end
		end
	end

end

function GroupHandler:IsLead(name)
	for _, unit in ipairs(units) do
		if unit:IsLeader() then
			if unit:GetMemberName() == name then
				return true --is leader and has name.
			else
				return false --is leader, but hasnt name.
			end
		elseif unit:GetMemberName() == name then
			return false --isnt leader, but has name.
		end
	end
	return false --no leader in group?! --nobody with the name?! --wtf?!
end

function GroupHandler:IsLeadOrAssist(name)
	for _, unit in ipairs(units) do
		if unit:GetMemberName() == name then
			if unit:IsRaidAssistant() then
				return true
			elseif unit:IsLeader() then
				return true
			else
				return false
			end
		end
	end
	return false --did not find the name.
end

function GroupHandler:CheckAccepting(name)
	if acceptFrom == "lead" then
		return self:IsLead(name)
	elseif acceptFrom == "assist" then
		return self:IsLeadOrAssist(name)
	else
		return true
	end
end

function GroupHandler:GetLead()
	for _, unit in ipairs(units) do
		if unit:IsLeader() then
			return unit
		end
	end
	return nil --no leader? no group?
end

function MRF:GetGroupHandlersRegroup(unithandler_groups, unithandler_units, UnitHandler)
	groups = unithandler_groups
	units = unithandler_units
	
	function GroupHandler:Reposition(...)
		return UnitHandler:Reposition(...)
	end
	
	return GroupHandler.Regroup
end

local function append(tar, src, ...)
	if not src then return tar end
	for _, v in ipairs(src) do
		tinsert(tar, v)
	end
	return append(tar, ...)
end

optResort:OnUpdate(GroupHandler, "UpdateResort")
function GroupHandler:UpdateResort(new)
	if not new then
		GroupHandler.Resort = GroupHandler.Resort_None
	else
		GroupHandler.Resort = GroupHandler["Resort_"..new]
	end
	GroupHandler:Resort()
	GroupHandler:Reposition()
end

function GroupHandler:Resort() --== Resort_None
end

function GroupHandler:Resort_Role()
	for gidx, group in ipairs(groups) do
		local t, h, d = {}, {}, {}
		for _, idx in ipairs(group) do
			if units[idx]:IsTank() then
				tinsert(t,idx)
			elseif units[idx]:IsHeal() then
				tinsert(h,idx)
			else
				tinsert(d,idx)
			end
		end
		groups[gidx] = append(t, h, d)
		groups[gidx].name = group.name
	end
end

function GroupHandler:Resort_Class()
	for gidx, group in ipairs(groups) do
		local t = {[GameLib.CodeEnumClass.Warrior] = {}, [GameLib.CodeEnumClass.Engineer] = {}, [GameLib.CodeEnumClass.Esper] = {}, [GameLib.CodeEnumClass.Medic] = {}, [GameLib.CodeEnumClass.Stalker] = {}, [GameLib.CodeEnumClass.Spellslinger] = {}}
		for _, idx in ipairs(group) do
			local id = units[idx]:GetClassId()
			tinsert(t[id], idx)
		end
		groups[gidx] = append(t[GameLib.CodeEnumClass.Warrior], t[GameLib.CodeEnumClass.Engineer], 
							t[GameLib.CodeEnumClass.Esper], t[GameLib.CodeEnumClass.Medic], 
							t[GameLib.CodeEnumClass.Stalker], t[GameLib.CodeEnumClass.Spellslinger])
		groups[gidx].name = group.name
	end
end

function GroupHandler:Resort_Name()
	for gidx, group in ipairs(groups) do
		local name2id = {}
		for i, idx in ipairs(group) do
			group[i] = units[idx]:GetMemberName()
			name2id[group[i]] = idx
		end
		table.sort(group) -- sort alphabetically
		for i, n in ipairs(group) do
			group[i] = name2id[n]
		end
	end
end

function GroupHandler:Resort_None()
end

function GroupHandler:InitSettings(parent, name)
	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")
	
	local function trans(x)
		if not x then 
			return L["None"]
		else
			return L[x]
		end
	end
	
	local sortRow = MRF:LoadForm("HalvedRow", parent)
	sortRow:FindChild("Left"):SetText(L["Sort-method for groups:"])
	MRF:applyDropdown(sortRow:FindChild("Right"), {false, "Role", "Class", "Name"}, optResort, trans)
	
	MRF:LoadForm("HalvedRow", parent) --spacing
	
	local actRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(actRow:FindChild("Right"), optActAcc, L["Activate grouping on accept from chat"])
	local deaRow = MRF:LoadForm("HalvedRow", parent)
	MRF:applyCheckbox(deaRow:FindChild("Right"), optDeactGrp, L["Deactivate grouping on new group"])
	
	MRF:LoadForm("QuestionMark", actRow:FindChild("Left")):SetTooltip(L["ttActAccept"])
	MRF:LoadForm("QuestionMark", deaRow:FindChild("Left")):SetTooltip(L["ttDeactGrp"])

	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	Options:ForceUpdate()
end

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MRF: Grouping %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
local form = nil
local grOptions = MRF:GetOption("Group Handler")
local optGrName = MRF:GetOption(grOptions, "name")
local optGrIdx = MRF:GetOption(grOptions, "index")
local optSName = MRF:GetOption(grOptions, "saveName")
local optLoad = MRF:GetOption(grOptions, "load")
local optRemove = MRF:GetOption(grOptions, "remove")
local handler = {}
local ungrHandler = {} --ungrouped List		--ListItem creation within the Init!
local grpdHandler = {} --grouped List		--ListItem creation within the Init!
local grouHandler = {} --groups List		--ListItem creation within the Init!
local switching = false

optUse:OnUpdate(handler, "UpdateUse")
optAcc:OnUpdate(handler, "UpdateAccept")
optGrName:OnUpdate(handler, "UpdateGrName")
optGrIdx:OnUpdate(handler, "UpdateGroupIndex")
optLoad:OnUpdate(handler, "LoadIndex")
optRemove:OnUpdate(handler, "RemoveIndex")
optSortUI:OnUpdate(handler, "UpdateSortUI")

local classColor = unpack(MRF:HasModule("Class Colors"):GetColorTable())
local name2color = {}
local name2text = {}
local sortedNames = {}
local nocolor = ApolloColor.new("FF666666")

function handler:Update(onlyUI)
	if not onlyUI then 
		GroupHandler:Regroup()
		GroupHandler:Reposition()
	end
	
	if not form then return end
	
	self:ReselectGroup() --this will end up in redrawing the selected Group & the Groups List.
	
	ungrHandler:Redraw() --redraw the Ungrouped ppl aswell.
end

function GroupHandler:DistantUpdate()
	if not units then return end
	
	name2color = {}
	name2text = {}
	for i, unit in ipairs(units) do
		local n = unit:GetMemberName()
		local pre = (unit:IsTank() and "T" or unit:IsHeal() and "H" or "D")..": "
		local c = classColor:Get(unit)
		
		name2color[n] = c
		name2text[n] = pre..n
	end
	
	self:SortUINames()
	
	handler:Update(true)
end

local tinsert = table.insert
function GroupHandler:SortUINames()
	if not units then return end
	
	local sort = optSortUI:Get()
	if sort == "Name" then
		local tbl = {}
		for _, unit in ipairs(units) do
			tinsert(tbl, unit:GetMemberName())
		end
		for idx in pairs(userdef) do
			if type(idx) == "string" and not name2text[idx] then
				tinsert(tbl, idx)
			end
		end
		table.sort(tbl)
		
		sortedNames = tbl
		return tbl
	elseif sort == "Class" then
		local t = {[GameLib.CodeEnumClass.Warrior] = {}, [GameLib.CodeEnumClass.Engineer] = {}, [GameLib.CodeEnumClass.Esper] = {}, [GameLib.CodeEnumClass.Medic] = {}, [GameLib.CodeEnumClass.Stalker] = {}, [GameLib.CodeEnumClass.Spellslinger] = {}}
		for _, unit in ipairs(units) do
			local id = unit:GetClassId()
			tinsert(t[id], unit:GetMemberName())
		end
		
		local noclass = {}
		for idx in pairs(userdef) do
			if type(idx) == "string" and not name2text[idx] then
				tinsert(noclass, idx)
			end
		end
		
		sortedNames = append(t[GameLib.CodeEnumClass.Warrior], t[GameLib.CodeEnumClass.Engineer], 
							t[GameLib.CodeEnumClass.Esper], t[GameLib.CodeEnumClass.Medic], 
							t[GameLib.CodeEnumClass.Stalker], t[GameLib.CodeEnumClass.Spellslinger], noclass)
		return sortedNames
	elseif sort == "Role" then
		local tanks , heals, dps = {},{},{}
		for _, unit in ipairs(units) do
			tinsert(unit:IsTank() and tanks or unit:IsHeal() and heals or dps, unit:GetMemberName())
		end
		
		local norole = {}
		for idx in pairs(userdef) do
			if type(idx) == "string" and not name2text[idx] then
				tinsert(norole, idx)
			end
		end
		sortedNames = append(tanks, heals, dps, norole)
		return sortedNames
	else
		local tbl = {}
		for _, unit in ipairs(units) do
			tinsert(tbl, unit:GetMemberName())
		end
		for idx in pairs(userdef) do
			if type(idx) == "string" and not name2text[idx] then
				tinsert(tbl, idx)
			end
		end
		
		sortedNames = tbl
		return sortedNames
	end

end

function handler:ReselectGroup()
	--reselect the old Group - or select the first - or select nil
	local name = optGrName:Get()

	if name then
		for i, n in ipairs(userdef) do
			if n==name then
				return optGrIdx:Set(i)
			end
		end
	end
	
	if userdef[1] then
		return optGrIdx:Set(1)
	else
		return optGrIdx:Set(nil)
	end
end

function handler:OnCancel() --Pressed the X button
	form:Show(false, false)
end

function handler:ResetGroups() --Pressed 'Reset All'
	wipe(userdef)
	self:Update()
	GroupHandler:ChangedGroupLayout()
end

local function findUniqueName(i)
	i = i or 0
	local n = L["New Group"]..(i>0 and " "..i or "")
	for _, name in ipairs(userdef) do
		if name == n then
			return findUniqueName(i+1)
		end
	end
	return n;
end
GroupHandler.GetUniqueGroupName = findUniqueName

function handler:AddGroup() --Pressed 'Add'
	userdef[#userdef+1] = findUniqueName()
	optGrIdx:Set(#userdef)
	GroupHandler:ChangedGroupLayout()
end

function handler:RemoveGroup() --Pressed 'Remove'
	local idx = optGrIdx:Get()
	if idx then 
		handler:MoveFromGroup()
		table.remove(userdef, idx)
	end
	for i,v in pairs(userdef) do
		if type(v) == "number" and v>idx then
			userdef[i] = v-1
		end
	end
	self:Update()
	GroupHandler:ChangedGroupLayout()
end

function handler:MoveToGroup() --Pressed '-->'
	local idx = optGrIdx:Get()
	if idx then
		for i, n in ipairs(sortedNames) do
			userdef[n] = userdef[n] or idx
		end
	end
	self:Update()
	GroupHandler:ChangedGroupLayout()
end

function handler:MoveFromGroup() --Pressed '<--'
	local idx = optGrIdx:Get()
	if idx then
		for k, i in pairs(userdef) do
			if i == idx then
				userdef[k] = nil
			end
		end 
	end
	self:Update()
	GroupHandler:ChangedGroupLayout()
end

function handler:ToggleSaveMenu(btn) --Pressed 'Load/Save'
	self.saveMenu:Show(btn:IsChecked())
end

function handler:PublishGroup()
	GroupHandler:PublishGroup()
end

function handler:PublishReadable()
	GroupHandler:PublishReadable()
end

function handler:UpdateUse(use) -- called by optUse:ForceUpdate()
	if use == nil then
		optUse:Set(false)
	else
		if useUserDef ~= nil and useUserDef~=use then
			useUserDef = use
			if publishing then
				if use then
					GroupHandler:ICCommShareGroup()
				else
					GroupHandler:ICCommShareDeact()
				end
			end
		else
			useUserDef = use
		end
		handler:Update()
	end
end

function handler:UpdateAccept(acc) -- called by optAcc:ForceUpdate()
	if acc == nil then
		optAcc:Set(true)
	else
		if accept == false and acc == true then
			accept = true
			GroupHandler:ICCommShareVersion()
		else
			accept = acc
		end
	end
end

local oldName = nil
function handler:UpdateGrName(name) -- called by optGrName:ForceUpdate()
	local idx = optGrIdx:Get()
	if idx and not switching and oldName ~= name then
		oldName = name
		for i, n in ipairs(userdef) do --check for name unique -> if it isnt: just apply the old one.
			if n == name then
				return optGrName:Set(userdef[idx])
			end
		end
		
		userdef[idx] = name
		grouHandler[idx]:SetText(grouHandler:GetText(idx))
		self:Update()
		GroupHandler:ChangedGroupLayout()
	end
end

function handler:UpdateGroupIndex(idx) -- called by optGrIdx:ForceUpdate()
	switching = true 
	if idx then --set the groupName
		optGrName:Set(userdef[idx])
	else
		optGrName:Set("")
	end
	grouHandler:Redraw()
	grpdHandler:Redraw()
	switching = false
end

local function copy(tbl, target)
	target = target or {}
	for i,v in pairs(tbl) do
		target[i] = v
	end
	return target
end

function handler:SaveThis(button)
	local name = optSName:Get()
	if not name or name:gsub("^%s+","") == "" then return end
	
	local idx = #permData+1
	for i, t in ipairs(permData) do
		if t.name == name then
			idx = i
			break;
		end
	end
	
	permData[idx] = permData[idx] or {["name"] = name}
	permData[idx].data = copy(userdef)
end

function handler:LoadIndex(idx)
	if idx and permData[idx] then
		local name = permData[idx].name
		wipe(userdef)
		copy(permData[idx].data, userdef)
		optSName:Set(name)
		optLoad:Set(nil)
		self:Update()
		GroupHandler:ChangedGroupLayout()
	end
end

function handler:RemoveIndex(idx)
	if idx and permData[idx] then
		table.remove(permData, idx)
		optRemove:Set(nil)
	end
end

function handler:UpdateSortUI()
	GroupHandler:SortUINames()
	handler:Update(true)
end

function grouHandler:GetText(idx)
	local num = 0
	for i, v in pairs(userdef) do
		if v == idx then
			num = num+1
		end 
	end
	return userdef[idx].." ("..num..")"
end

function grouHandler:Redraw()
	for i, name in ipairs(userdef) do
		self[i]:SetText(self:GetText(i))
		self[i]:SetCheck(false) --the one that is selected will be selected below
	end
	self.parent:ArrangeChildrenVert()
	self.parent:SetAnchorOffsets(0,0,0,#userdef * 25)
	self.parent:GetParent():RecalculateContentExtents()
	
	local idx = optGrIdx:Get()
	if idx then
		self[idx]:SetCheck(true)
	end
end

function grouHandler:GroupSelected(button)
	if switching then return end
	optGrIdx:Set(button:GetData())
end

function grouHandler:GroupUp(wndControl, wndHandler)
	if wndControl ~= wndHandler then return end
	local src = wndControl:GetParent():GetData() --the index the group is at right now.
	local tar = src-1; if tar<1 then tar=#userdef end
	
	userdef[src], userdef[tar] = userdef[tar], userdef[src] --switch the names
	for i,v in pairs(userdef) do
		if v == src then
			userdef[i] = tar
		elseif v == tar then
			userdef[i] = src
		end
	end
	
	handler:Update()
	GroupHandler:ChangedGroupLayout()
end

function grouHandler:GroupDown(wndControl, wndHandler)
	if wndControl ~= wndHandler then return end
	local src = wndControl:GetParent():GetData() --the index the group is at right now.
	local tar = src+1; if tar>#userdef then tar=1 end
	
	userdef[src], userdef[tar] = userdef[tar], userdef[src] --switch the names
	for i,v in pairs(userdef) do
		if v == src then
			userdef[i] = tar
		elseif v == tar then
			userdef[i] = src
		end
	end
	
	handler:Update()
	GroupHandler:ChangedGroupLayout()
end

function grpdHandler:GetText(name)
	return name2text[name] or name
end

function grpdHandler:GetTextColor(name)
	return name2color[name] or nocolor
end 

function grpdHandler:Redraw()
	local idx = optGrIdx:Get()
	
	local i = 0
	if idx then
		for _, name in ipairs(sortedNames) do
			if userdef[name] == idx then
				i = i+1
				self[i]:SetText(self:GetText(name))
				self[i]:SetTextColor(self:GetTextColor(name))
				self[i]:SetData(name)
			end
		end
	end
	
	self.parent:ArrangeChildrenVert()
	self.parent:SetAnchorOffsets(0,0,0, i*25)
	self.parent:GetParent():RecalculateContentExtents()
end

function grpdHandler:UnitSelected(button)
	local name = button:GetData()
	userdef[name] = nil
	
	handler:Update()
	
	GroupHandler:ChangedGroupLayout()
end

function ungrHandler:GetText(n)
	return name2text[n] or n
end

function ungrHandler:GetTextColor(n)
	return name2color[n] or nocolor
end 

function ungrHandler:Redraw()
	local i = 0
	
	for _, name in ipairs(sortedNames) do
		if not userdef[name] then
			i = i+1
			self[i]:SetText(self:GetText(name))
			self[i]:SetTextColor(self:GetTextColor(name))
			self[i]:SetData(name)
		end
	end
	
	self.parent:ArrangeChildrenVert()
	self.parent:SetAnchorOffsets(0,0,0, i*25)
	self.parent:GetParent():RecalculateContentExtents()
end

function ungrHandler:UnitSelected(button)
	local idx = optGrIdx:Get()
	if not idx then return end
	
	local n = button:GetData()
	
	userdef[n] = idx
	
	handler:Update()
	
	GroupHandler:ChangedGroupLayout()
end

function MRF:InitGroupForm()
	if form then return form:Show(true, false) end
	
	local _L = L
	local L = MRF:Localize({--English
		["Title"] = "MRF: Grouping",
		["SaveTitle"] = "Save and Load",
		["Activate"] = "Activate",
		["Accept:"] = "Accept:",
		["Lead only"] = "Lead only",
		["ttActivated"] = "Use these Settings instead of the default tank-heal-dps groups.",
		["ttAccept"] = "Accept published Settings of other players. If you have problems recieving groupings, you may try to /reloadui. The connection may not work the first time.",
		["ttFrom"] = "Published settings will only be imported from this group.",
		["ttGroupName"] = [[Note: Every groups name needs to be unique.]],
		["ttPublish"] = [[Publishes your current settings to the group.
			This and other addons may only accept the settings, if you are the leader of the group.
			The addon can only publish settings for units, which are currently in your group. Make sure they are.]],
		["ttRepublish"] = "Publish accepted settings you recieved. This only works, if you are the leader and the options are set to publish.",
		["select one"] = "select one",
		["Publish"] = "Publish",
		["Ungrouped:"] = "Ungrouped:",
		["Add"] = "Add",
		["Groups:"] = "Groups:",
		["Rem."] = "Rem.",
		["Reset All"] = "Reset All",
		["Save/Load"] = "Save/Load",
		["Save As:"] = "Save As:",
		["Load this:"] = "Load this:",
		["Remove this:"] = "Remove this:",
		["ttToGroup"] = "Move all from ungrouped to the selected group.",
		["ttFromGroup"] = "Remove all from the selected group.",
		["ttAdd"] = "Add a new group.",
		["ttRemove"] = "Remove the selected group.",
		["ttReset"] = "Remove all groups.",
		["ttPubChat"] = "Publish your current Settings to chat. To be readable for other players addons.",
		["ttOutput"] = "Share a readable version of your Groups throught Chat.",
		["lead"] = "Leader",
		["assist"] = "Assistants",
		["all"] = "all",
	}, {--German
		["Title"] = "MRF: Gruppierung",
		["SaveTitle"] = "Speichern und Laden",
		["Activate"] = "Aktiviert",
		["Accept:"] = "Akzeptiere:",
		["Lead only"] = "Nur Leiter",
		["ttActivated"] = "Nutze diese Einstellungen, anstelle der normalen Tank-Heiler-DD Gruppen. Falls scheinbar keine Daten empfangen werden, sollte ein /reloadui versucht werden. Die Verbindung funktioniert nicht immer beim ersten mal.",
		["ttAccept"] = "Akzeptiere Einstellungen von anderen Spielern.",
		["ttFrom"] = "Akzeptiere nur die Einstellungen dieser Gruppe.",
		["ttGroupName"] = [[Achtung: Jede Gruppe muss einen einzigartigen Namen haben!]],
		["ttPublish"] = [[Publiziert deine momentanen Gruppen für andere Spieler.
			Dieses, sowie andere AddOns könnten möglicherweise diese Publikation nur akzeptieren, falls du der Gruppenleiter bist.
			Dem Addon ist es nur möglich die Einstellungen für momentane Mitglieder der Gruppe zu Teilen.]],
		["ttRepublish"] = "Publiziere erhaltene settings als deine. Dies passiert nur, falls du Leiter bist und 'Publizieren' aktiv hast.",
		["select one"] = "wähle eine",
		["Publish"] = "Publizieren",--
		["Republish"] = "Republizieren",
		["Ungrouped:"] = "Ungruppiert:",--
		["Add"] = "+",--
		["Groups:"] = "Gruppen:",--
		["Rem."] = "-",--
		["Reset All"] = "Zurücksetzen",--
		["Save/Load"] = "Speichern",--
		["Save As:"] = "Speichern als:",--
		["Load this:"] = "Lade diese:",--
		["Remove this:"] = "Lösche diese:",--
		["Publish in Chat"] = "Publiz. im Chat",
		["Output Readable"] = "Lesbar Ausgeben",
		["ttToGroup"] = "Füge alle Ungruppierten der momentan ausgewählten Gruppe hinzu.",
		["ttFromGroup"] = "Entferne alle aus der ausgewählten Gruppe.",
		["ttAdd"] = "Füge eine neue Gruppe hinzu.",
		["ttRemove"] = "Entferne die ausgewählte Gruppe.",
		["ttReset"] = "Entferne alle Gruppen.",
		["ttPubChat"] = "Publiziere deine momentanen Gruppen über den Chat, um von den AddOns anderer Spieler gelesen zu werden.",
		["ttOutput"] = "Teile eine lesbare Version deiner Gruppen über den Chat.",
		["from "] = "von ",
		["lead"] = "Leiter",
		["assist"] = "Assistenten",
		["all"] = "allen",
		["Sort Grouping Frame:"] = "Gruppierungsfenster sortieren:",
	}, {--French
	})
	
	local function transAccept(key) return L["from "]..(L[key or ""] or "").."." end
	
	form = self:LoadForm("GroupingForm", nil, handler)
	handler.saveMenu = form:FindChild("SavesFrame")
	ungrHandler.parent = form:FindChild("Ungrouped:Items")
	grpdHandler.parent = form:FindChild("Grouped:Items")
	grouHandler.parent = form:FindChild("Groups:Items")
	
	MRF:applyCheckbox(form:FindChild("SideTab:Checkbox_Activated"), optUse, L["Activate"]).form:SetTooltip(L["ttActivated"])
	MRF:applyCheckbox(form:FindChild("SideTab:Checkbox_Accept"), optAcc, L["Accept:"]).form:SetTooltip(L["ttAccept"])
	MRF:applyDropdown(form:FindChild("SideTab:Dropdown_From"), {"lead", "assist", "all"}, optAccFrom, transAccept).drop:SetTooltip(L["ttFrom"])
	MRF:applyCheckbox(form:FindChild("SideTab:Checkbox_Publish"), optPublish, L["Publish"]).form:SetTooltip(L["ttPublish"])
	MRF:applyCheckbox(form:FindChild("SideTab:Checkbox_Republish"), optRepublish, L["Republish"]).form:SetTooltip(L["ttRepublish"])
	MRF:applyTextbox(form:FindChild("Textbox_GroupName"), optGrName)
	MRF:LoadForm("QuestionMark", form:FindChild("Textbox_GroupName")):SetTooltip(L["ttGroupName"])
	
	form:FindChild("Title"):SetText(L["Title"])
	form:FindChild("lblUngrouped"):SetText(L["Ungrouped:"])
	form:FindChild("lblGroups"):SetText(L["Groups:"])
	form:FindChild("lblSorting"):SetText(L["Sort Grouping Frame:"])
	form:FindChild("Group_Add"):SetText(L["Add"])
	form:FindChild("Group_Remove"):SetText(L["Rem."])
	form:FindChild("Group_Reset"):SetText(L["Reset All"])
	form:FindChild("Button_OpenSave"):SetText(L["Save/Load"])
	form:FindChild("SavesFrame:Title"):SetText(L["SaveTitle"])
	form:FindChild("SavesFrame:Button_SaveTo"):SetText(L["Save As:"])
	form:FindChild("SavesFrame:lblLoad"):SetText(L["Load this:"])
	form:FindChild("SavesFrame:lblRemove"):SetText(L["Remove this:"])
	form:FindChild("SideTab:Group_Publish"):SetText(L["Publish in Chat"])
	form:FindChild("SideTab:Group_Output"):SetText(L["Output Readable"])
	
	form:FindChild("All_ToGroup"):SetTooltip(L["ttToGroup"])
	form:FindChild("All_FromGroup"):SetTooltip(L["ttFromGroup"])
	form:FindChild("Group_Add"):SetTooltip(L["ttAdd"])
	form:FindChild("Group_Remove"):SetTooltip(L["ttRemove"])
	form:FindChild("Group_Reset"):SetTooltip(L["ttReset"])
	form:FindChild("SideTab:Group_Publish"):SetTooltip(L["ttPubChat"])
	form:FindChild("SideTab:Group_Output"):SetTooltip(L["ttOutput"])
	
	
	ungrHandler = setmetatable(ungrHandler, {__index = function(t,k) 
		if type(k) == "number" then
			local item = MRF:LoadForm("Groups_ListItemUnit", t.parent, t)
			rawset(t,k,item)
			return item
		end
	end})
	
	grpdHandler = setmetatable(grpdHandler, {__index = function(t,k) 
		if type(k) == "number" then
			local item = MRF:LoadForm("Groups_ListItemUnit", t.parent, t)
			rawset(t,k,item)
			return item
		end
	end})
	
	grouHandler = setmetatable(grouHandler, {__index = function(t,k) 
		if type(k) == "number" then
			local item = MRF:LoadForm("Groups_ListItemGroup", t.parent, t)
			item:SetData(k) --this is the groups index.
			rawset(t,k,item)
			return item
		end
	end})
	
	MRF:applyTextbox(form:FindChild("SavesFrame:Textbox_Name"),optSName)
 
	local permRef = {
		ipairs = function()
			local tbl = {ipairs(permData)}
			local f = tbl[1]
			local function double(f,s,...) return f,f,... end
			tbl[1] = function(...) return double(f(...)) end
			return unpack(tbl)
		end
	}
	local function trans(i)
		return i and permData[i].name or L["select one"]
	end
	MRF:applyDropdown(form:FindChild("SavesFrame:Dropdown_Load"), permRef, optLoad, trans)
	MRF:applyDropdown(form:FindChild("SavesFrame:Dropdown_Remove"), permRef, optRemove, trans)

	local optSort = MRF:GetOption(grOptions, "sortUI")
	optSort:OnUpdate(function(val)
		if val ~= "" then
			optSort:Set("")
			if val ~= nil then
				optSortUI:Set(val)
			end
		end
	end)
	
	
	MRF:applyDropdown(form:FindChild("Dropdown_Sorting"), {false, "Role", "Class", "Name"}, optSort, 
		{[false]=_L["None"], ["Role"]=_L["Role"], ["Class"]=_L["Class"], ["Name"]=_L["Name"], [""]=""})
	
	grOptions:ForceUpdate()
	Options:ForceUpdate()
	CharOpt:ForceUpdate()
	handler:Update()
end


