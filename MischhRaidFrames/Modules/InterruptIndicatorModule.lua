--[[]]

local modKey = "Interrupt Indicator"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local IntMod, ModOptions = MRF:newModule(modKey , "misc", false)

local edgeOpt = MRF:GetOption(ModOptions, "edge")
local edgemode = true
edgeOpt:OnUpdate(IntMod, "NewEdgeMode")
function IntMod:NewEdgeMode(mode)
	if mode == nil then
		edgeOpt:Set(false)
	else
		edgemode = mode
		self:UpdateAll()
	end
end

local hPosOpt = MRF:GetOption(ModOptions, "horizontalPos")
local vPosOpt = MRF:GetOption(ModOptions, "verticalPos")
local hPos = 0
local vPos = 0
hPosOpt:OnUpdate(IntMod, "NewHPos")
vPosOpt:OnUpdate(IntMod, "NewVPos")
function IntMod:NewHPos(val)
	if type(val) ~= "number" then
		hPosOpt:Set(0)
	else
		hPos = val
		self:UpdateAll()
	end
end
function IntMod:NewVPos(val)
	if type(val) ~= "number" then
		vPosOpt:Set(0.5)
	else
		vPos = val
		self:UpdateAll()
	end
end

local lOpt = MRF:GetOption(ModOptions, "leftOffset")
local tOpt = MRF:GetOption(ModOptions, "topOffset")
local rOpt = MRF:GetOption(ModOptions, "rightOffset")
local bOpt = MRF:GetOption(ModOptions, "bottomOffset")
local l,t,r,b = 0,-2,0,-2
lOpt:OnUpdate(IntMod, "NewLeft")
tOpt:OnUpdate(IntMod, "NewTop")
rOpt:OnUpdate(IntMod, "NewRight")
bOpt:OnUpdate(IntMod, "NewBottom")
function IntMod:NewLeft(val)
	if type(val) ~= "number" then
		lOpt:Set(-50)
	else
		l = val; self:UpdateAll()
	end
end
function IntMod:NewTop(val)
	if type(val) ~= "number" then
		tOpt:Set(-6)
	else
		t = val; self:UpdateAll()
	end
end
function IntMod:NewRight(val)
	if type(val) ~= "number" then
		rOpt:Set(50)
	else
		r = val; self:UpdateAll()
	end
end
function IntMod:NewBottom(val)
	if type(val) ~= "number" then
		bOpt:Set(-3)
	else
		b = val; self:UpdateAll()
	end
end

local cOpt = MRF:GetOption(ModOptions, "color")
local c = ApolloColor.new("FFBFBFBF")
cOpt:OnUpdate(IntMod, "NewColor")
function IntMod:NewColor(col)
	if not col then
		cOpt:Set("FFFFFFFF")
	else
		c = ApolloColor.new(col); self:UpdateAll()
	end
end

local dispOpt = MRF:GetOption(ModOptions, "disptime")
local dispTime = 3
dispOpt:OnUpdate(IntMod, "NewTime")
function IntMod:NewTime(time)
	if type(time) ~= "number" or time <= 0 then
		dispOpt:Set(3)
	else
		dispTime = time
	end
end

local actOpt = MRF:GetOption(ModOptions, "activated")
actOpt:OnUpdate(IntMod, "Activated")
function IntMod:Activated(isActive)
	if isActive == nil then
		actOpt:Set(false)
	elseif not isActive then
		self:HideAll()
	end
end

local frames_back = setmetatable({}, {__index = function(tbl, parent) 
	local frame = MRF:LoadForm("Window", parent)
	if edgemode then
		frame:SetAnchorPoints(hPos,vPos,1+hPos,1+vPos);
	else
		frame:SetAnchorPoints(0.5+hPos,0.5+vPos,0.5+hPos,0.5+vPos);
	end
	frame:SetAnchorOffsets(l,t,r,b);
	parent:SendChildToBottom(frame)
	
	frame:SetSprite("WhiteFill")
	frame:SetBGColor(c)
	frame:Show(false)
	
	rawset(tbl, parent, frame)
	return frame
end})

