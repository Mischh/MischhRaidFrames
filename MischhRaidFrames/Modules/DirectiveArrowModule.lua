--[[]]

local modKey = "Arrow Icon"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local ArrowMod, ModOptions = MRF:newModule(modKey , "icon", false)

local icons = MRF:GetModIcons(modKey)
local arrows = {} --gets updated with the icons.
local timer = ApolloTimer.Create(1, true, "OnTimer", ArrowMod)
timer:Stop()

local activeOption = MRF:GetOption(ModOptions, "activated")

local lOff, tOff, rOff, bOff = -10, -10, 10, 10
local hSizeOpt = MRF:GetOption(ModOptions, "hSize")
local vSizeOpt = MRF:GetOption(ModOptions, "vSize")

local distance, color = 0, ApolloColor.new("FFFFFFFF") 
local timeOpt = MRF:GetOption(ModOptions, "time")
local distOpt = MRF:GetOption(ModOptions, "dist")
local colorOpt = MRF:GetOption(ModOptions, "color")

function ArrowMod:UpdateActivated(active)
	if active == nil then
		activeOption:Set(true) --default to true
	elseif active then
		timer:Start()
	else
		timer:Stop()
	end
end
activeOption:OnUpdate(ArrowMod, "UpdateActivated")

--############ SIZE ############
local floor = math.floor
function ArrowMod:UpdateHSize(val)
	if type(val) ~= "number" or val<=0 then
		hSizeOpt:Set(20)
	else
		lOff = -floor(val/2)
		rOff = val+lOff
		self:UpdateAll()
	end
end
hSizeOpt:OnUpdate(ArrowMod, "UpdateHSize")

function ArrowMod:UpdateVSize(val)
	if type(val) ~= "number" or val<=0 then
		vSizeOpt:Set(20)
	else
		tOff = -floor(val/2)
		bOff = val+tOff
		self:UpdateAll()
	end
end
vSizeOpt:OnUpdate(ArrowMod, "UpdateVSize")

function ArrowMod:UpdateTime(t)
	if type(t) ~= "number" or t<0 then
		timeOpt:Set(0.1) --default
	else
		timer:Set(t, true, "OnTimer", self)
		activeOption:ForceUpdate() --make the Timer stop, if needed.
	end
end
timeOpt:OnUpdate(ArrowMod, "UpdateTime")

function ArrowMod:UpdateDistance(d)
	if type(d) ~= "number" or d<0 then
		distOpt:Set(0)
	else
		distance = d
	end
end
distOpt:OnUpdate(ArrowMod, "UpdateDistance")

function ArrowMod:UpdateColor(c)
	if not c then
		colorOpt:Set("FFFFFFFF")
	else
		color = ApolloColor.new(c)
		self:UpdateAll()
	end
end
colorOpt:OnUpdate(ArrowMod, "UpdateColor")

function ArrowMod:UpdateAll()
	for k, icon in pairs(icons) do
		icon:SetAnchorOffsets(lOff, tOff, rOff, bOff)
		arrows[k]:SetBGColor(color)
	end
end

do
	--apply size on creation of icons.
	local meta = getmetatable(icons)
	local orig = meta.__index
	meta.__index = function(t,k)
		local icon = orig(t,k)
		icon:SetAnchorOffsets(lOff, tOff, rOff, bOff)
		arrows[k] = MRF:LoadForm("ArrowForm", icon)
		arrows[k]:SetBGColor(color)
		
		return icon
	end
	setmetatable(icons, meta)
	
	
	ArrowMod:UpdateAll() --if there are actually some already created.
	for k, icon in pairs(icons) do --for all previous loaded Icons. Can this even Happen?!
		arrows[k] = MRF:LoadForm("ArrowForm", icon)
	end
end

MRF:OnceDocLoaded(function()
	Apollo.LoadSprites("textures/ArrowTexture.xml")
end)

--############ ICON ############
local cache = {} --[frame] = unit
function ArrowMod:iconUpdate(frame, unit)
	cache[frame] = unit
end

function ArrowMod:OnTimer()
	for frame, unit in pairs(cache) do
		self:Update(frame, unit)
	end
end

