--[[]]

local modKey = "Mouse Interaction"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local MouseMod, ModOptions = MRF:newModule(modKey , "misc", false)

local frames = {}
local clickAction = {[0]="Target Unit",[1]="Dropdown Menu",[2]="Focus Unit",[3]=false,[4]=false,over=false}
local supportedActions = {["Target Unit"] = true, ["Dropdown Menu"] = true, ["Focus Unit"] = true, ["Show Hint Arrow"] = true, [false] = true}
local actions = {false, "Dropdown Menu", "Target Unit", "Focus Unit", "Show Hint Arrow"}

local advEnter = false
local invertEnter = true

--Options
local activeOption = MRF:GetOption(ModOptions, "activated")
-- all of these shall be either false or a Sting categorizing the action.
local mouse0Option = MRF:GetOption(ModOptions, "mouse0") --Left
local mouse1Option = MRF:GetOption(ModOptions, "mouse1") --Right
local mouse2Option = MRF:GetOption(ModOptions, "mouse2") --Middle
local mouse3Option = MRF:GetOption(ModOptions, "mouse3") --LastPage (Browser-Default)
local mouse4Option = MRF:GetOption(ModOptions, "mouse4") --NextPage
local mouseoverOption = MRF:GetOption(ModOptions, "mouseover")

local advEnterOpt = MRF:GetOption(ModOptions, "advancedMouseEnter")
local inversionOpt = MRF:GetOption(ModOptions, "invertActions")

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
		mouseoverOption:Set(false)
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

function MouseMod:UpdateAdvanced(adv)
	if adv == nil then
		advEnterOpt:Set(false)
	else
		advEnter = adv
		Apollo.RemoveEventHandler("NextFrame", self)
	end
end

function MouseMod:UpdateInvert(inv)
	if inv == nil then
		inversionOpt:Set(true)
	else
		invertEnter = inv
	end
end

advEnterOpt:OnUpdate(MouseMod, "UpdateAdvanced")
inversionOpt:OnUpdate(MouseMod, "UpdateInvert")

-- HANDLERS
local EnterMod = {}
local LeaveMod = {}