local frames_fore = setmetatable({}, {__index = function(tbl, parent) 
	local frame = MRF:LoadForm("IconTemplate", parent)
	if edgemode then
		frame:SetAnchorPoints(hPos,vPos,1+hPos,1+vPos);
	else
		frame:SetAnchorPoints(0.5+hPos,0.5+vPos,0.5+hPos,0.5+vPos);
	end
	frame:SetAnchorOffsets(l,t,r,b);
		
	frame:SetSprite("WhiteFill")
	frame:SetBGColor(c)
	frame:Show(false)
	
	rawset(tbl, parent, frame)
	return frame
end})

local backOpt = MRF:GetOption(ModOptions, "backdropped")
local backdropped = true
backOpt:OnUpdate(IntMod, "NewBackMode")
function IntMod:NewBackMode(val)
	if val == nil then
		backOpt:Set(false)
	elseif backdropped ~= val then
		backdropped = val
		for idx, indicator in pairs(frames_back) do --switch the 'shown'-State 
			local x = indicator:IsShown()
			indicator:Show(frames_fore[idx]:IsShown())
			frames_fore[idx]:Show(x)
		end
	end
end

function IntMod:HideAll()
	for i,frame in pairs(frames_fore) do
		frame:Show(false)
	end
	for i,frame in pairs(frames_back) do
		frame:Show(false)
	end
end
function IntMod:UpdateAll()
	for i,frame in pairs(frames_fore) do
		if edgemode then
			frame:SetAnchorPoints(hPos,vPos,1+hPos,1+vPos);
		else
			frame:SetAnchorPoints(0.5+hPos,0.5+vPos,0.5+hPos,0.5+vPos);
		end
		frame:SetAnchorOffsets(l,t,r,b)
		frame:SetBGColor(c)
	end
	for i,frame in pairs(frames_back) do
		if edgemode then
			frame:SetAnchorPoints(hPos,vPos,1+hPos,1+vPos);
		else
			frame:SetAnchorPoints(0.5+hPos,0.5+vPos,0.5+hPos,0.5+vPos);
		end
		frame:SetAnchorOffsets(l,t,r,b)
		frame:SetBGColor(c)
	end
end

local loaded = false
MRF:OnceDocLoaded(function() 
	loaded = true
	if actOpt:Get() then
		Apollo.RegisterEventHandler("CombatLogVitalModifier", "VitalChange", IntMod)
		Apollo.RegisterEventHandler("CombatLogCCState", "CCStateChange", IntMod)
	end
end)

actOpt:OnUpdate(IntMod, "ActivateEvents")
function IntMod:ActivateEvents(isActive)
	if loaded then
		if isActive then
			Apollo.RegisterEventHandler("CombatLogVitalModifier", "VitalChange", self)
			Apollo.RegisterEventHandler("CombatLogCCState", "CCStateChange", self)
		else
			Apollo.RemoveEventHandler("CombatLogVitalModifier", self)
			Apollo.RemoveEventHandler("CombatLogCCState", self)
		end
	end
end

local nametbl = {} --[name] = idx & [idx] = name
local foretbl = {} --[idx] = indicator (foreground)
local backtbl = {} --[idx] = indicator (background)
local timertbl = setmetatable({}, {__index = function(self, idx) 
	local timer = ApolloTimer.Create(1, false, tostring(idx), self)
	timer:Stop()
	
	self[tostring(idx)] = function()
		foretbl[idx]:Show(false)
		backtbl[idx]:Show(false)
	end
	
	rawset(self, idx, timer)
	return timer
end}) 

