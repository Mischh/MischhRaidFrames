local MRF = Apollo.GetAddon("MischhRaidFrames")
local DragDrop = {}
MRF.DragDrop = DragDrop

local units = MRF:GetUnits()
local activated = false
local removing = false --remove groups, if empty after drag.
local dragActIsInsert = true
local dropActIsInsert = true
local triggered = false --already initialized..
local grpActOpt = MRF:GetOption(true, "Groupings", "use")
local grpCurOpt = MRF:GetOption(true, "Groupings", "cache")

local L = MRF:Localize({
}, {
	["To: %s"] = "Zu: %s",
	["All: %s"] = "Alle: %s",
	["Switch: %s"] = "Wechsel: %s",
	["New Group..."] = "Neue Gruppe...",
	["Ungroup"] = "Ungruppieren",
	["Rename"] = "Umbenennen",
	["Enter a new Name"] = "Wähle einen neuen Namen",
	["Delete"] = "Löschen",
	["Deactivate"] = "Deaktivieren",
	["Activate"] = "Aktivieren",
}, {
})

--hook into frames and headers.
--theoratically frames could exist before headers, but we assume we are only interested in those not associated with headers/groups
MRF:GetOption("FrameHandler_GroupFrames"):OnUpdate(DragDrop, "TriggeredGroupFrames")
function DragDrop:TriggeredGroupFrames(val)
	if not val or not activated or triggered then return end
	triggered = true
	--why do we do this? lets say it like this: its complicated. do not remove.
	--short: this can be called mid-creation of frames[1], which meant the frame-hook didnt affect frames[1]
	--		 this was the easiest way to solve it.
	self.triggertimer = ApolloTimer.Create(0, false, "OnGroupFrames", self)
end
function DragDrop:OnGroupFrames()
	self.triggertimer = nil
	
	local headers = MRF:GetOption("FrameHandler_GroupFrames"):Get().headers
	local FrameHandler = MRF.FrameHandler --headers all have the same parent
	
	--hook into header creation
	local header_meta = getmetatable(headers)
	local header_index = header_meta.__index
	function header_meta.__index(t,k)
		local h = header_index(t,k)
		h:AddEventHandler("QueryBeginDragDrop", "HeaderQueryBeginDragDrop", FrameHandler)
		h:AddEventHandler("QueryDragDrop", "HeaderQueryDragDrop", FrameHandler)
		h:AddEventHandler("DragDrop", "HeaderDragDrop", FrameHandler)
		h:SetData(k)
		return h
	end
	for k, h in ipairs(headers) do
		h:AddEventHandler("QueryBeginDragDrop", "HeaderQueryBeginDragDrop", FrameHandler)
		h:AddEventHandler("QueryDragDrop", "HeaderQueryDragDrop", FrameHandler)
		h:AddEventHandler("DragDrop", "HeaderDragDrop", FrameHandler)
		h:SetData(k)
	end
	
	function FrameHandler:HeaderQueryBeginDragDrop(...)
		return DragDrop:HeaderQueryBeginDragDrop(...)
	end
	function FrameHandler:HeaderQueryDragDrop(...)
		return DragDrop:HeaderQueryDragDrop(...)
	end
	function FrameHandler:HeaderDragDrop(...)
		return DragDrop:HeaderDragDrop(...)
	end
	
	local frames = MRF:GetFrameTable() --each item is the handler, with the actual frame at index 'frame'
	--consistency WHOO!
	
	local frames_meta = getmetatable(frames)
	local frames_index = frames_meta.__index
	function frames_meta.__index(t,k)
		local f = frames_index(t,k)
		f.frame:AddEventHandler("QueryBeginDragDrop", "FrameQueryBeginDragDrop", f)
		f.frame:SetData(k)
		f.FrameQueryBeginDragDrop = self.FrameQueryBeginDragDrop
		return f
	end	
	for k, f in pairs(frames) do
		f.frame:AddEventHandler("QueryBeginDragDrop", "FrameQueryBeginDragDrop", f)
		f.frame:SetData(k)
		f.FrameQueryBeginDragDrop = self.FrameQueryBeginDragDrop
	end
end