local oldTar = nil
MouseMod["Target Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	if unit then
		oldTar = nil --maybe change to unit	
		GameLib.SetTargetUnit(unit)
	end
end

local oldFoc = nil
MouseMod["Focus Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	local plr = GameLib.GetPlayerUnit()
	if unit then
		oldFoc = nil --maybe change to unit
		plr:SetAlternateTarget(unit)
	end
end

EnterMod["Target Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	if unit then
		if not oldTar then
			oldTar = GameLib.GetTargetUnit() or true
		end
		
		GameLib.SetTargetUnit(unit)
	end
end

EnterMod["Focus Unit"] = function(self, handler,wndHandler)
	local unit = frames[handler]:GetRealUnit()
	if unit then
		local plr = GameLib.GetPlayerUnit()
		if not oldFoc then
			oldFoc = plr:GetAlternateTarget() or true
		end
		plr:SetAlternateTarget(unit)
	end
end

LeaveMod["Target Unit"] = function(self, handler, wndHandler)
	if not oldTar then return end
	if oldTar == true then
		GameLib.SetTargetUnit(nil)
	else
		GameLib.SetTargetUnit(oldTar)
	end
	oldTar = nil
end

LeaveMod["Focus Unit"] = function(self, handler, wndHandler)
	if not oldFoc then return end
	if oldFoc == true then
		GameLib.GetPlayerUnit():SetAlternateTarget(nil)
	else
		GameLib.GetPlayerUnit():SetAlternateTarget(oldFoc)
	end
	oldFoc = nil
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
EnterMod["Dropdown Menu"] = EnterMod["Dropdown Menu"]

MouseMod["Show Hint Arrow"] = function(self, handler, ...)
	local fakeUnit = frames[handler]
	local unit = fakeUnit:GetRealUnit()
	if unit then
		unit:ShowHintArrow()
	end
end
EnterMod["Show Hint Arrow"] = EnterMod["Show Hint Arrow"]

-- HANDLE THE REGISTERED EVENTS

local function MouseMod_MouseUp(self, handler, wndHandler, wndControl, button, posx, posy)
	if wndHandler ~= wndControl then return end
	if clickAction[button] then
		self[clickAction[button]](self,handler,wndHandler)
	end
end
MouseMod.MouseUp = MouseMod_MouseUp;

local curHandler = nil
local function MouseMod_MouseEnter(self, handler, wndHandler, wndControl)
	if curHandler == handler then return end
	curHandler = handler
	
	if clickAction["over"] then
		Apollo.RemoveEventHandler("NextFrame", self)
		EnterMod[clickAction["over"]](self,handler,wndHandler)
	end
end
MouseMod.MouseEnter = MouseMod_MouseEnter;

local leftHandler = nil
local function MouseMod_MouseExit(self, handler, wndHandler, wndControl)
	if wndControl ~= wndHandler then return end
	if curHandler ~= handler then return end
	curHandler = nil
	leftHandler = handler
	
	local act = clickAction["over"]
	if act then
		if invertEnter and LeaveMod[act] then
			LeaveMod[act](self, handler, wndHandler)
		end
		if advEnter then
			Apollo.RegisterEventHandler("NextFrame", "MouseUpdate", self)
		end
	end
end
MouseMod.MouseExit = MouseMod_MouseExit;

local function MouseMod_MouseUpdate(self)
	local wndTarget = Apollo.GetMouseTargetWindow()
	if not wndTarget then --no target? -> mouseenter is basically guaranteed.
		Apollo.RemoveEventHandler("NextFrame", self)
	end
	
	local tarHandler = wndTarget:GetData()
	if tarHandler ~= leftHandler and frames[tarHandler] then
		Apollo.RemoveEventHandler("NextFrame", self)
		self:MouseEnter(tarHandler, wndTarget, wndTarget)
	end
end
MouseMod.MouseUpdate = MouseMod_MouseUpdate;

local function empty() end

function MouseMod:Off()
	self.MouseEnter = empty
	self.MouseExit = empty
	self.MouseUp = empty
	
	Apollo.RemoveEventHandler("NextFrame", self)
end

function MouseMod:On()
	self.MouseEnter = MouseMod_MouseEnter
	self.MouseExit = MouseMod_MouseExit
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
		
		f = frame.MouseExit
		frame.MouseExit = function(...)
			f(...)
			self:MouseExit(...)
		end
	end
	frames[frame] = unit
end

function MouseMod:InitMiscSettings(parent)
	local L = MRF:Localize({--English
		["ttMouse"] = [[Here you can define which action should occur, when a specific Mouse-Action was done.
			Note that most actions only work, when the Unit had been updated within your Range.]],
		["ttInv"] = [[Checking this Option makes this module try to invert mouseover-actions whenever the mouse leaves a frame again. 
			Currently working: retarget old target (Target Unit) and refocus old focus (Focus Unit).]],
		["ttAdv"] = [[With this Option on, the Module tries to more reliably detect mouseovers.
			This Option only makes sense, when the frames overlap each other(negative Spaces in Frame Handler -> Spacing).]],
	}, {--German
		["Left Click:"] = "Linksklick:",
		["Right Click:"] = "Rechtsklick:",
		["Middle Click:"] = "Mittlere Maustaste:",
		["Mouse 4 Click:"] = "Maustaste 4:",
		["Mouse 5 Click:"] = "Maustaste 5:",
		["Mouseenter (Mouseover):"] = "Mauseintritt (Mouseover):",
		["Dropdown Menu"]= "Options-Menü öffnen",
		["Target Unit"] = "Als Ziel wählen",
		["Focus Unit"] = "Als Fokus markieren",
		["Show Hint Arrow"] = "Hinweis-Pfeil zeigen",
		["ttMouse"] = [[Hier kann definiert werden, welche Aktion geschehen soll, wenn eine bestimmte Maus-Aktion getätigt wurde.
			Achtung! Die meisten Aktionen fünktionieren nur, wenn der Spieler in Reichweite aktualisiert wurde.]],
		["ttInv"] = [[Wenn diese Option gewählt wurde, versucht das Modul Mauseintritt Aktionen bei Austritt zu revidieren.
			Momentan funktioniert: Zurückwählen des alten Ziels (Als Ziel wählen) und Markieren des alten Fokus (Als Fokus markieren).]],
		["ttAdv"] = [[Bei aktivierter Option, versucht das Modul verlässlicher Mauseintritte zu erkennen.
			Diese Option ergibt nur dann Sinn, wenn die frames zum Teil übereinander liegen.(negative Abstände in Frame Handler -> Spacing)]],
		["Invert Mouseenter"] = "Mauseintritt invertieren",
		["Advanced Mouseenter"] = "Verbesserter Mauseintritt",
	}, {--French
	})

	local rowL = MRF:LoadForm("HalvedRow", parent)
	local rowR = MRF:LoadForm("HalvedRow", parent)
	local rowM = MRF:LoadForm("HalvedRow", parent)
	local row4 = MRF:LoadForm("HalvedRow", parent)
	local row5 = MRF:LoadForm("HalvedRow", parent)
	local rowOver = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("HalvedRow", parent) --empty row
	local rowInv = MRF:LoadForm("HalvedRow", parent)
	local rowAdv = MRF:LoadForm("HalvedRow", parent)
	
	rowL:FindChild("Left"):SetText(L["Left Click:"])
	rowR:FindChild("Left"):SetText(L["Right Click:"])
	rowM:FindChild("Left"):SetText(L["Middle Click:"])
	row4:FindChild("Left"):SetText(L["Mouse 4 Click:"])
	row5:FindChild("Left"):SetText(L["Mouse 5 Click:"])
	rowOver:FindChild("Left"):SetText(L["Mouseenter (Mouseover):"])
	
	MRF:LoadForm("QuestionMark", rowL:FindChild("Left")):SetTooltip(L["ttMouse"])
	MRF:LoadForm("QuestionMark", rowInv:FindChild("Left")):SetTooltip(L["ttInv"])
	MRF:LoadForm("QuestionMark", rowAdv:FindChild("Left")):SetTooltip(L["ttAdv"])
	
	local function translateAction(action) return L[action] or " - " end
	
	MRF:applyDropdown(rowL:FindChild("Right"), actions, mouse0Option, translateAction)
	MRF:applyDropdown(rowR:FindChild("Right"), actions, mouse1Option, translateAction)
	MRF:applyDropdown(rowM:FindChild("Right"), actions, mouse2Option, translateAction)
	MRF:applyDropdown(row4:FindChild("Right"), actions, mouse3Option, translateAction)
	MRF:applyDropdown(row5:FindChild("Right"), actions, mouse4Option, translateAction)
	MRF:applyDropdown(rowOver:FindChild("Right"), actions, mouseoverOption, translateAction)
	
	MRF:applyCheckbox(rowInv:FindChild("Right"), inversionOpt, L["Invert Mouseenter"])
	MRF:applyCheckbox(rowAdv:FindChild("Right"), advEnterOpt, L["Advanced Mouseenter"])
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 9*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