local vitalIA = GameLib.CodeEnumVital.InterruptArmor
function IntMod:VitalChange(e)
	local res, err = pcall(function()
	if e.eVitalType == vitalIA and e.unitCaster and e.nAmount < 0 then
		local idx = nametbl[e.unitCaster:GetName()]
		if idx then
			self:Start(idx)
		end
	end
	end)
	if not res then print(err) end
end

local blockedIds = { --copied from VinceRaidFrames, there are maybe more i do not know about.
	[19190] = true -- Esper's Fade Out
}

function IntMod:CCStateChange(e)
	local res, err = pcall(function()
	if e.nInterruptArmorHit > 0 and e.unitCaster then
		local idx = nametbl[e.unitCaster:GetName()]
		if idx and not blockedIds[e.splCallingSpell:GetBaseSpellId()] then
			self:Start(idx)
		end
	end
	end)
	if not res then print(err) end
end

function IntMod:Start(idx)
	local t = timertbl[idx]
	t:Stop()
	t:Set(dispTime, false, tostring(idx), timertbl)
	t:Start()
	if backdropped then	
		backtbl[idx]:Show(true)
	else
		foretbl[idx]:Show(true)
	end
end

function IntMod:miscUpdate(frame, unit)
	local idx = unit:GetMemberIdx()
	local name = unit:GetName()
	
	backtbl[idx] = frames_back[frame.frame]
	foretbl[idx] = frames_fore[frame.frame]
	
	if nametbl[idx] ~= name then
		nametbl[nametbl[idx] or ""] = nil
		nametbl[name] = idx
		nametbl[idx] = name
		
		timertbl[idx]:Stop()
		backtbl[idx]:Show(false)
		foretbl[idx]:Show(false)
	end
end

