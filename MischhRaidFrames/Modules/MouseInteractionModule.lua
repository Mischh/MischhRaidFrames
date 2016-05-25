--[[]]

local modKey = "Mouse Interaction"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local MouseMod, ModOptions = MRF:newModule(modKey , "misc", false)

local frames = {}
local clickAction = {[0]="Target Unit",[1]="Dropdown Menu",[2]="Focus Unit",[3]=false,[4]=false,over=false}
local supportedActions = {["Target Unit"] = true, ["Dropdown Menu"] = true, ["Focus Unit"] = true, [false] = true}
local actions = {false, "Dropdown Menu", "Target Unit", "Focus Unit"}

--Options
local activeOption = MRF:GetOption(ModOptions, "activated")
-- all of these shall be either false or a Sting categorizing the action.
local mouse0Option = MRF:GetOption(ModOptions, "mouse0") --Left
local mouse1Option = MRF:GetOption(ModOptions, "mouse1") --Right
local mouse2Option = MRF:GetOption(ModOptions, "mouse2") --Middle
local mouse3Option = MRF:GetOption(ModOptions, "mouse3") --LastPage (Browser-Default)
local mouse4Option = MRF:GetOption(ModOptions, "mouse4") --NextPage
local mouseoverOption = MRF:GetOption(ModOptions, "mouseover")


function MouseMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	elseif active then
		self:On()
	else
		self:Off()
	end
end
activeOption:OnUpdate(MouseMod, "UpdateActivated")

function MouseMod:UpdateMouse0Option(action)
	if action == nil or not supportedActions[action] then
		mouse0Option:Set("Target Unit") --apply default
	else
		clickAction[0] = action
	end
end

function MouseMod:UpdateMouse1Option(action)
	if action == nil or not supportedActions[action] then
		mouse1Option:Set("Dropdown Menu")		
	else
		clickAction[1] = action
	end
end

function MouseMod:UpdateMouse2Option(action)
	if action == nil or not supportedActions[action] then
		mouse2Option:Set("Focus Unit")		
	else
		clickAction[2] = action
	end
end

function MouseMod:UpdateMouse3Option(action)
	if action == nil or not supportedActions[action] then
		mouse3Option:Set(false)		
	else
		clickAction[3] = action
	end
end

function MouseMod:UpdateMouse4Option(action)
	if action == nil or not supportedActions[action] then
		mouse4Option:Set(false)		
	else
		clickAction[4] = action
	end
end

function MouseMod:UpdateMouseoverOption(action)
	if action == nil or not supportedActions[action] then
		mouseoverOption:Set(false)		--"DisplayTooltip"
	else
		clickAction["over"] = action
	end
end

mouse0Option:OnUpdate(MouseMod, "UpdateMouse0Option")
mouse1Option:OnUpdate(MouseMod, "UpdateMouse1Option")
mouse2Option:OnUpdate(MouseMod, "UpdateMouse2Option")
mouse3Option:OnUpdate(MouseMod, "UpdateMouse3Option")
mouse4Option:OnUpdate(MouseMod, "UpdateMouse4Option")
mouseoverOption:OnUpdate(MouseMod, "UpdateMouseoverOption")


-- HANDLERS
MouseMod["Target Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	if unit then
		GameLib.SetTargetUnit(unit)
	end
end

MouseMod["Focus Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	if unit then
		GameLib.GetPlayerUnit():SetAlternateTarget(unit)
	end
end

MouseMod["Dropdown Menu"] = function(self, handler,wndHandler)
	local fakeUnit = frames[handler]
	local unit = frames[handler]:GetRealUnit()
	if unit then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, fakeUnit:GetName(), unit)
	else
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, fakeUnit:GetName())
	end
end

MouseMod["Display Tooltip"] = function(self, handler,wndHandler) --not supported right now. Doesnt work.
	local unit = frames[handler]:GetRealUnit()
	if unit then
		Event_FireGenericEvent("MouseOverUnitChanged", unit)
	end
end

-- HANDLE THE REGISTERED EVENTS

local function MouseMod_MouseUp(self, handler, wndHandler, wndControl, button, posx, posy)
	if wndHandler ~= wndControl then return end
	if clickAction[button] then
		self[clickAction[button]](self,handler,wndHandler)
	end
end
MouseMod.MouseUp = MouseMod_MouseUp;

local function MouseMod_MouseEnter(self, handler, wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	if clickAction["over"] then
		self[clickAction["over"]](self,handler,wndHandler)
	end
end
MouseMod.MouseEnter = MouseMod_MouseEnter;

local function empty() end

function MouseMod:Off()
	self.MouseEnter = empty
	self.MouseUp = empty
end

function MouseMod:On()
	self.MouseEnter = MouseMod_MouseEnter
	self.MouseUp = MouseMod_MouseUp
end

function MouseMod:miscUpdate(frame, unit)
	if not frames[frame] then
		-- hook into
		local f = frame.MouseButtonUp
		frame.MouseButtonUp = function(...)
			f(...)
			self:MouseUp(...)
		end
		
		f = frame.MouseEnter
		frame.MouseEnter = function(...)
			f(...)
			self:MouseEnter(...)
		end
	end
	frames[frame] = unit
end

function MouseMod:InitMiscSettings(parent)
	local rowL = MRF:LoadForm("HalvedRow", parent)
	local rowR = MRF:LoadForm("HalvedRow", parent)
	local rowM = MRF:LoadForm("HalvedRow", parent)
	local row4 = MRF:LoadForm("HalvedRow", parent)
	local row5 = MRF:LoadForm("HalvedRow", parent)
	local rowOver = MRF:LoadForm("HalvedRow", parent)
	
	rowL:FindChild("Left"):SetText("Left Click:")
	rowR:FindChild("Left"):SetText("Right Click:")
	rowM:FindChild("Left"):SetText("Middle Click:")
	row4:FindChild("Left"):SetText("Mouse 4 Click:")
	row5:FindChild("Left"):SetText("Mouse 5 Click:")
	rowOver:FindChild("Left"):SetText("Mousenter (Mouseover):")
	
	local question = MRF:LoadForm("QuestionMark", rowL:FindChild("Left"))
	question:SetTooltip([[Here you can define which action should occur, when a specific Mouse-Action was done.
	Note that most actions only work, when the Unit had been updated within your Range.]])
	
	local function translateAction(action) return action or " - " end
	
	MRF:applyDropdown(rowL:FindChild("Right"), actions, mouse0Option, translateAction)
	MRF:applyDropdown(rowR:FindChild("Right"), actions, mouse1Option, translateAction)
	MRF:applyDropdown(rowM:FindChild("Right"), actions, mouse2Option, translateAction)
	MRF:applyDropdown(row4:FindChild("Right"), actions, mouse3Option, translateAction)
	MRF:applyDropdown(row5:FindChild("Right"), actions, mouse4Option, translateAction)
	MRF:applyDropdown(rowOver:FindChild("Right"), actions, mouseoverOption, translateAction)
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 6*30 --we want to display six 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