function DragDrop:InitDragDown()
	self.dragDown = MRF:LoadForm("DragDown", nil, self)
	self.textBlock = MRF:LoadForm("TextBox", nil, self)
	self.textBlock:Show(false, true)
	self.textBlock:SetAnchorPoints(0,0,0,0)
	self.textBlock:SetStyle("Escapable", true)
	self.textBlock:SetStyle("CloseOnExternalClick", true)
	self.textBlock:SetSprite("CRB_CharacterCreateSprites:sprCharS_NameBackBlue")
	self.textBox = self.textBlock:FindChild("Text")
	self.textBox:AddEventHandler("EditBoxReturn", "EditBoxReturn", self)
	self.textBox:AddEventHandler("EditBoxEscape", "EditBoxEscape", self)
	self.textBox:SetPrompt(L["Enter a new Name"])
	self.textBox:SetTextColor(ApolloColor.new("FFFFFFFF"))
	
	return self.dragDown
end

local function decrease(min, val, ...)
	if not min then
		return val, ...
	end
	if val then
		local new = min ~= val and val or nil
		if min == val then val = nil 
		elseif min < val then val = val-1 end
		
		if select("#", ...) == 0 then
			return val
		else
			return val, decrease(min, ...)
		end
	else
		if select("#", ...) == 0 then
			return nil
		else
			return nil, decrease(min, ...)
		end
	end