function IntMod:InitMiscSettings(parent)
	local L = MRF:Localize({--English
		["ttOffset"] = [[These Offsets are always from the Edge of each frame. Going positive moves the edges right/bottom.]],
		["ttCombat"] = [[This module requires the full combat log, which does not only include the Player, but also all his Partymembers and many more. Activate this to make this module useful.]],
		["ttBack"] = [[You can either choose to have this Indicator backdropped behind the frame (like Dispel-Indicator) or in front of the frame (like Icons)]],
		["ttEdge"] = [[Choose whether the Indicator covers (without changes to Position/Offsets) the size of the whole Frame or is a simple centered Point]],
		["ttPos"] = [[Move the whole Indicator Left/Right and Up/Down. Positive is Right and Down.]]
	}, {--German
		["ttMouse"] = [[Diese Abstände sind immer relativ zum jeweiligen Rand. Positive Werte verschieben dabei nach rechts bzw. unten.]],
		["ttCombat"] = [[Dieses Modul benötigt Einsicht in den kompletten Combatlog, damit dieser nicht nur den Spieler, sondern auch Gruppenmitglieder und weitere Einheiten enthält. Aktiviere diese Option, um dieses Modul nützlich zu machen.]],
		["ttBack"] = [[Dieser Indikator kann entweder hinter das Frame (wie der Dispel-Indokator) oder vor das Frame (wie ein Icon) gelegt werden.]],
		["ttEdge"] = [[Es kann gewählt werden, ob der Indikator im unveränderten Zustand die Fläche des kompletten Frames einnimmt, oder nur ein zentrierter Punkt ist.]],
		["ttPos"] = [[Bewegt den gesamten Indikator Links/Rechts bzw. Hoch/Runter. Positive Werte gehen dabei nach Rechts/Unten.]],
		["Log other Players"] = "Logge andere Spieler",
		["Duration to be shown:"] = "Angezeigte Zeitspanne:",
		["Indicators Color:"] = "Farbe des Indikators:",
		["Backdrop Indicator"] = "Hinter das Frame",
		["Offset from Edge"] = "Von Rändern Ausrichten",
		["Horizontal Position:"] = "Horizontale Position:",
		["Vertical Position:"] = "Vertikale Position:",
		["Offset Left:"] = "Abstand Links:",
		["Offset Right:"] = "Abstand Rechts:",
		["Offset Top:"] = "Abstand Oben:",
		["Offset Bottom:"] = "Abstand Unten:",
	}, {--French
	})

	local logOpt = MRF:GetOption("cmbtlog.disableOtherPlayers")
	logOpt:Set(not Apollo.GetConsoleVariable("cmbtlog.disableOtherPlayers"))
	logOpt:OnUpdate(function(b) 
		Apollo.SetConsoleVariable("cmbtlog.disableOtherPlayers", not b)
	end)
	
	local rowLog = MRF:LoadForm("HalvedRow", parent)
	local rowDur = MRF:LoadForm("HalvedRow", parent)
	local rowCol = MRF:LoadForm("HalvedRow", parent)
	
	local rowBack = MRF:LoadForm("HalvedRow", parent)
	local rowEdge = MRF:LoadForm("HalvedRow", parent)
	local rowHPos = MRF:LoadForm("HalvedRow", parent)
	local rowVPos = MRF:LoadForm("HalvedRow", parent)
	
	local rowL = MRF:LoadForm("HalvedRow", parent)
	local rowR = MRF:LoadForm("HalvedRow", parent)
	local rowT = MRF:LoadForm("HalvedRow", parent)
	local rowB = MRF:LoadForm("HalvedRow", parent)
	
	MRF:LoadForm("QuestionMark", rowLog:FindChild("Left")):SetTooltip(L["ttCombat"])
	MRF:LoadForm("QuestionMark", rowBack:FindChild("Left")):SetTooltip(L["ttBack"])
	MRF:LoadForm("QuestionMark", rowEdge:FindChild("Left")):SetTooltip(L["ttEdge"])
	MRF:LoadForm("QuestionMark", rowHPos:FindChild("Left")):SetTooltip(L["ttPos"])
	MRF:LoadForm("QuestionMark", rowL:FindChild("Left")):SetTooltip(L["ttMouse"])
	
	
	rowDur:FindChild("Left"):SetText(L["Duration to be shown:"])
	rowCol:FindChild("Left"):SetText(L["Indicators Color:"])
	rowHPos:FindChild("Left"):SetText(L["Horizontal Position:"])
	rowVPos:FindChild("Left"):SetText(L["Vertical Position:"])
	rowL:FindChild("Left"):SetText(L["Offset Left:"])
	rowR:FindChild("Left"):SetText(L["Offset Right:"])
	rowT:FindChild("Left"):SetText(L["Offset Top:"])
	rowB:FindChild("Left"):SetText(L["Offset Bottom:"])
	
	MRF:applyCheckbox(rowLog:FindChild("Right"), logOpt, L["Log other Players"])
	MRF:applySlider(rowDur:FindChild("Right"), dispOpt, 1, 60, 1, true, false, true) --textbox: ignore steps, no pos limit
	MRF:applyColorbutton(rowCol:FindChild("Right"), cOpt)
	MRF:applyCheckbox(rowBack:FindChild("Right"), backOpt, L["Backdrop Indicator"])
	MRF:applyCheckbox(rowEdge:FindChild("Right"), edgeOpt, L["Offset from Edge"])
	MRF:applySlider(rowHPos:FindChild("Right"), hPosOpt, -0.75, 0.75, 0.01, true) --textbox: ignore steps
	MRF:applySlider(rowVPos:FindChild("Right"), vPosOpt, -0.75, 0.75, 0.01, true)
	MRF:applySlider(rowL:FindChild("Right"), lOpt, -25, 25, 1, false, true)--textbox: use steps, unlimited values
	MRF:applySlider(rowR:FindChild("Right"), rOpt, -25, 25, 1, false, true)
	MRF:applySlider(rowT:FindChild("Right"), tOpt, -25, 25, 1, false, true)
	MRF:applySlider(rowB:FindChild("Right"), bOpt, -25, 25, 1, false, true)
	
	logOpt:ForceUpdate()
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 11*30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

