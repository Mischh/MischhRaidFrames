--[[]]

local GroupHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
local groups = nil --applied in GetGroupHandlersRegroup
local units = nil --applied in GetGroupHandlersRegroup


local Options = MRF:GetOption(nil, "Group Handler")
--MRF:AddMainTab("Group Handler", GroupHandler, "InitSettings")


local useUserDef = false
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
local optUse = MRF:GetOption(grOptions, "useThis")
local optGrName = MRF:GetOption(grOptions, "name")
local optGrIdx = MRF:GetOption(grOptions, "index")
local handler = {}
local ungrHandler = {} --ungrouped List		--ListItem creation within the Init!
local grpdHandler = {} --grouped List		--ListItem creation within the Init!
local grouHandler = {} --groups List		--ListItem creation within the Init!
local switching = false

optUse:OnUpdate(handler, "UpdateUse")
optGrName:OnUpdate(handler, "UpdateGrName")
optGrIdx:OnUpdate(handler, "UpdateGroupIndex")

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

function handler:OnCancel()
	form:Show(false, false)
end

function handler:ResetGroups()
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

function handler:AddGroup()
	userdef[#userdef+1] = findUniqueName()
	optGrIdx:Set(#userdef)
end

function handler:RemoveGroup()
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

function handler:MoveToGroup()
	local idx = optGrIdx:Get()
	if idx then
		for i, unit in ipairs(units) do
			local n = unit:GetName()
			userdef[n] = userdef[n] or idx
		end
	end
	self:Update()
end

function handler:MoveFromGroup()
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

function handler:UpdateUse(use)
	if use == nil then
		optUse:Set(false)
	else
		useUserDef = use
		handler:Update()
	end
end

local oldName = nil
function handler:UpdateGrName(name)
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

function handler:UpdateGroupIndex(idx)
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
	ungrHandler.parent = form:FindChild("Ungrouped:Items")
	grpdHandler.parent = form:FindChild("Grouped:Items")
	grouHandler.parent = form:FindChild("Groups:Items")
	
	MRF:applyCheckbox(form:FindChild("Checkbox_Activated"), optUse, "Use")
	MRF:applyTextbox(form:FindChild("Textbox_GroupName"), optGrName)
	MRF:LoadForm("QuestionMark", form:FindChild("Textbox_GroupName")):SetTooltip([[Note: Every groups name needs to be unique.]])
	
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
 
	
	handler:Update()
end