end
function DragDrop:CheckEmptyGroup(data, grpIdx, ...)
	if not removing  then return end
	local rmv = false
	if grpIdx then
		rmv = true
		for i, v in pairs(data) do
			if v == grpIdx then
				rmv = false
				break;
			end
		end
		if rmv then
			for i = grpIdx+1, #data, 1 do
				data[i-1] = data[i]
			end
			data[#data] = nil
			for i,v in pairs(data) do
				if type(v) == "number" and v>grpIdx then
					data[i] = v-1
				end
			end
		end
	end
	if select("#", ...) > 0 then
		if rmv then
			self:CheckEmptyGroup(data, decrease(grpIdx, ...))
			return true
		else
			return self:CheckEmptyGroup(data, ...)
		end
	else
		return rmv
	end
end

function DragDrop:SwitchGroups(data, grpIdx1, grpIdx2)
	data[grpIdx1], data[grpIdx2] = data[grpIdx2], data[grpIdx1]
	for n, i in pairs(data) do
		if type(n) == "string" then
			if i == grpIdx1 then
				data[n] = grpIdx2
			elseif i == grpIdx2 then
				data[n] = grpIdx1
			end
		end
	end
end

function DragDrop:InsertGroup(data, srcIdx, tarIdx)	
	for n, i in pairs(data) do
		if type(n) == "string" then
			if i==srcIdx then
				data[n] = tarIdx
			end
		end
	end
	self:CheckEmptyGroup(data, srcIdx)
end

function DragDrop:HeaderQueryBeginDragDrop(wndHandler, wndControl)
	if not activated then return end
	--self = handler = {frame = userdata}
	local drag = DragDrop.dragDown or DragDrop:InitDragDown()
	local data = DragDrop:Populate("MischhGroup", wndHandler:GetData(), wndHandler)
	drag:SetData(data)
	Apollo.BeginDragDrop(drag, "MischhGroup", "IconSprites:Icon_Windows_UI_CRB_AccountInventory_AccountBound", 0)
end

function DragDrop:FrameQueryBeginDragDrop(wndHandler, wndControl)
	if not activated then return end
	--self = FrameHandler
	local drag = DragDrop.dragDown or DragDrop:InitDragDown()
	local data = DragDrop:Populate("MischhMember", wndHandler:GetData(), wndHandler)
	drag:SetData(data)
	Apollo.BeginDragDrop(drag, "MischhMember", "IconSprites:Icon_Windows_UI_CRB_RezCaster", 0)
end
local validTypes = {MischhMember=true, MischhGroup=true}
function DragDrop:HeaderQueryDragDrop(wndHandler, wndControl, nX, nY, wndDragDown, strType, nID)
	if wndHandler ~= wndControl then return end
	if not validTypes[strType] then return end
	
	local id, name = unpack(wndDragDown:GetData())
	if id == "off" then return Apollo.DragDropQueryResult.Ignore end
	return Apollo.DragDropQueryResult.Accept --all other situations are acceptible
end

function DragDrop:HeaderDragDrop(wndHandler, wndControl, nX, nY, wndDragDown, strType, nID)
	if wndHandler ~= wndControl then return end
	if not validTypes[strType] then return end
	
	local grouping = grpCurOpt:Get()
	
	local id, name = unpack(wndDragDown:GetData())
	local tarID = wndHandler:GetData()
	if tarID > #grouping then tarID = nil end --tarID = ungrouped
	
	if strType == "MischhMember" then
		local lastGroup = grouping[name]
		grouping[name] = tarID --assign the unit to the group
		self:CheckEmptyGroup(grouping, lastGroup)
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	elseif id ~= "ungrp" then --MischhGroup (source)
		if not (id and name and grouping[id] == name) then return end
		if id == tarID then return end
		
		if dragActIsInsert then
			self:InsertGroup(grouping, id, tarID)
		else
			self:SwitchGroups(grouping, id, tarID)
		end
		
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	else --ungrp MischhGroup (source)
		if not tarID then return end --from ungrouped to ungrouped? rly?
		--fill the target group from ungrouped.
		
		for i,unit in ipairs(units) do
			local name = unit:GetName()
			grouping[name] = grouping[name] or tarID
		end
		
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	end
end

function DragDrop:QueryDragDrop(wndHandler, wndControl, nX, nY, wndDragDown, strType, nID) 
	if wndHandler ~= wndControl then return end
	if not validTypes[strType] then return end
	
	local data = wndHandler:GetData()
	
	return data[strType] and Apollo.DragDropQueryResult.Accept or Apollo.DragDropQueryResult.Ignore
end
function DragDrop:DragDrop(wndHandler, wndControl, nX, nY, wndDragDrop, strType, nID)
	if wndHandler ~= wndControl then return end
	if not validTypes[strType] then return end
	
	local data = wndHandler:GetData()
	if not data[strType] then return end
	
	self[data[strType]](self, wndHandler, unpack(data))
end
function DragDrop:DragDropClear(...) -- Ending 'Drag' -> Cursor back to 'normal'
	self.dragDown:Show(false)
end
function DragDrop:EditBoxReturn(wndHandler, wndControl, text)
	if wndHandler ~= wndControl then return end
	
	wndHandler:GetParent():Show(false) --whatever happens -> hide the textbox
	
	local grpIdx, grpName = unpack(wndHandler:GetData()) --set inside :RenameGroup
	local grouping = grpCurOpt:Get()
	if not (grpIdx and grpName and grouping[grpIdx] == grpName) then return end
	
	--check, whether text is a unique groupName.
	if text:match("^%s*$") then return end
	for i,v in ipairs(grouping) do
		if v == text then
			return
		end
	end
	
	--apply groupName
	grouping[grpIdx] = text
	grpCurOpt:ForceUpdate()
	MRF.GroupHandler:ChangedGroupLayout()
end
function DragDrop:EditBoxEscape(wndHandler, wndControl)
	wndHandler:GetParent():Show(false)
end

function DragDrop:Populate(typ, key, src)
	local drag = self.dragDown
	--guaranteed to be created.
	
	local data = nil; --used to carry information like {grpIdx, grpName}
	local cPos = Apollo.GetMouse()
	local wPos = src:GetMouse()
	
	local l, r;
	local srcLeftEdge = cPos.x-wPos.x
	local srcRightEdge = srcLeftEdge+src:GetWidth()
	if srcLeftEdge > select(3, src:GetParent():GetRect()) - srcRightEdge then
		--show on left side of raidframes
		r =-2 + srcLeftEdge
		l = r - drag:GetWidth()
	else
		--show on right side of raidframes
		l = 2 + srcRightEdge
		r = l + drag:GetWidth()
	end
	
	local y =   cPos.y-wPos.y
	drag:SetAnchorOffsets(l, y, r, drag:GetHeight()+y)
	drag:ToFront()
	drag:Show(true)
	
	local numBtn = 1;
	local btn; --just so i do not need to name everyone...
	
	if grpActOpt:Get() then
		local grouping = grpCurOpt:Get()
		--[[
			[1] = "Group1",
			[2] = "Group2",
			["NameOfUnit"] = 2,
		]]
		if typ == "MischhMember" then
			local unit = units[key]
			local name = unit:GetName()
			data = {key, name}
			for i,v in ipairs(grouping) do
				-- i = idx
				-- v = GroupName
				btn, numBtn = self:GetButton(numBtn)
				btn:SetText(L["To: %s"]:format(v))
				btn:SetData({name, i, v, MischhMember = "MoveToGroup"})
			end	
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["To: %s"]:format(L["New Group..."]))
			btn:SetData({name, "new", MischhMember = "MoveToGroup"})
			
			if grouping[name] then
				btn, numBtn = self:GetButton(numBtn)
				btn:SetText(L["Ungroup"])
				btn:SetData({name, "ungrp", MischhMember = "MoveToGroup"})
			end
		elseif typ == "MischhGroup" and grouping[key] then
			-- key = #group
			data = {key, grouping[key]}
			for i,v in ipairs(grouping) do
				if i~=key then
					btn, numBtn = self:GetButton(numBtn)
					btn:SetText((dropActIsInsert and L["All: %s"] or L["Switch: %s"]):format(v))
					btn:SetData({key, grouping[key], i, v, dropActIsInsert, MischhGroup = "Group2Group"})
				end
			end
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["Rename"])
			btn:SetData({{key, grouping[key]}, MischhGroup = "RenameGroup"})
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["Delete"])
			btn:SetData({key, grouping[key], MischhGroup = "RemoveGroup"})
		elseif typ == "MischhGroup" then --its the 'ungrouped'-Group
			data = {"ungrp", nil}
			for i,v in ipairs(grouping) do
				btn, numBtn = self:GetButton(numBtn)
				btn:SetText(L["All: %s"]:format(v))
				btn:SetData({i, v, MischhGroup = "UngroupedTo"})
			end
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["All: %s"]:format(L["New Group..."]))
			btn:SetData({"new", MischhGroup = "UngroupedTo"})
		end
	else
		data = {"off", nil}
	end
	
	
	--GroupingActivation
	btn, numBtn = self:GetButton(numBtn)
	if grpActOpt:Get() then
		btn:SetText(L["Deactivate"])
	else
		btn:SetText(L["Activate"])
	end
	btn:SetData({grpActOpt:Get(), MischhGroup = "GroupingActivation", MischhMember = "GroupingActivation"})
	self:AlignButtons(numBtn)
	return data
