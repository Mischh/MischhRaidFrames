local MRF = Apollo.GetAddon("MischhRaidFrames")
local DragDrop = {}
MRF.DragDrop = DragDrop

local units = MRF:GetUnits()
local activated = true
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
function DragDrop:TriggeredGroupFrames()
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
		h:SetData(k)
		return h
	end
	for k, h in ipairs(headers) do
		h:AddEventHandler("QueryBeginDragDrop", "HeaderQueryBeginDragDrop", FrameHandler)
		h:SetData(k)
	end
	
	function FrameHandler:HeaderQueryBeginDragDrop(...)
		DragDrop:HeaderQueryBeginDragDrop(...)
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

function DragDrop:HeaderQueryBeginDragDrop(wndHandler, wndControl)
	if not activated then return end
	--self = handler = {frame = userdata}
	local drag = DragDrop.dragDown or DragDrop:InitDragDown()
	DragDrop:Populate("MischhGroup", wndHandler:GetData(), wndHandler)
	Apollo.BeginDragDrop(drag, "MischhGroup", "IconSprites:Icon_Windows_UI_CRB_AccountInventory_AccountBound", 0)
end

function DragDrop:FrameQueryBeginDragDrop(wndHandler, wndControl)
	if not activated then return end
	--self = FrameHandler
	local drag = DragDrop.dragDown or DragDrop:InitDragDown()
	DragDrop:Populate("MischhMember", wndHandler:GetData(), wndHandler)
	Apollo.BeginDragDrop(drag, "MischhMember", "IconSprites:Icon_Windows_UI_CRB_RezCaster", 0)
end

local validTypes = {MischhGroup = Apollo.DragDropQueryResult.Accept, MischhMember = Apollo.DragDropQueryResult.Accept, [false] = Apollo.DragDropQueryResult.Ignore}
function DragDrop:QueryDragDrop(wndHandler, wndControl, nX, nY, wndDragDown, strType, nID) 
	return validTypes[strType] or validTypes[false]
end
function DragDrop:DragDrop(wndHandler, wndControl, nX, nY, wndDragDrop, strType, nID)
	if wndHandler ~= wndControl then return end
	
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
	
	local cPos = Apollo.GetMouse()
	local wPos = src:GetMouse()
	local x = 2+cPos.x-wPos.x+src:GetWidth()
	local y =   cPos.y-wPos.y
	drag:SetAnchorOffsets(x, y, drag:GetWidth()+x, drag:GetHeight()+y)
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
			
			for i,v in ipairs(grouping) do
				if i~=key then
					btn, numBtn = self:GetButton(numBtn)
					btn:SetText(L["Switch: %s"]:format(v))
					btn:SetData({key, grouping[key], i, v, MischhGroup = "SwitchGroup"})
				end
			end
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["Rename"])
			btn:SetData({{key, grouping[key]}, MischhGroup = "RenameGroup"})
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["Delete"])
			btn:SetData({key, grouping[key], MischhGroup = "RemoveGroup"})
		elseif typ == "MischhGroup" then --its the 'ungrouped'-Group
			for i,v in ipairs(grouping) do
				btn, numBtn = self:GetButton(numBtn)
				btn:SetText(L["All: %s"]:format(v))
				btn:SetData({i, v, MischhGroup = "UngroupedTo"})
			end
			
			btn, numBtn = self:GetButton(numBtn)
			btn:SetText(L["All: %s"]:format(L["New Group..."]))
			btn:SetData({"new", MischhGroup = "UngroupedTo"})
		end
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
	if grpIdx == "new" then
		local grouping = grpCurOpt:Get()
		grouping[#grouping+1] = MRF.GroupHandler.GetUniqueGroupName()
		grouping[unitName] = #grouping
		grpCurOpt:ForceUpdate()
		MRF.GroupHandler:ChangedGroupLayout()
	elseif grpIdx == "ungrp" then
		local grouping = grpCurOpt:Get()
		if grouping[unitName] then
			grouping[unitName] = nil
			grpCurOpt:ForceUpdate()
			MRF.GroupHandler:ChangedGroupLayout()
		end
	else
		local grouping = grpCurOpt:Get()
		--first check if such a group still exists -> rather do nothing, than doing weird stuff..
		-- as such grpName is just a 'checksum'
		if not (grpIdx and grpName and grouping[grpIdx] == grpName) then return end
		grouping[unitName] = grpIdx
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

function DragDrop:SwitchGroup(wndBtn, srcIdx, srcName, tarIdx, tarName)
	--again, names just as a checksum.
	local grouping = grpCurOpt:Get()
	if not (srcIdx and srcName and grouping[srcIdx] == srcName) then return end
	if not (tarIdx and tarName and grouping[tarIdx] == tarName) then return end
	
	grouping[srcIdx] = tarName
	grouping[tarIdx] = srcName
	
	for i,v in pairs(grouping) do
		if v == srcIdx then
			grouping[i] = tarIdx
		elseif v == tarIdx then
			grouping[i] = srcIdx
		end
	end
	grpCurOpt:ForceUpdate()
	MRF.GroupHandler:ChangedGroupLayout()
end

function DragDrop:UngroupedTo(wndButton, grpIdx, grpName) print(pcall(function()
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
	MRF.GroupHandler:ChangedGroupLayout() end))
end