local acos = math.acos
local twopi = math.pi*2
function ArrowMod:Update(frame, unit)
	local show = false
	local icon = icons[frame.frame] --DONT REMOVE! this creates arrows[frame.frame]
	
	local tTbl = unit:GetPosition()
	if tTbl then
		show = true
		local tVec = Vector2.New(tTbl.x, tTbl.z)
		
		local p = GameLib.GetPlayerUnit()
	  	local pTbl = p:GetPosition()
	  	local pVec = Vector2.New(pTbl.x, pTbl.z)
	
	  	local dirVec = tVec - pVec
	
		show = self:CheckDistance(dirVec)
		if show then
			dirVec = dirVec:NormalFast()
		
		  	local facTbl = p:GetFacing()
		  	local facVec = Vector2.New(facTbl.x, facTbl.z)
		
		  	local angle = acos(Vector2.Dot(dirVec,facVec) / (dirVec:Length() * facVec:Length()))
		
		  	local turn = dirVec.x * facVec.y - dirVec.y * facVec.x
		  	if turn<0 then
		    	angle = twopi-angle
		 	end
		
			self:ChooseArrow(arrows[frame.frame], angle)
		end
	end
	icon:Show(show)
end

function ArrowMod:CheckDistance(vec)
	return vec:Length() > distance
end

--angle is from 0 to twopi.
function ArrowMod:ChooseArrow(form, angle)
	local idx = math.floor(angle/(2*math.pi)*108)
	
	local row = floor(idx/9)
	local col = idx%9
	form:SetAnchorPoints(-col, -row, 9-col, 12-row)
end

function ArrowMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["ttTime"] = [[This Module does not use the normal 'frequent updates', because even they would be too slow (in most cases) to make the arrows look good. Select the Time in between two Updates.]],
		["ttDist"] = [[You can choose to only show arrows for units of more than this distance.]],
	}, {--German
		["Width:"] = "Breite:",
		["Height:"] = "Höhe:",
		["Time between Updates:"] = "Zeit zwischen Aktualisierungen:",
		["Minimal Distance:"] = "Minimale Distanz:",
		["Color of Arrow:"] = "Farbe des Pfeils:",
		["ttTime"] = [[Dieses Modul nutzt nicht die normalen Aktualisierungsmethoden, da sie in den meisten Fällen zu langsam für diesen Pfeil wären. Hier kann die Zeit zwischen zwei Aktualisierungen des selben Pfeils ausgewählt werden.]],
		["ttDist"] = [[Es kann gewählt werden, ab welcher Distanz frühestens ein Pfeil gezeigt werden soll.]]
	}, {--French
	})

	local hRow = MRF:LoadForm("HalvedRow", parent)
	local wRow = MRF:LoadForm("HalvedRow", parent)
	
	wRow:FindChild("Left"):SetText(L["Width:"])
	hRow:FindChild("Left"):SetText(L["Height:"])
	MRF:applySlider(wRow:FindChild("Right"), hSizeOpt, 1, 100, 1)
	MRF:applySlider(hRow:FindChild("Right"), vSizeOpt, 1, 100, 1)
	
	MRF:LoadForm("HalvedRow", parent) --spacing
	
	local timeRow = MRF:LoadForm("HalvedRow", parent)
	local distRow = MRF:LoadForm("HalvedRow", parent)
	local colorRow = MRF:LoadForm("HalvedRow", parent)
	timeRow:FindChild("Left"):SetText(L["Time between Updates:"])
	distRow:FindChild("Left"):SetText(L["Minimal Distance:"])
	colorRow:FindChild("Left"):SetText(L["Color of Arrow:"])
	MRF:applySlider(timeRow:FindChild("Right"), timeOpt, 0, 3, 0.1, true)
	MRF:applySlider(distRow:FindChild("Right"), distOpt, 0, 100, 1)
	MRF:applyColorbutton(colorRow:FindChild("Right"), colorOpt)
	
	MRF:LoadForm("QuestionMark", timeRow:FindChild("Left")):SetTooltip(L["ttTime"])
	MRF:LoadForm("QuestionMark", distRow:FindChild("Left")):SetTooltip(L["ttDist"])
	
	local anchor = {parent:GetAnchorOffsets()}
	local children = parent:GetChildren()
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end




