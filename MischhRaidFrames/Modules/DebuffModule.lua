--[[]]

local modKey = "Debuffs"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local BuffMod, ModOptions = MRF:newModule(modKey , "icon", true)
BuffMod.names = {}; BuffMod.ids = {}

local actOpt = MRF:GetOption(ModOptions, "activated")
actOpt:OnUpdate(BuffMod, "UpdateActiveMod")
function BuffMod:UpdateActiveMod(act)
	if act == nil then 
		actOpt:Set(false) --default
	elseif not act then
		BuffMod:DeactivateMod()
	end
	
	--i know this looks stupid, it is and i really hate it.
	--there seems to be some kind of problem, why i need it, dont get it...
	MRF:GetOption(ModOptions, "buffs"):ForceUpdate() 
end

local buffs = {}
local buffTblOpt = MRF:GetOption(ModOptions, "buffs")
buffTblOpt:OnUpdate(BuffMod, "UpdateBuffTbl")
function BuffMod:UpdateBuffTbl(tbl)
	if type(tbl) ~= "table" or #tbl < 1 then
		buffTblOpt:Set({self:GetDefaultBuff()})
	else
		buffs = tbl;
		self.names = {}
		self.ids = {}
		for i, buff in ipairs(buffs) do
			if buff.isSpellID then
				local num = tonumber(buff.spellName)
				if num then
					self.ids[num] = self.ids[num] or {}
					self.ids[num][#self.ids[num]+1] = buff
				end
			elseif buff.spellName then
				self.names[buff.spellName] = self.names[buff.spellName] or {}
				self.names[buff.spellName][#self.names[buff.spellName]+1] = buff
			end
		end
		
		self:UpdateIcons()
	end
end

function BuffMod:CreateIcon(parent)
	local x = MRF:LoadForm("IconTemplate", parent)
	x:SetSprite("WhiteFill")
	return x
end
local icons = setmetatable({}, {__index = function(self,parent)
	local tbl = {}
	for idx, buff in ipairs(buffs) do
		tbl[idx] = BuffMod:CreateIcon(parent)
		BuffMod:UpdateSize(tbl[idx], buff.ySiz, buff.xSiz)
		BuffMod:UpdatePosition(tbl[idx], buff.xPos, buff.yPos)
		tbl[idx]:SetBGColor(ApolloColor.new(buff.color))
		tbl[idx]:SetTextColor(ApolloColor.new(buff.textColor))
	end
	rawset(self, parent, tbl)
	return tbl
end})
function BuffMod:UpdateIcons()
	for parent, tbl in pairs(icons) do
		for idx, buff in ipairs(buffs) do
			tbl[idx] = tbl[idx] or self:CreateIcon(parent)
			self:UpdateSize(tbl[idx], buff.ySiz, buff.xSiz)
			self:UpdatePosition(tbl[idx], buff.xPos, buff.yPos)
			tbl[idx]:SetBGColor(ApolloColor.new(buff.color))
			tbl[idx]:SetTextColor(ApolloColor.new(buff.textColor))
		end
		for idx = #buffs+1, #tbl, 1 do
			tbl[idx]:Show(false)
		end
	end
end

function BuffMod:DeactivateMod()
	for parent, tbl in pairs(icons) do
		for idx, icon in ipairs(tbl) do
			icon:Show(false)
		end
	end
end


local floor = math.floor
function BuffMod:UpdateSize(icon, height, width)
	if height and width then
		local t = -floor(height/2)
		local b = height+t
		local l = -floor(width/2)
		local r = width+l
		icon:SetAnchorOffsets(l,t,r,b)
	elseif height then
		local l,t,r,b = icon:GetAnchorOffsets()
		t = -floor(height/2)
		b = height+t
		icon:SetAnchorOffsets(l,t,r,b)
	elseif width then
		local l,t,r,b = icon:GetAnchorOffsets()
		l = -floor(width/2)
		r = width+l
		icon:SetAnchorOffsets(l,t,r,b)
	end
end

function BuffMod:UpdatePosition(icon, x, y)
	if x and y then
		icon:SetAnchorPoints(x,y,x,y)
	elseif x then
		local _, y = icon:GetAnchorPoints()
		icon:SetAnchorPoints(x,y,x,y)
	elseif y then
		local x = icon:GetAnchorPoints()
		icon:SetAnchorPoints(x,y,x,y)
	end
end

function BuffMod:GetDefaultBuff()
	return {
		name = "Debuff",
		spellName = "Debuffs Name",
		isSpellID = false,
		xPos = 0,
		yPos = 0,
		xSiz = 10,
		ySiz = 10,
		color = "FFFFFFFF",
		pattern = "",
		textColor = "FFFFFFFF",
		stackLimit = nil,
		stackComp = "<",
		timeLimit = nil,
		timeComp = "<",
	}
end

function BuffMod:iconUpdate(frame, unit)
	local show = {} --[buff] = true
	local info = {} --[buff] = {s = 123, t = 234}
	
	local unitBuffs = unit:GetBuffs()
	if not unitBuffs then return end
	
	for _, buff in ipairs(unitBuffs.arHarmful) do
		local tblName = self.names[buff.splEffect:GetName()]
		local tblID = self.ids[buff.splEffect:GetId()]
		for i, b in ipairs(tblName or {}) do
			show[b] = show[b] or self:CheckBuff(buff, b, info) or nil
		end
		for i, b in ipairs(tblID or {}) do
			show[b] = show[b] or self:CheckBuff(buff, b, info) or nil
		end
	end
	
	for i, buff in ipairs(buffs) do
		icons[frame.frame][i]:Show(show[buff] or false)
		if show[buff] then
			self:ApplyText(icons[frame.frame][i], buff.pattern, info[buff])
		end
	end
end

--retrieve Playername:
do
	local f = BuffMod.iconUpdate;
	BuffMod.iconUpdate = function(self, ...)
		local plr = GameLib.GetPlayerUnit()
		if plr then 
			self.playerName = plr:GetName()
			self.iconUpdate = f;
		end
		
		f(self, ...)
	end
end

local comps = {
	["<"] =  function(a,b) return a<b  end,
	[">"] =  function(a,b) return a>b  end,
	["<="] = function(a,b) return a<=b end,
	[">="] = function(a,b) return a>=b end,
	["=="] = function(a,b) return a==b end,
	["!="] = function(a,b) return a~=b end,
}

function BuffMod:CheckBuff(buff, buffTbl, info)
	local ret = true
	if buffTbl.stackLimit and buffTbl.stackComp then
		ret = ret and comps[buffTbl.stackComp](buff.nCount, buffTbl.stackLimit)
	end
	if buffTbl.timeLimit and buffTbl.timeComp then
		ret = ret and comps[buffTbl.timeComp](buff.fTimeRemaining, buffTbl.timeLimit)
	end
	
	if ret then --fill info
		info[buffTbl] = info[buffTbl] or {stacks = 0, time = 0}
		info[buffTbl].stacks = info[buffTbl].stacks + buff.nCount
		if buff.fTimeRemaining > 0 then
			info[buffTbl].time = (info[buffTbl].time == 0 or info[buffTbl].time > buff.fTimeRemaining) and buff.fTimeRemaining or info[buffTbl].time
		end
	end
	
	return ret
end

local floor = math.floor
local patterns = setmetatable({ --makes the text pattern easier & faster
	_h = function(tbl) return floor(tbl.t/3600) end,
	_m = function(tbl) return floor(tbl.t/60)%60 end,
	_s = function(tbl) return tbl.t%60 end,
} , { __index = function(tbl, key)
	local f = rawget(tbl, "_"..key) -- see functions above. 
	if f then
		return f(tbl)
	else
		rawset(tbl, key, key) --invalid stuff will stay invalid - just save this funcs return.
		return key;-- if ppl do invalid stuff, the key will be returned (this will make %% work aswell)
	end
end})
function BuffMod:ApplyText(icon, pattern, info)
	patterns["n"] = info.stacks
	patterns["t"] = floor(info.time)
	
	icon:SetText((pattern or ""):gsub("%%(.)", patterns))	
end

function BuffMod:InitIconSettings(parent)
	local L = MRF:Localize({--English
		["ttName"] = [[Set a Name to identify this icon. Changing this will not alter anything on the Icons behavior.]],
		["ttSpell"] = [[Enter the buffs name or the SpellID to search for. This is case-sensitive and should be the exact name/SpellID of the buff. To enter a SpellID you should check the box below.]],
		["ttPosition"] = [[Choose a position and the size of the Icon.]],
		["ttLimit"] = [[You can make the Icon to be only shown whenever stacks and/or time meet a certain criteria. Note that non-number(or empty) values disable this.]],
		["ttPattern"] = [[To apply a text to this Icon, you can choose a pattern. Within this pattern specific characters will be replaced:
			%n = Stacks of this Buff (Sum of all*)
			%t = Left time in seconds (Shortest of all*)
			%h, %m, %s = the time split up in hours, minutes and seconds.
			
			*'all' references every buff meeting the criteria of this icon.
		]],
	}, {--German
		["Add"] = "Neu",
		["Remove"] = "Entf.",
		["Icons Name:"] = "Name des Icons:",
		["SpellName / SpellID:"] = "SpellName / SpellID:",
		["Is SpellID"] = "Ist SpellID",
		["Horizontal Position:"] = "Horizontale Position:",
		["Vertical Position:"] = "Vertikale Position:",
		["Height:"] = "Höhe:",
		["Width:"] = "Breite:",
		["Icons Color:"] = "Farbe des Icons:",
		["Text Pattern:"] = "Text Schema:",
		["Text Color:"] = "Text Farbe:",
		["Stacks Comparator:"] = "Vergleichsmethode, Stapel:",
		["Stacks compare value:"] = "Vergleichswert, Stapel:",
		["Time Comparator:"] = "Vergleichsmethode, Zeit:",
		["Time compare value:"] = "Vergleichswert, Zeit:",
		["stacks "] = "Stapel ",
		["time "] = "Zeit ",
		[" value"] = " Wert",
		["ttName"] = [[Wähle einen Namen um dieses Icon zu identifizieren. Verändern des Namens hat keinen Einfluss auf das Verhalten.]],
		["ttSpell"] = [[Füge hier den Namen des Buffs bzw. die SpellID ein. Achtung! Der Name muss exakt mit dem des Buffs übereinstimmen. Um eine SpellID zu verwenden, sollte der Hacken unten gesetzt sein.]],
		["ttPosition"] = [[Setze eine Position, sowie die Größe dieses Icons.]],
		["ttLimit"] = [[Es ist möglich das Icon nur dann zu zeigen, wenn der Buff bestimmte Stapel bzw. eine bestimmte Restzeit hat. Werte, die keine Zahl darstellen deaktivieren diese Funktion.]],
		["ttPattern"] = [[Mit einem hier gewählten Schema kann der Text auf dem Icon gewählt werden. Innerhlab dieses Schemas werden bestimmte Zeichenkombinationen ersetzt:
			%n = Stapel dieses Buffs (Summe über alle*)
			%t = Restliche Zeit in Sekunden (Kürzeste aller*)
			%h, %m, %s = Restzeit aufgeteilt in Stunden, Minuten und Sekunden
			
			*'alle' referenziert auf alle Buffs, die die Kriterien dieses Icons erfüllen.
		]]
	}, {--French
	})

	--### Hack into the default Icon-Settings for Dropdown, Add and Remove Button.
	local def_tab = parent:GetParent():FindChild("DefaultTab")
	local def_selRow = MRF:LoadForm("HalvedRow", def_tab)
	def_selRow:SetAnchorPoints(0.5,0,1,0)
	def_selRow:SetAnchorOffsets(def_tab:FindChild("CheckboxActivated"):GetAnchorOffsets())
	
		--Selecting Dropdown
	local selector, selected = MRF:SelectRemote("Debuffs_SelectedBuff", buffTblOpt)
	local selection = {} 
	local function double1st(f,s,...)
		return f,f,...
	end
	local function dblIndex(func, ...)
		local replacing = function(...)
			return double1st(func(...))
		end
		return replacing , ...	
	end
	function selection:ipairs() 			--i know looks complicated, but its essentially a ipairs on buffs,
		return dblIndex(ipairs(buffs))		--which returns the key as the first two arguements.
	end
	local function selectTrans(idx)
		return buffs[idx] and buffs[idx].name or " - "
	end
	MRF:applyDropdown(def_selRow:FindChild("Right"), selection,  selector, selectTrans, selected)
	
		--Add/Remove Buttons
	local def_btnRow = MRF:LoadForm("HalvedRow", def_selRow:FindChild("Left"))
	local btn_rem = MRF:LoadForm("Button", def_btnRow:FindChild("Right"), {ButtonClick = function(self, wndH, wndC)
		if wndH ~= wndC then return end
		local idx = selector:Get()
		table.remove(buffs, idx)
		selector:Set(idx>#buffs and #buffs or idx)
		
		buffTblOpt:ForceUpdate()
	end})
	btn_rem:SetText(L["Remove"]) 
	MRF:LoadForm("Button", def_btnRow:FindChild("Left"), {ButtonClick = function(self, wndH, wndC) 
		if wndH ~= wndC then return end
		table.insert(buffs, BuffMod:GetDefaultBuff())
		selector:Set(#buffs)
		
		buffTblOpt:ForceUpdate()
	end}):SetText(L["Add"])
	
	buffTblOpt:OnUpdate(function(tbl)
		if not tbl or  #tbl>1 then
			btn_rem:Enable(true)
		else
			btn_rem:Enable(false)
		end
	end)
	
		--disable the original Sliders: (aka Hide them)
	local l,t,r,b = def_tab:GetAnchorOffsets()
	def_tab:SetAnchorOffsets(l,t,r,b-70)
	def_tab:FindChild("SliderX"):Show(false)
	def_tab:FindChild("SliderY"):Show(false)
	
	def_tab:GetParent():ArrangeChildrenVert()
	--### End Hack
	
	
	--### Preview Workarounds:
	local xPos = MRF:GetOption(selected, "xPos")
	local yPos = MRF:GetOption(selected, "yPos")
	local xSiz = MRF:GetOption(selected, "xSiz")
	local ySiz = MRF:GetOption(selected, "ySiz")
	
	xPos:OnUpdate(MRF:GetOption(ModOptions, "xOffset"), "Set")
	yPos:OnUpdate(MRF:GetOption(ModOptions, "yOffset"), "Set")
	
	local prevIcons = MRF:GetModIcons(modKey)
	do
		local meta = getmetatable(prevIcons)
		local idx = meta.__index
		meta.__index = function(...)
			local icon = idx(...)
			BuffMod:UpdateSize(icon, ySiz:Get(), xSiz:Get())
			return icon
		end
		setmetatable(prevIcons, meta)
	end
	xSiz:OnUpdate(function(w)
		for _, icon in pairs(prevIcons) do
			BuffMod:UpdateSize(icon, nil, w)
		end
	end)
	
	ySiz:OnUpdate(function(h)
		for _, icon in pairs(prevIcons) do
			BuffMod:UpdateSize(icon, h, nil)
		end
	end)
	
	--### End Workarounds
	
	--Name
	local nameOpt = MRF:GetOption(selected, "name")
	local nameRow = MRF:LoadForm("HalvedRow", parent)
	nameRow:FindChild("Left"):SetText(L["Icons Name:"])
	MRF:applyTextbox(nameRow:FindChild("Right"), nameOpt)
	
	MRF:LoadForm("QuestionMark", nameRow:FindChild("Left")):SetTooltip(L["ttName"])
	
	--SpellName
	local spellOpt = MRF:GetOption(selected, "spellName")
	local spellRow = MRF:LoadForm("HalvedRow", parent)
	spellRow:FindChild("Left"):SetText(L["SpellName / SpellID:"])	
	MRF:applyTextbox(spellRow:FindChild("Right"), spellOpt)	
	
	MRF:LoadForm("QuestionMark", spellRow:FindChild("Left")):SetTooltip(L["ttSpell"])
	
	--Ckeckboxes
	local checkRow = MRF:LoadForm("HalvedRow", parent)
	local isSpOpt = MRF:GetOption(selected, "isSpellID")
	MRF:applyCheckbox(checkRow:FindChild("Left"), isSpOpt, L["Is SpellID"])
	
	
	--Position
	local hPosRow = MRF:LoadForm("HalvedRow", parent)
	local vPosRow = MRF:LoadForm("HalvedRow", parent)
	hPosRow:FindChild("Left"):SetText(L["Horizontal Position:"])
	vPosRow:FindChild("Left"):SetText(L["Vertical Position:"])
	MRF:applySlider(hPosRow:FindChild("Right"), xPos, -0.5,1.5, 0.01, true)
	MRF:applySlider(vPosRow:FindChild("Right"), yPos, -0.5,1.5, 0.01, true)
	
	MRF:LoadForm("QuestionMark", hPosRow:FindChild("Left")):SetTooltip(L["ttPosition"])
	
	--Size
	local vSizeRow = MRF:LoadForm("HalvedRow", parent)
	local hSizeRow = MRF:LoadForm("HalvedRow", parent)
	vSizeRow:FindChild("Left"):SetText(L["Height:"])
	hSizeRow:FindChild("Left"):SetText(L["Width:"])
	MRF:applySlider(vSizeRow:FindChild("Right"), ySiz, 1, 50, 1, false, false, true) --textbox: no pos limit
	MRF:applySlider(hSizeRow:FindChild("Right"), xSiz, 1, 50, 1, false, false, true)
	
	--Color
	
	local colorOpt = MRF:GetOption(selected, "color")
	local colorRow = MRF:LoadForm("HalvedRow", parent)
	colorRow:FindChild("Left"):SetText(L["Icons Color:"])
	MRF:applyColorbutton(colorRow:FindChild("Right"), colorOpt)
	
	--Text pattern
	local patternOpt = MRF:GetOption(selected, "pattern")
	local patternRow = MRF:LoadForm("HalvedRow", parent)
	patternRow:FindChild("Left"):SetText(L["Text Pattern:"])
	MRF:applyTextbox(patternRow:FindChild("Right"), patternOpt)
	
	MRF:LoadForm("QuestionMark", patternRow:FindChild("Left")):SetTooltip(L["ttPattern"])
	
	--Text color
	local tcolorOpt = MRF:GetOption(selected, "textColor")
	local tcolorRow = MRF:LoadForm("HalvedRow", parent)
	tcolorRow:FindChild("Left"):SetText(L["Text Color:"])
	MRF:applyColorbutton(tcolorRow:FindChild("Right"), tcolorOpt)
		
	MRF:LoadForm("HalvedRow", parent)
		
	--Limits:
	local comparators = {"<", ">", "<=", ">=", "==", "!="}
	local transStack = function(comp)
		return L["stacks "]..tostring(comp)..L[" value"]
	end
	local transTime = function(comp)
		return L["time "]..tostring(comp)..L[" value"]
	end
	
	--Stack Limit
	local stCompOpt = MRF:GetOption(selected, "stackComp")
	local stLimitOpt = MRF:GetOption(selected, "stackLimit")
	local stCompRow = MRF:LoadForm("HalvedRow", parent)
	local stLimitRow = MRF:LoadForm("HalvedRow", parent)
	
	stCompRow:FindChild("Left"):SetText(L["Stacks Comparator:"])
	stLimitRow:FindChild("Left"):SetText(L["Stacks compare value:"])
	MRF:applyDropdown(stCompRow:FindChild("Right"), comparators, stCompOpt, transStack)
	MRF:applyTextbox(stLimitRow:FindChild("Right"), stLimitOpt)
	
	stLimitOpt:OnUpdate(function(val)
		if val and type(val) ~= "number" then
			stLimitOpt:Set(tonumber(val))
		end
	end)
	
	MRF:LoadForm("QuestionMark", stCompRow:FindChild("Left")):SetTooltip(L["ttLimit"])
	
	--Time Limit
	local tiCompOpt = MRF:GetOption(selected, "timeComp")
	local tiLimitOpt = MRF:GetOption(selected, "timeLimit")
	local tiCompRow = MRF:LoadForm("HalvedRow", parent)
	local tiLimitRow = MRF:LoadForm("HalvedRow", parent)
	
	tiCompRow:FindChild("Left"):SetText(L["Time Comparator:"])
	tiLimitRow:FindChild("Left"):SetText(L["Time compare value:"])
	MRF:applyDropdown(tiCompRow:FindChild("Right"), comparators, tiCompOpt, transTime)
	MRF:applyTextbox(tiLimitRow:FindChild("Right"), tiLimitOpt)
	
	tiLimitOpt:OnUpdate(function(val)
		if val and type(val) ~= "number" then
			tiLimitOpt:Set(tonumber(val))
		end
	end)
	
	selector:Set(1)
	selected:OnUpdate(buffTblOpt, "ForceUpdate")
	
	local anchor = {parent:GetAnchorOffsets()}
	local children = parent:GetChildren()
	anchor[4] = anchor[2] + #children*30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end