end

do
	local buttons = {} --[idx] = wndButton
	function DragDrop:GetButton(idx)
		if not buttons[idx] then
			buttons[idx] = MRF:LoadForm("DragDownButton", self.dragDown, self)
		end
		buttons[idx]:Show(true, true)
		return buttons[idx], idx+1
	end

	function DragDrop:AlignButtons(idx) --idx is the first hidden button; Assumes at least one Button!
		for i = idx, #buttons, 1 do
			buttons[i]:Show(false, true)
		end
		self.dragDown:ArrangeChildrenVert()
		local ch = self.dragDown:GetChildren()
		local b = select(4, ch[idx-1]:GetAnchorOffsets())
		local l, t, r = self.dragDown:GetAnchorOffsets()
		self.dragDown:SetAnchorOffsets(l, t, r, t+b)
	end
end

function DragDrop:GroupingActivation(wndBtn, bWasActive)
	grpActOpt:Set(not bWasActive)
end

function DragDrop:MoveToGroup(wndBtn, unitName, grpIdx, grpName)
	local grouping = grpCurOpt:Get()
	local prevIdx = grouping[unitName]
	if grpIdx == "new" then
		grouping[#grouping+1] = MRF.GroupHandler.GetUniqueGroupName()
		grouping[unitName] = #grouping
		self:CheckEmptyGroup(grouping, prevIdx)
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	elseif grpIdx == "ungrp" then
		if grouping[unitName] then
			grouping[unitName] = nil
			self:CheckEmptyGroup(grouping, prevIdx)
			grpCurOpt:ForceUpdate()
			MRF.GroupHandler:ChangedGroupLayout()
		end
	else
		--first check if such a group still exists -> rather do nothing, than doing weird stuff..
		-- as such grpName is just a 'checksum'
		if not (grpIdx and grpName and grouping[grpIdx] == grpName) then return end
		grouping[unitName] = grpIdx
		self:CheckEmptyGroup(grouping, prevIdx)
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	end
end

function DragDrop:RemoveGroup(wndBtn, grpIdx, grpName)
--grpName as some sort of checksum, that nothing majorly gone wrong.
	local grouping = grpCurOpt:Get()
	if not (grpIdx and grpName and grouping[grpIdx] == grpName) then return end
	
	table.remove(grouping, grpIdx)
	for i, v in pairs(grouping) do
		if v == grpIdx then
			grouping[i] = nil
		end
	end
	
	grpCurOpt:ForceUpdate()
	MRF.GroupHandler:ChangedGroupLayout()
end

function DragDrop:RenameGroup(wndBtn, params)
	local l, t, r, _ = self.dragDown:GetAnchorOffsets()
	local _, t2, _, b2 = wndBtn:GetAnchorOffsets()
	
	self.textBlock:Show(true, true)
	self.textBlock:SetAnchorOffsets(l, t+t2, r, t+b2)
	self.textBox:SetText("")
	self.textBox:SetFocus(true)
	
	self.textBox:SetData(params)
end

function DragDrop:Group2Group(wndBtn, srcIdx, srcName, tarIdx, tarName, isInsert)
	--again, names just as a checksum.
	local grouping = grpCurOpt:Get()
	if not (srcIdx and srcName and grouping[srcIdx] == srcName) then return end
	if not (tarIdx and tarName and grouping[tarIdx] == tarName) then return end

	if isInsert then
		self:InsertGroup(grouping, srcIdx, tarIdx)
	else
		self:SwitchGroups(grouping, srcIdx, tarIdx)
	end

	grpCurOpt:ForceUpdate()
	MRF.GroupHandler:ChangedGroupLayout()
end

function DragDrop:UngroupedTo(wndButton, grpIdx, grpName)
	--again, names just as a checksum.
	local grouping = grpCurOpt:Get()
	
	if grpIdx == "new" then
		grpIdx = #grouping+1
		grpName = MRF.GroupHandler.GetUniqueGroupName()
		grouping[grpIdx] = grpName
	end
	
	if not (grpIdx and grpName and grouping[grpIdx] == grpName) then return end
	
	for i,unit in ipairs(units) do
		local name = unit:GetName()
		grouping[name] = grouping[name] or grpIdx
	end
	
	grpCurOpt:ForceUpdate()
	MRF.GroupHandler:ChangedGroupLayout()
end


-- #############################----------------------####################################
-- ##############--------------------- Settings ---------------------#####################
-- #############################----------------------####################################
do
	local opts = MRF:GetOption(nil, "DragDrop")
	local actOpt = MRF:GetOption(opts, "activated")
	local remOpt = MRF:GetOption(opts, "removeEmpty")
	local drgOpt = MRF:GetOption(opts, "dragAction")
	local drpOpt = MRF:GetOption(opts, "dropAction")
	actOpt:OnUpdate(function(val) 
		if val == nil then
			actOpt:Set(true)
		else
			activated = val
			if val then
				DragDrop:TriggeredGroupFrames(MRF:GetOption("FrameHandler_GroupFrames"):Get())
			end
		end
	end)
	remOpt:OnUpdate(function(val)
		if val == nil then
			remOpt:Set(true)
		else
			removing = val
		end
	end)
	drgOpt:OnUpdate(function(val)
		if val == nil then
			drgOpt:Set("insert")
		else
			dragActIsInsert = val == "insert"
		end
	end)
	drpOpt:OnUpdate(function(val)
		if val == nil then
			drpOpt:Set("switch")
		else
			dropActIsInsert = val == "insert"
		end
	end)

	MRF:AddChildTab("Drag n' Drop", "Group Handler", DragDrop, "InitSettings")
	function DragDrop:InitSettings(parent, name)
		local L = MRF:Localize({
		},{
			["Activate"] = "Aktivieren",
			["Remove emptied groups"] = "Entferne geleerte Gruppen",
			["'Group -> Group' drag operation:"] = "'Gruppe -> Gruppe' per Ziehen:",
			["'Group -> Group' dropdown operation:"] = "'Gruppe -> Gruppe' per Auswahlmenü:",
			["Switch Groups"] = "Gruppen Tauschen",
			["Insert all Members"] = "Alle Mitglieder Einfügen",
		},{
		})
	
		local form = MRF:LoadForm("SimpleTab", parent)
		form:FindChild("Title"):SetText(name)
		parent = form:FindChild("Space")
		
		local row;
		local function newRow() row = MRF:LoadForm("HalvedRow", parent); return row end
		local function left() return row:FindChild("Left") end
		local function right() return row:FindChild("Right") end
		
		newRow()
		MRF:applyCheckbox(right(), actOpt, L["Activate"])
		
		newRow()
		MRF:applyCheckbox(right(), remOpt, L["Remove emptied groups"])
		
		newRow()
		left():SetText(L["'Group -> Group' drag operation:"])
		MRF:applyDropdown(right(), {"switch", "insert"}, drgOpt, {switch=L["Switch Groups"], insert=L["Insert all Members"]})
		
		newRow()
		left():SetText(L["'Group -> Group' dropdown operation:"])
		MRF:applyDropdown(right(), {"switch", "insert"}, drpOpt, {switch=L["Switch Groups"], insert=L["Insert all Members"]})		
		
		parent:ArrangeChildrenVert()
		local children = parent:GetChildren()
		local l, t, r = parent:GetAnchorOffsets()
		local b = select(4,children[#children]:GetAnchorOffsets())
		parent:SetAnchorOffsets(l, t, r, t+b)
		parent:GetParent():RecalculateContentExtents()
		parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
		opts:ForceUpdate()
	end
end