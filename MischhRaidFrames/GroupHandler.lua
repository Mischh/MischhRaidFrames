--[[]]

local GroupHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
local groups = nil --applied in GetGroupHandlersRegroup
local units = nil --applied in GetGroupHandlersRegroup
local tinsert = table.insert

local Options = MRF:GetOption(nil, "Group Handler")
local optSavedDef = MRF:GetOption(Options, "cache")
local optPermSave = MRF:GetOption(Options, "saved")
local optUse = MRF:GetOption(Options, "use")
local optAcc = MRF:GetOption(Options, "accept")
local optLead = MRF:GetOption(Options, "lead")
--MRF:AddMainTab("Group Handler", GroupHandler, "InitSettings")

local accept = true --do we accept the leaders groupings?
local onlyLead = true
local useUserDef = false
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

do
	local f = MRF.OnDocLoaded
	function MRF:OnDocLoaded(...)
		f(self,...)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", GroupHandler)
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
	groups[unI] = {name = "Ungrouped"}
	
	for i, unit in ipairs(units) do
		local n = unit:GetName()
		local grI = userdef[n] or unI --group = the user-defenition, or ungrouped
		local gr = groups[grI] or groups[unI]
		gr[#gr+1] = i
	end
end

function GroupHandler:Regroup_Default()
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

optLead:OnUpdate(GroupHandler, "UpdateRecieveLead")
function GroupHandler:UpdateRecieveLead(new)
	if new == nil then
		optLead:Set(true)
	else
		onlyLead = new
	end
end

function GroupHandler:VRFSerialize(t) --use VinceRaidFrames Serializing and Deserializing to be compatible.
	local tbl = {"{"}
	local indexed = #t > 0
	local hasValues = false
	for k, v in pairs(t) do
		hasValues = true
		tinsert(tbl, type(v) == "number" and tostring(v) or '"'..v..'"' )
		tinsert(tbl, ",")
	end
	tbl[#tbl] = nil
	
	tinsert(tbl, "}")
	return table.concat(tbl)
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
		tinsert(memberNames, unit:GetName())
	end
	-- Sorted member names for short unique ids across clients!
	table.sort(memberNames)
	for i, name in ipairs(memberNames) do --this is just a array -> map method.
		memberNameToId[name] = i
	end
	
	return memberNameToId, memberNames
end

local shareKey = "}=>"
function GroupHandler:PublishGroup()
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
	
	local str = shareKey..self:VRFSerialize(layout)
	ChatSystemLib.GetChannels()[ChatSystemLib.ChatChannel_Party]:Send(str)
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
	
	self:Regroup()
	self:Reposition()
	self:DistantUpdate()
end

local matchString = "^"..shareKey.."(.+)$"
function GroupHandler:OnChatMessage(channelSource, tMessageInfo)
	if not accept then
		return
	end
	if channelSource:GetType() ~= ChatSystemLib.ChatChannel_Party then
		return
	end
	if onlyLead and not self:IsLead(tMessageInfo.strSender) then
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
	self:ImportGroup(layout)
end

function GroupHandler:IsLead(name)
	for _, unit in ipairs(units) do
		if unit:IsLeader() then
			if unit:GetName() == name then
				return true --is leader and has name.
			else
				return false --is leader, but hasnt name.
			end
		elseif unit:GetName() == name then
			return false --isnt leader, but has name.
		end
	end
	return false --no leader in group?! --nobody with the name?! --wtf?!
end

function MRF:GetGroupHandlersRegroup(unithandler_groups, unithandler_units, UnitHandler)
	groups = unithandler_groups
	units = unithandler_units
	
	function GroupHandler:Reposition(...)
		return UnitHandler:Reposition(...)
	end
	
	return GroupHandler.Regroup
end

function GroupHandler:InitSettings(parent, name)
	
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

local classColor = unpack(MRF:HasModule("Class Colors"):GetColorTable())
local name2color = {}
local name2text = {}
local nocolor = ApolloColor.new("FF666666")

function handler:Update(onlyUI)
	if not form then return end

	if not onlyUI then 
		GroupHandler:Regroup()
		GroupHandler:Reposition()
	end
	
	self:ReselectGroup() --this will end up in redrawing the selected Group & the Groups List.
	
	ungrHandler:Redraw() --redraw the Ungrouped ppl aswell.
end

function GroupHandler:DistantUpdate()
	if not units then return end
	
	name2color = {}
	name2text = {}
	for i, unit in ipairs(units) do
		local n = unit:GetName()
		local pre = (unit:IsTank() and "T" or unit:IsHeal() and "H" or "D")..": "
		local c = classColor:Get(unit)
		
		name2color[n] = c
		name2text[n] = pre..n
	end
	
	handler:Update(true)
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
end

local function findUniqueName(i)
	i = i or 0
	local n = "New Group"..(i>0 and " "..i or "")
	for _, name in ipairs(userdef) do
		if name == n then
			return findUniqueName(i+1)
		end
	end
	return n;
end

function handler:AddGroup() --Pressed 'Add'
	userdef[#userdef+1] = findUniqueName()
	optGrIdx:Set(#userdef)
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
end

function handler:MoveToGroup() --Pressed '-->'
	local idx = optGrIdx:Get()
	if idx then
		for i, unit in ipairs(units) do
			local n = unit:GetName()
			userdef[n] = userdef[n] or idx
		end
	end
	self:Update()
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
end

function handler:ToggleSaveMenu(btn) --Pressed 'Load/Save'
	self.saveMenu:Show(btn:IsChecked())
end

function handler:PublishGroup()
	GroupHandler:PublishGroup()
end

function handler:UpdateUse(use) -- called by optUse:ForceUpdate()
	if use == nil then
		optUse:Set(false)
	else
		useUserDef = use
		handler:Update()
	end
end

function handler:UpdateAccept(acc) -- called by optAcc:ForceUpdate()
	if acc == nil then
		optAcc:Set(true)
	else
		accept = acc
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
	end
end

function handler:RemoveIndex(idx)
	if idx and permData[idx] then
		table.remove(permData, idx)
		optRemove:Set(nil)
	end
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

function grpdHandler:GetText(name)
	return name2text[name] or name
end

function grpdHandler:GetTextColor(name)
	return name2color[name] or nocolor
end 

function grpdHandler:Redraw()
	local idx = optGrIdx:Get()
	
	local i = 0
	for name, grIndex in pairs(userdef) do
		if grIndex == idx then
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

function grpdHandler:UnitSelected(button)
	local name = button:GetData()
	userdef[name] = nil
	
	handler:Update()
end

function ungrHandler:GetText(unit)
	local n = unit:GetName()
	return name2text[n] or n
end

function ungrHandler:GetTextColor(unit)
	local n = unit:GetName()
	return name2color[n] or nocolor
end 

function ungrHandler:Redraw()
	local i = 0
	for _, unit in ipairs(units) do
		local n = unit:GetName()
		if not userdef[n] then
			i = i+1
			self[i]:SetText(self:GetText(unit))
			self[i]:SetTextColor(self:GetTextColor(unit))
			self[i]:SetData(unit)
		end
	end
	
	self.parent:ArrangeChildrenVert()
	self.parent:SetAnchorOffsets(0,0,0, i*25)
	self.parent:GetParent():RecalculateContentExtents()
end

function ungrHandler:UnitSelected(button)
	local idx = optGrIdx:Get()
	if not idx then return end
	
	local unit = button:GetData()
	local n = unit:GetName()
	
	userdef[n] = idx
	
	handler:Update()
end

function MRF:InitGroupForm()
	if form then return form:Show(true, false) end
	
	form = self:LoadForm("GroupingForm", nil, handler)
	handler.saveMenu = form:FindChild("SavesFrame")
	ungrHandler.parent = form:FindChild("Ungrouped:Items")
	grpdHandler.parent = form:FindChild("Grouped:Items")
	grouHandler.parent = form:FindChild("Groups:Items")
	
	MRF:applyCheckbox(form:FindChild("Checkbox_Activated"), optUse, "Activate").form:SetTooltip("Use these Settings instead of the Default tank-heal-dps groups.")
	MRF:applyCheckbox(form:FindChild("Checkbox_Accept"), optAcc, "Accept").form:SetTooltip("Accept published Settings from Chat.")
	MRF:applyCheckbox(form:FindChild("Checkbox_All"), optLead, "Lead only").form:SetTooltip("Published settings are only imported from the group-leader.")
	MRF:applyTextbox(form:FindChild("Textbox_GroupName"), optGrName)
	MRF:LoadForm("QuestionMark", form:FindChild("Textbox_GroupName")):SetTooltip([[Note: Every groups name needs to be unique.]])
	
	form:FindChild("Group_Publish"):SetTooltip([[Publishes your current settings to the group.
	This and other addons may only accept the settings, if you are the leader of the group.
	The addon can only publish settings for units, which are currently in your group. Make sure they are.]])
	
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
		return i and permData[i].name or "select one"
	end
	MRF:applyDropdown(form:FindChild("SavesFrame:Dropdown_Load"), permRef, optLoad, trans)
	MRF:applyDropdown(form:FindChild("SavesFrame:Dropdown_Remove"), permRef, optRemove, trans)
	
	
	
	grOptions:ForceUpdate()
	Options:ForceUpdate()
	handler:Update()
end


