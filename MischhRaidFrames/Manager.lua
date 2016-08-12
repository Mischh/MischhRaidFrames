--[[]]

local MRF = Apollo.GetAddon("MischhRaidFrames")
local modules = {}
local notInitialized = {}
local moduleOptions = MRF:GetOption(nil, "modules")
local frameOptions = MRF:GetOption(nil, "frame")

local barMods = {};
--'lil hacky, but works
local textMods = setmetatable({},{__newindex = function(t, k, f) rawset(t,k,f); MRF:RegisterTextMod(k, f) end});
local colorMods = setmetatable({},{__newindex = function(t, k, f) rawset(t,k,f); MRF:RegisterColorMod(k, f) end});
local miscMods = setmetatable({},{__newindex = function(t, k, f) rawset(t,k,f); MRF:RegisterMiscMod(k, f) end});
local iconMods = setmetatable({},{__newindex = function(t, k, f) rawset(t,k,f); MRF:RegisterIconMod(k, f) end});

local ManagerSettings = {}--this is the object we use to build the Settings of all Modules with.
--[[
ManagerSettings:Add(type, name)
--]]


local supportedUses = {bar = barMods, text = textMods, color = colorMods, misc = miscMods, icon = iconMods}
local function saveUses(modKey, use, frequency, ...)
	local targetTbl = supportedUses[use or false] -- [false] returns nil, see 'if' below.
	if targetTbl then
		targetTbl[modKey] = frequency
		ManagerSettings:Add(use, modKey)
		saveUses(modKey, ...)
	end
end

--... should always be an unlimited amount of pairs, these pairs should look like "text", true (example for a text requiring frequent updates)
-- 		frequent colors recieve a progress-value from the bar they are applied to, but can only be applied to bars.
--		non-frequent stuff recieves updates, whenever the frames unit changes. (this is far more frequent than one might think)
function MRF:newModule(key, ...)
	modules[key] = {}
	notInitialized[key] = modules[key]
	saveUses(key, ...)
	return modules[key], self:GetOption(moduleOptions, key)
end

function MRF:HasModule(key)
	return modules[key]
end

function MRF:GetDefaultColor()
	local cTbl = modules["Default Color"]:GetColorTable()
	
	self.GetDefaultColor = function()
		return cTbl[1]
	end
	return self:GetDefaultColor()
end

local function checkemptybarcolor(c)
	if c[1] or c[2] then
		return c
	end
	return nil;
end

do --Frame Updating
	local currentTemplate = {}

	local textcolors = {}; --[[ = {
		[text1] = color1, --text1 defines, which Objects Text is to be colored
		[text2] = color2,
	}]]
	
	local barcolors = {}; --[[ = {
		[bar1] = {lColor, nil}
		[bar2] = {nil, rColor}
	}]]
	
	local barprogresscolors = {}; --[[ = {
		[bar1] = {nil, rColor},
		[bar2] = {lColor, nil},
	}]]
	
	local function rememberTextColor(key, color)
		textcolors[key] = color;
	end
	
	local frequentBars = {}; --[[ = {
		[modKey] = module,
	}]]
	local frequentTexts = {}; --[[ = {
		[targetBarKey] = module,
	}]]
	local unitBars = {};
	local unitTexts = {};
	
	local freqMisc = {}
	local unitMisc = {}
	
	local freqIcon = {}
	local unitIcon = {}
	
	function MRF:RegisterMiscMod(modKey, frequent)
		local targetTbl = frequent and freqMisc or unitMisc
		local function updateActive(active)
			if active then
				targetTbl[modKey] = modules[modKey]
			else
				targetTbl[modKey] = nil
			end
		end
		self:GetOption(moduleOptions, modKey, "activated"):OnUpdate(updateActive)
	end
	
	function MRF:RegisterIconMod(modKey, frequent)
		local targetTbl = frequent and freqIcon or unitIcon 
		local function updateActive(active)
			if active then
				targetTbl[modKey] = modules[modKey]
				self:ShowAllIcons(modKey)
			else
				targetTbl[modKey] = nil
				self:HideAllIcons(modKey)
			end
		end
		self:GetOption(moduleOptions, modKey, "activated"):OnUpdate(updateActive)
	end
	
	local function frameChanged(newTemplate)
		--empty tables
		textcolors, barcolors, barprogresscolors, frequentBars, frequentTexts, unitBars, unitTexts = {}, {}, {}, {}, {}, {}, {}

		currentTemplate = newTemplate
		
		--fill with updated information.
		for pos, bar in pairs(newTemplate) do
			if type(pos) ~= "string" then --string attributes like "inset" and "size" are used by the Frame Handler itself  
		
				if bar.modKey and barMods[bar.modKey] ~= nil then
					--make this bar get updates.
					(barMods[bar.modKey] and frequentBars or unitBars)[bar.modKey] = modules[bar.modKey]
					--Register the Bar-Colors to be applied.
					
					barcolors[bar.modKey] = {}
					barprogresscolors[bar.modKey] = {}
					if bar.lColor then
						(bar.lColor.frequent and barprogresscolors or barcolors)[bar.modKey][1] = bar.lColor
					end
					if bar.rColor then
						(bar.rColor.frequent and barprogresscolors or barcolors)[bar.modKey][2] = bar.rColor 
					end
					barcolors[bar.modKey] = checkemptybarcolor(barcolors[bar.modKey])
					barprogresscolors[bar.modKey] = checkemptybarcolor(barprogresscolors[bar.modKey])
				end
				
				if bar.textSource and textMods[bar.textSource] ~= nil then
					--make this text get Updates.
					(textMods[bar.textSource] and frequentTexts or unitTexts)[bar.modKey] = modules[bar.textSource]
					textcolors[bar.modKey] = bar.textColor
				end
			
			end
		end
	end
	frameOptions:OnUpdate(frameChanged)
	
	function MRF:PushFrequentUpdate(frame, unit)
		local progress = {}
	
		for modKey, mod in pairs(frequentBars) do
			progress[modKey] = mod:progressUpdate(frame, unit)
			frame:SetVar("progress", modKey, progress[modKey])
		end
		for target, mod in pairs(frequentTexts) do
			frame:SetVar("text", target, mod:textUpdate(frame, unit))
		end
		for target, cTbl in pairs(barprogresscolors) do
			local lColor = cTbl[1] and cTbl[1]:Get(unit, progress[target])
			local rColor = cTbl[2] and cTbl[2]:Get(unit, progress[target])
			frame:SetVar("barcolor", target, lColor, rColor)
		end
		for modKey, mod in pairs(freqMisc) do
			mod:miscUpdate(frame,unit)
		end
		for modKey, mod in pairs(freqIcon) do
			mod:iconUpdate(frame,unit)
		end
		
	end
	
	function MRF:PushUnitUpdate(frame, unit)
		for modKey, mod in pairs(unitBars) do --do these exist?
			progress[modKey] = mod:progressUpdate(frame, unit)
			frame:SetVar("progress", modKey, progress[modKey])
		end
		for target, mod in pairs(unitTexts) do
			frame:SetVar("text", target, mod:textUpdate(frame, unit))
		end
		for target, cTbl in pairs(barcolors) do
			local lColor = cTbl[1] and cTbl[1]:Get(unit)
			local rColor = cTbl[2] and cTbl[2]:Get(unit)
			frame:SetVar("barcolor", target, lColor, rColor)
		end
		for target, color in pairs(textcolors) do
			frame:SetVar("textcolor", target, color:Get(unit))
		end
		for modKey, mod in pairs(unitMisc) do
			mod:miscUpdate(frame,unit)
		end
		for modKey, mod in pairs(unitIcon) do
			mod:iconUpdate(frame,unit)
		end
		
		self:PushFrequentUpdate(frame, unit)
	end
	
	function MRF:CreateNewTemplatedFrame()
		return self:newFrame(nil, currentTemplate)
	end
end

do
	local freqModKeys = {} --we fill these first, because we only
	local unitModKeys = {} --want to ask for ColorTables on the first ipairs.

	local freqColorTbls = setmetatable({},{
		__index = function(t, index)
			local mod = modules[freqModKeys[index]]
			t[index] = mod:GetColorTable()
			return t[index]
		end
	})
	local unitColorTbls = setmetatable({},{
		__index = function(t, index)
			local mod = modules[unitModKeys[index]]
			t[index] = mod:GetColorTable()
			return t[index]
		end
	})
	
	local modSources = {} --should contain the modKeys for every color returned by ipairs.
	
	local barColors = {
		ipairs = function(self) --these locals....
			local source = freqColorTbls
			local maxTbls = #freqModKeys
			
			local source_next = unitColorTbls
			local maxTbls_next = #unitModKeys
			
			local curTblI = 2
			local curTbl = freqColorTbls[1]
			
			local maxColors = #(curTbl or {})
			local curColorI = 1
		
			local i = 0
			
			return function() --the 'next' function
				if curColorI > maxColors then
					if curTblI > maxTbls then --no tbl anymore in source.
						if not source_next or maxTbls_next < 1 then --no source left/next source is empty
							return nil
						else --select the next source.
							source = source_next
							maxTbls = maxTbls_next
							curTblI = 1
							
							source_next = nil
							maxTbls_next = 0
						end 	
					end
					--select next tbl from source.
					curTbl = source[curTblI]
					curTblI = curTblI+1
						
					maxColors = #curTbl
					
					curColorI = 1
				end
				i = i+1
				
				local c = curTbl[curColorI]
				curColorI = curColorI+1
				if not modSources[c] then
					modSources[c] = (source == freqColorTbls and freqModKeys or unitModKeys)[curTblI-1]
				end
				return i, c
			end
		end
	}
	
	local nobarColors = {
		ipairs = function(self)
			local source = unitColorTbls
			local maxTbls = #unitModKeys
			
			local curTblI = 2
			local curTbl = unitColorTbls[1]
			
			local maxColors = #(curTbl or {})
			local curColorI = 1
		
			local i = 0
			
			return function() --the 'next' function
				if curColorI > maxColors then
					if curTblI > maxTbls then --no tbl anymore in source.
						return nil
					end
					--select next tbl from source.
					curTbl = source[curTblI]
					curTblI = curTblI+1
						
					maxColors = #curTbl
					
					curColorI = 1
				end
				i = i+1
				
				local c = curTbl[curColorI]
				curColorI = curColorI+1
				if not modSources[c] then
					modSources[c] = unitModKeys[curTblI-1]
				end
				return i, c
			end
		end
	}
	
	function MRF:RegisterColorMod(modKey, freq)
		if freq then --just save them. Dont do much on Addon Loading. PLEASE.
			freqModKeys[#freqModKeys +1] = modKey
		else
			unitModKeys[#unitModKeys +1] = modKey
		end
	end
	
	local function translate(color)
		return color and (modSources[color] or "Unknown")..": "..color.name or " - "
	end
	
	function MRF:GetBarColors()
		return barColors, translate
	end
	
	function MRF:GetNoBarColors()
		return nobarColors, translate
	end
end

do
	local mods = {false}
	
	function MRF:RegisterTextMod(modKey, freq)
		mods[#mods+1] = modKey
	end
	
	local function trans(modKey)
		if not modKey then 
			return " - "
		else
			return modKey
		end 
	end
	
	function MRF:GetTextChoices()
		return mods, trans
	end
end

function MRF:RemovedColor(color)
	local default = self:GetDefaultColor()
	local frame = frameOptions:Get()
	for pos, bar in pairs(frame) do
		if type(pos) ~= "string" then
			bar.lColor = bar.lColor == color and default or bar.lColor
			bar.rColor = bar.rColor == color and default or bar.rColor
			bar.textColor = bar.textColor == color and default or bar.textColor
		end 
	end
	frameOptions:Set(frame)
end



MRF:AddMainTab("Bars")
MRF:AddMainTab("Icons")
MRF:AddMainTab("Texts")
MRF:AddMainTab("Colors")
MRF:AddMainTab("Misc")

local trans = {bar = "Bars", text = "Texts", icon = "Icons", color = "Colors", misc = "Misc"}
local inits = {bar = "InitBar", text = "InitText", icon = "InitIcon", color = "InitColor", misc = "InitMisc"}

function ManagerSettings:Add(type, modName)
	MRF:AddChildTab(modName, trans[type], self, inits[type])
end

do
	local shownTab = MRF:GetOption("UI_TabShown")
	do --Bars
		local L = MRF:Localize({--English
			["ttBarPos"] = "Changes the way the position below is interpreted. Only shown Bars have a position.",
			["ttRelPos"] = "These values are only used when the Mode is 'Stacking' or 'Offset'. The lowest position is the top-most. A bar in 'Offset'-Mode grows to the bottom.",
			["ttFixPos"] = "These values are only used when the Mode is 'Fixed'.",
			["ttBarCol"] = "These colors are displayed on the filled/missing part of the Bar. A half filled bar would be colored 50:50. The 'Filled Barcolor' always defines the left part of the Bar.",
			["ttBarTex"] = "These textures are used for the filled/missing part of the Bar. The 'Filled Bartexture' is always used for the left part of the Bar.",
			["ttTxtSrc"] = "These Options define which text should be applied to the bar. Be sure to never use one text-source for two bars.",
		}, {--German
			["Bar-Position Mode:"] = "Bar-Positionierungs-Modus:",
			["Relative Position:"] = "Relative Position:",
			["Relative Size:"] = "Relative Größe:",
			["Fixed Offset - Left:"] = "Fixer Abstand - Links:",
			["Fixed Offset - Right:"] = "Fixer Abstand - Rechts:",
			["Fixed Offset - Top:"] = "Fixer Abstand - Oben:",
			["Fixed Offset - Bottom:"] = "Fixer Abstand - Unten:",
			["Filled Barcolor:"] = "Bar-Farbe, füllend:",
			["Missing Barcolor:"] = "Bar-Farbe, leerend:",
			["Filled Bartexture:"] = "Bar-Textur, füllend:",
			["Missing Bartexture:"] = "Bar-Textur, leerend:",
			["Text Source:"] = "Text Ursprung:",
			["Text Color:"] = "Text Farbe:",
			["ttBarPos"] = "Bestimmt, welcher Modus zur Positionierung der Bar genutzt wird. Nur Sichtbare Bars haben eine Position.",
			["ttRelPos"] = "Diese Werte werden nur verwendet, wenn die Modi 'Stapelnd' oder 'Verschoben' gewählt sind. Die geringste Position liegt am oberen Rand. Eine Bar im Modus 'Verschoben' wächst immer nach unten.",
			["ttFixPos"] = "Diese Werte werden nur verwendet, wenn der Modus 'Fixiert' gewählt wurde.",
			["ttBarCol"] = "Die gewählten Farben werden auf dem vorhandenen/fehldenen Teil der Bar genutzt. Eine halb gefüllte Bar wird auf der linken Seite immer die füllende Farbe zeigen, auf der rechten hingegen die leerende.",
			["ttBarTex"] = "Die gewählten Texturen werden auf dem vorhandenen/fehlenden Teil der Bar gezeigt. Die füllende Textur wird dabei immer im linken Teil angezeigt, die leerende hingegen rechts.",
			["ttTxtSrc"] = "Diese Optionen definieren, welcher Text auf der Bar wiedergegeben werden soll. Stelle sicher, dass kein Text mehr als einer Bar zugewiesen wird.",
			
			["Stacking"] = "Stapelnd",
			["Offset"] = "Verschoben",
			["Fixed"] = "Fixiert",
			["Not Shown"] = "Versteckt",
			["Offset: "] = "Abstand: ",
			["Left"] = "Links",
			["Right"] = "Rechts",
			["Top"] = "Oben",
			["Bottom"] = "Unten",
			["Center"] = "Mitte",
			["Horizontal Text Position:"] = "Horizontale Text-Position:",
			["Vertical Text Position:"] = "Vertikale Text-Position:"
		}, {--French
		})
		local cBarChoices, cTrans = MRF:GetBarColors()
		local cTxtChoices = MRF:GetNoBarColors()
		local txtChoices, txtTrans = MRF:GetTextChoices()
		
		local posMode = MRF:GetOption("Manager:Bar", "Mode")
		local fixedL = MRF:GetOption("Manager:Bar", "Left")
		local fixedT = MRF:GetOption("Manager:Bar", "Top")
		local fixedR = MRF:GetOption("Manager:Bar", "Right")
		local fixedB = MRF:GetOption("Manager:Bar", "Bottom")
		local relPos = MRF:GetOption("Manager:Bar", "relative")
		local relSize = MRF:GetOption("Manager:Bar", "size")
		local lColor = MRF:GetOption("Manager:Bar", "lColor")
		local rColor = MRF:GetOption("Manager:Bar", "rColor")
		local lTexture = MRF:GetOption("Manager:Bar", "lTexture")
		local rTexture = MRF:GetOption("Manager:Bar", "rTexture")
		local hTextPos = MRF:GetOption("Manager:Bar", "hTextPos")
		local vTextPos = MRF:GetOption("Manager:Bar", "vTextPos")
		local txtSource = MRF:GetOption("Manager:Bar", "textSrc")
		local txtColor = MRF:GetOption("Manager:Bar", "textColor")
								
		local switchingTab = false
		
		local frameTmp = {}
		local pnl2ModKey = {}
		local modKey2Bar = {}
		local modKey2Pos = {}
		
		local function calcTotal()
			local x = 0
			for i,v in ipairs(frameTmp) do
				x = x+v.size
			end
			return x
		end
		
		local function indexes(from, to)
			if from > to then
				return
			else
				return from, indexes(from+1, to)
			end
		end
		
		local relPosChoices = {ipairs = function()
			local mode = posMode:Get()
			if mode == "Stacking" then
				return ipairs({indexes(1,#frameTmp)})
			elseif mode == "Offset" then
				return ipairs({indexes(-calcTotal(),0)})
			else
				return ipairs({false})
			end
		end}
		
		local textureChoices = {"WhiteFill", "ForgeUI_Smooth", "ForgeUI_Minimalist", "ForgeUI_Flat"}
		
		local _transTexChoices = {WhiteFill = "Fill", ForgeUI_Smooth = "ForgeUI: Smooth", ForgeUI_Minimalist = "ForgeUI: Minimalist", ForgeUI_Flat = "ForgeUI: Flat"}
		local function transTexChoices(tex)
			return _transTexChoices[tex or ""] or ""
		end
		
		local _transTextPos = {l=L["Left"], r=L["Right"], t=L["Top"], b=L["Bottom"], c=L["Center"]}
		local function transTextPos(x)
			return _transTextPos[x or ""] or " - "
		end
		
		local function transRelPosChoices(pos)
			if type(pos) == "number" then
				if pos > 0 then
					return "Bar "..pos.. ": ".. frameTmp[pos].modKey
				else
					return L["Offset: "]..tostring(math.abs(pos))
				end
			else
				return " - "
			end
		end
		
		local function transPosMode(mode)
			return L[mode or ""]
		end
		
		local barHandler = {windows = {}}
		shownTab:OnUpdate(barHandler, "SwitchedTab")
		frameOptions:OnUpdate(barHandler, "UpdatedFrame")
		posMode:OnUpdate(barHandler, "SwitchedMode")
		relPos:OnUpdate(barHandler, "SwitchedRelativePosition")
		relSize:OnUpdate(barHandler, "SwitchedRelativeSize")
		fixedL:OnUpdate(barHandler, "SwitchedFixed1")
		fixedT:OnUpdate(barHandler, "SwitchedFixed2")
		fixedR:OnUpdate(barHandler, "SwitchedFixed3")
		fixedB:OnUpdate(barHandler, "SwitchedFixed4")
		lColor:OnUpdate(barHandler, "SwitchedLColor")
		rColor:OnUpdate(barHandler, "SwitchedRColor")
		lTexture:OnUpdate(barHandler, "SwitchedLTexture")
		rTexture:OnUpdate(barHandler, "SwitchedRTexture")
		hTextPos:OnUpdate(barHandler, "SwitchedHTextPos")
		vTextPos:OnUpdate(barHandler, "SwitchedVTextPos")
		txtSource:OnUpdate(barHandler, "SwitchedTextSource")
		txtColor:OnUpdate(barHandler, "SwitchedTextColor")
		
		function barHandler:SwitchedTab(pnl) 
			local mod = pnl2ModKey[pnl]
			if not mod then return end
			switchingTab = true
			
			--okay, we switched to a bar tab - exactly we switched to the bar with the key 'mod'
			local pos, bar = modKey2Pos[mod], modKey2Bar[mod]
			local mode = self:GetPosMode(pos)
			
			local rel, l, t, r, b = false, 0,0,0,0
			local size = bar and bar.size or 1
			
			posMode:Set(mode)
			relSize:Set(size)
			if mode == "Stacking" then
				rel = pos
			elseif mode == "Offset" then
				rel = -pos[0]
			elseif mode == "Fixed" then
				l,t,r,b = unpack(pos)
			else
			
			end
			
			relPos:Set(rel); fixedL:Set(l); fixedT:Set(t); fixedR:Set(r); fixedB:Set(b);
			if bar then 
				lColor:Set(bar.lColor); rColor:Set(bar.rColor);
				lTexture:Set(bar.lTexture); rTexture:Set(bar.rTexture);
				hTextPos:Set(bar.hTextPos); vTextPos:Set(bar.vTextPos);
				txtSource:Set(bar.textSource); txtColor:Set(bar.textColor);
			else
				lColor:Set(nil); rColor:Set(nil);
				lTexture:Set(nil); rTexture:Set(nil);
				hTextPos:Set(nil); vTextPos:Set(nil);
				txtSource:Set(nil); txtColor:Set(nil);
			end
			
			switchingTab = false
		end
		
		function barHandler:UpdatedFrame(newFrame)
			frameTmp = newFrame
			modKey2Bar = {}
			modKey2Pos = {}
			for pos, bar in pairs(newFrame) do
				if type(pos) ~= "string" then
					modKey2Bar[bar.modKey] = bar
					modKey2Pos[bar.modKey] = pos
				end
			end
			shownTab:ForceUpdate()
		end
		
		local oldMode = "Not Shown"
		function barHandler:SwitchedMode(newMode)
			if not switchingTab and oldMode~=newMode then --if we currently switch tabs, the mode will be update to the new tabs bar.
				local pnl = shownTab:Get()
				local mod = pnl2ModKey[pnl]
				local pos = modKey2Pos[mod]
				local bar = modKey2Bar[mod]

				if oldMode == "Stacking" then
					--get the Bars Position and move all following a step up
					for i = pos+1, #frameTmp, 1 do
						frameTmp[i-1] = frameTmp[i]
					end
					frameTmp[#frameTmp] = nil
					
				elseif oldMode == "Not Shown" then
					local c = MRF:GetDefaultColor()
					bar = { size=1, modKey=mod, lColor=c, rColor=c, lTexture="WhiteFill", rTexture="WhiteFill"}
				else
					--just set the old pos to nil
					frameTmp[pos] = nil
				end
				oldMode = newMode;
				
				
				if newMode == "Stacking" then
					frameTmp[#frameTmp+1] = bar
				elseif newMode == "Offset" then
					frameTmp[{[0]=0}] = bar
				elseif newMode == "Fixed" then
					frameTmp[{0,0,1,1}] = bar
				end --newMode == "Not Shown" -> dont re-apply
				
				--:Set() the newly built frame - publish our changes.
				frameOptions:Set(frameTmp)
			else
				oldMode = newMode;
			end
			for _, tbl in ipairs(self.windows) do
				--tbl = {top, rel, fix, bar, tex, txt, parent, tab}
				if tbl[6]:GetParent():IsShown() then --only update the one Tab which is shown
					local size = 0
					
					--top -> Always shown
					size = size + tbl[1]:GetData()
					--rel -> shown: Stacking, Offset
					--fix -> shown: Fixed
					if newMode == "Stacking" or newMode == "Offset" then
						tbl[2]:SetAnchorOffsets(0,0,0,tbl[2]:GetData())
						tbl[3]:SetAnchorOffsets(0,0,0,0)
						size = size + tbl[2]:GetData()
					elseif newMode == "Fixed" then
						tbl[2]:SetAnchorOffsets(0,0,0,0)
						tbl[3]:SetAnchorOffsets(0,0,0,tbl[3]:GetData())
						size = size + tbl[3]:GetData()
					else
						tbl[2]:SetAnchorOffsets(0,0,0,0)
						tbl[3]:SetAnchorOffsets(0,0,0,0)
					end
					--bar -> now shown: Not Shown
					--tex -> not shown: Not Shown
					--txt -> not shown: Not Shown
					if newMode == "Not Shown" then
						tbl[4]:SetAnchorOffsets(0,0,0,0)
						tbl[5]:SetAnchorOffsets(0,0,0,0)
						tbl[6]:SetAnchorOffsets(0,0,0,0)
					else
						tbl[4]:SetAnchorOffsets(0,0,0,tbl[4]:GetData())
						tbl[5]:SetAnchorOffsets(0,0,0,tbl[5]:GetData())
						tbl[6]:SetAnchorOffsets(0,0,0,tbl[6]:GetData())
						size = size + tbl[4]:GetData() + tbl[5]:GetData() + tbl[6]:GetData()
					end
					
					--resort the tab, set tabs size, resort the parent
					tbl[8]:ArrangeChildrenVert()
					tbl[8]:SetAnchorOffsets(0,0,0,size)
					tbl[7]:ArrangeChildrenVert()
					tbl[7]:RecalculateContentExtents()
				end
			end
		end
		
		local oldPos = false
		function barHandler:SwitchedRelativePosition(newPos)
			if switchingTab or oldPos == newPos or type(newPos) ~= "number" then 
				oldPos = newPos
				return 
			end
			
			local bar = frameTmp[oldPos]
				
			if newPos > 0 then --Stacking
				if newPos < oldPos then --all positions between need to move up.
					for i = newPos, oldPos-1, 1 do
						frameTmp[i+1] = frameTmp[i]
					end
					frameTmp[newPos] = bar
				else --all positions between need to move down.
					for i = oldPos+1, newPos, 1 do
						frameTmp[i-1] = frameTmp[i]
					end
					frameTmp[newPos] = bar
				end
			else --Offset
				local pnl = shownTab:Get()
				local mod = pnl2ModKey[pnl]
				local pos = modKey2Pos[mod]
				pos[0] = math.abs(newPos) --we do not apply a negative value, as we use when selecting.
			end
			oldPos = newPos
			frameOptions:Set(frameTmp)
		end
		
		local oldSize = 1
		function barHandler:SwitchedRelativeSize(newSize)
			if switchingTab or oldSize == newSize then oldSize = newSize; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			bar.size = newSize
			
			oldSize = newSize
			
			frameOptions:Set(frameTmp)
		end
		
		function barHandler:CreateFixedSideUpdate(index)
			local oldVal = 0
			self["SwitchedFixed"..index] = function(self, newVal)
				if switchingTab or oldVal == newVal then oldVal = newVal; return end
				
				local pnl = shownTab:Get()
				local mod = pnl2ModKey[pnl]
				local pos = modKey2Pos[mod]
				
				if self:GetPosMode(pos) == "Fixed" then
					pos[index] = newVal
				end
				oldVal = newVal
				frameOptions:Set(frameTmp)
			end
		end
		barHandler:CreateFixedSideUpdate(1)
		barHandler:CreateFixedSideUpdate(2)
		barHandler:CreateFixedSideUpdate(3)
		barHandler:CreateFixedSideUpdate(4)

		local oldLColor = nil;
		function barHandler:SwitchedLColor(newColor)
			if switchingTab or oldLColor == newColor then oldLColor = newColor; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldLColor = newColor
			
			if bar then 
				bar.lColor = newColor
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldRColor = nil;
		function barHandler:SwitchedRColor(newColor)
			if switchingTab or oldRColor == newColor then oldRColor = newColor; return end
			
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldRColor = newColor
			if bar then 
				bar.rColor = newColor
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldLTexture = nil;
		function barHandler:SwitchedLTexture(newTexture)
			if switchingTab or oldLTexture == newTexture then oldLTexture = newTexture; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldLTexture = newTexture
			
			if bar then
				bar.lTexture = newTexture
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldRTexture = nil;
		function barHandler:SwitchedRTexture(newTexture)
			if switchingTab or oldRTexture == newTexture then oldRTexture = newTexture; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldRTexture = newTexture
			
			if bar then 
				bar.rTexture = newTexture
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldHTextPos = nil;
		function barHandler:SwitchedHTextPos(newPos)
			if switchingTab or oldHTextPos == newPos then oldHTextPos = newPos; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldHTextPos = newPos
			
			if bar then 
				bar.hTextPos = newPos
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldVTextPos = nil;
		function barHandler:SwitchedVTextPos(newPos)
			if switchingTab or oldVTextPos == newPos then oldVTextPos = newPos; return end
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldVTextPos = newPos
			
			if bar then 
				bar.vTextPos = newPos
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldSource = nil;
		function barHandler:SwitchedTextSource(newSource)
			if switchingTab or oldSource == newSource then oldSource = newSource; return end
			
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldSource = newSource
			if bar then 
				bar.textSource = newSource
				bar.textColor = bar.textColor or MRF:GetDefaultColor() --make sure the text has a color.
				frameOptions:Set(frameTmp)
			end
		end
		
		local oldTColor = nil;
		function barHandler:SwitchedTextColor(newColor)
			if switchingTab or oldTColor == newColor then oldTColor = newColor; return end
			
			local pnl = shownTab:Get()
			local mod = pnl2ModKey[pnl]
			local bar = modKey2Bar[mod]
			
			oldTColor = newColor
			if bar then 
				bar.textColor = newColor
				frameOptions:Set(frameTmp)
			end
		end
		
		function barHandler:GetPosMode(pos)
			if type(pos) == "table" then 
				return pos[0] and "Offset" or "Fixed" 
			elseif type(pos) == "number" then 
				return "Stacking"
			else
				return "Not Shown"
			end
		end
			
		function ManagerSettings:InitBar(pnl, modKey)
			pnl2ModKey[pnl] = modKey
			local parent = MRF:LoadForm("BarTab", pnl, barHandler)
			local form = parent:FindChild("DefaultTab")
			form:FindChild("Window_Top:Title"):SetText("Bar - "..modKey)
			
			form:FindChild("Window_Top:lblBarPosition"):SetText(L["Bar-Position Mode:"])
			form:FindChild("Window_Relative:lblRelPos"):SetText(L["Relative Position:"])
			form:FindChild("Window_Relative:lblRelSize"):SetText(L["Relative Size:"])
			form:FindChild("Window_Fixed:lblFixOffLeft"):SetText(L["Fixed Offset - Left:"])
			form:FindChild("Window_Fixed:lblFixOffRight"):SetText(L["Fixed Offset - Right:"])
			form:FindChild("Window_Fixed:lblFixOffTop"):SetText(L["Fixed Offset - Top:"])
			form:FindChild("Window_Fixed:lblFixOffBottom"):SetText(L["Fixed Offset - Bottom:"])
			form:FindChild("Window_Barcolor:lblBarColorL"):SetText(L["Filled Barcolor:"])
			form:FindChild("Window_Barcolor:lblBarColorR"):SetText(L["Missing Barcolor:"])
			form:FindChild("Window_Bartexture:lblBarTextureL"):SetText(L["Filled Bartexture:"])
			form:FindChild("Window_Bartexture:lblBarTextureR"):SetText(L["Missing Bartexture:"])
			form:FindChild("Window_Text:lblTextSource"):SetText(L["Text Source:"])
			form:FindChild("Window_Text:lblTextColor"):SetText(L["Text Color:"])
			form:FindChild("Window_Text:lblHorizontalPos"):SetText(L["Horizontal Text Position:"])
			form:FindChild("Window_Text:lblVerticalPos"):SetText(L["Vertical Text Position:"])
			
			form:FindChild("Window_Top:QuestionMark_PosMode"):SetTooltip(L["ttBarPos"])
			form:FindChild("Window_Relative:QuestionMark_Relative"):SetTooltip(L["ttRelPos"])
			form:FindChild("Window_Fixed:QuestionMark_Fixed"):SetTooltip(L["ttFixPos"])
			form:FindChild("Window_Barcolor:QuestionMark_Barcolor"):SetTooltip(L["ttBarCol"])
			form:FindChild("Window_Bartexture:QuestionMark_Bartexture"):SetTooltip(L["ttBarTex"])
			form:FindChild("Window_Text:QuestionMark_Text"):SetTooltip(L["ttTxtSrc"])
			
			MRF:applyPreview(form:FindChild("Window_Top:Preview"), modKey, "bar")
			
			MRF:applyDropdown(form:FindChild("Window_Top:PositionMode"), {"Stacking", "Offset", "Fixed", "Not Shown"}, posMode, transPosMode)
			MRF:applyDropdown(form:FindChild("Window_Relative:RelativePosition"), relPosChoices, relPos, transRelPosChoices)
			MRF:applySlider(form:FindChild("Window_Relative:RelativeSize"), relSize, 1, 10, 1, false, false, true)
			MRF:applySlider(form:FindChild("Window_Fixed:FixPosLeft"), fixedL, -0.5, 1.5, 0.01, true) --textbox: ignore steps
			MRF:applySlider(form:FindChild("Window_Fixed:FixPosRight"), fixedR, -0.5, 1.5, 0.01, true)
			MRF:applySlider(form:FindChild("Window_Fixed:FixPosTop"), fixedT, -0.5, 1.5, 0.01, true)
			MRF:applySlider(form:FindChild("Window_Fixed:FixPosBottom"), fixedB, -0.5, 1.5, 0.01, true)
			
			MRF:applyDropdown(form:FindChild("Window_Barcolor:BarColorLeft"), cBarChoices, lColor, cTrans )
			MRF:applyDropdown(form:FindChild("Window_Barcolor:BarColorRight"), cBarChoices, rColor, cTrans )
			MRF:applyDropdown(form:FindChild("Window_Bartexture:BarTextureLeft"), textureChoices, lTexture, transTexChoices)
			MRF:applyDropdown(form:FindChild("Window_Bartexture:BarTextureRight"), textureChoices, rTexture, transTexChoices)
			MRF:applyDropdown(form:FindChild("Window_Text:TextSource"), txtChoices, txtSource, txtTrans ) 
			MRF:applyDropdown(form:FindChild("Window_Text:TextColor"), cTxtChoices, txtColor, cTrans )
			MRF:applyDropdown(form:FindChild("Window_Text:HorizontalPos"), {'l', 'c', 'r'}, hTextPos, transTextPos)
			MRF:applyDropdown(form:FindChild("Window_Text:VerticalPos"), {'t', 'c', 'b'}, vTextPos, transTextPos)
			
			do
				local function f(x) x:SetData(x:GetHeight()) end
				local top, rel, fix, bar, tex, txt =  form:FindChild("Window_Top"), form:FindChild("Window_Relative"), form:FindChild("Window_Fixed"), form:FindChild("Window_Barcolor"), form:FindChild("Window_Bartexture"), form:FindChild("Window_Text")
				f(top); f(rel); f(fix); f(bar); f(tex); f(txt); --apply Height to Data.
				barHandler.windows[#barHandler.windows+1] = {top, rel, fix, bar, tex, txt, parent, form}
			end
			
			local mod = modules[modKey]
			if mod.InitBarSettings then
				local modSpace = parent:FindChild("ModuleSpace");
				mod:InitBarSettings(modSpace)
			end
			parent:RecalculateContentExtents()
			MRF:GetOption(nil, "modules", modKey):ForceUpdate()
		end
	end

	function ManagerSettings:InitIcon(pnl, modKey)
		local L = MRF:Localize({--English
		}, {--German
			["These values set the Position of the Icon."] = "Diese Werte definieren die Position des Icons.",
			["Activated"] = "Aktiviert",
			["Horizontal Position:"] = "Horizontale Position:",
			["Vertical Position:"] = "Vertikale Position:",
		}, {--French
		})
	
		local modOpt = MRF:GetOption(nil, "modules", modKey)
		local activeOpt = MRF:GetOption(modOpt, "activated")
		local posX = MRF:GetOption(modOpt, "xOffset")
		local posY = MRF:GetOption(modOpt, "yOffset")
		
		local parent = MRF:LoadForm("IconTab", pnl)
		local form = parent:FindChild("DefaultTab")
		
		form:FindChild("Title"):SetText("Icon - "..modKey)
		form:FindChild("DefaultTab:QuestionMark_Offset"):SetTooltip(L["These values set the Position of the Icon."])
		form:FindChild("DefaultTab:LabelX"):SetText(L["Horizontal Position:"])
		form:FindChild("DefaultTab:LabelY"):SetText(L["Vertical Position:"])
		
		MRF:applyPreview(form:FindChild("Window_Top:Preview"), modKey, "icon")
		
		MRF:applyCheckbox(form:FindChild("CheckboxActivated"), activeOpt, L["Activated"])
		MRF:applySlider(form:FindChild("SliderX"), posX, -0.5, 1.5, 0.01, true) --textbox: ignore steps
		MRF:applySlider(form:FindChild("SliderY"), posY, -0.5, 1.5, 0.01, true)
		
		local mod = modules[modKey]
		if mod.InitIconSettings then
			mod:InitIconSettings(parent:FindChild("ModuleSpace"))
		end
		parent:RecalculateContentExtents()
		modOpt:ForceUpdate()
	end

	function ManagerSettings:InitText(pnl, modKey)
		local parent = MRF:LoadForm("TextTab", pnl)
		parent:FindChild("Title"):SetText("Text - "..modKey)
		
		local mod = modules[modKey]
		if mod.InitTextSettings then
			mod:InitTextSettings(parent:FindChild("ModuleSpace"))
		end
		parent:RecalculateContentExtents()
		MRF:GetOption(nil, "modules", modKey):ForceUpdate()
	end

	function ManagerSettings:InitColor(pnl, modKey)
		local parent = MRF:LoadForm("ColorTab", pnl)
		parent:FindChild("Title"):SetText("Color - "..modKey)
		
		local mod = modules[modKey]
		if mod.InitColorSettings then
			mod:InitColorSettings(parent:FindChild("ModuleSpace"))
		end
		parent:RecalculateContentExtents()
		MRF:GetOption(nil, "modules", modKey):ForceUpdate()
	end
	
	function ManagerSettings:InitMisc(pnl, modKey)
		local L = MRF:Localize({--English
		}, {--German
			["Activated"] = "Aktiviert",
		}, {--French
		})
		
		local modOpt = MRF:GetOption(nil, "modules", modKey)
		local activeOpt = MRF:GetOption(modOpt, "activated")
		
		local parent = MRF:LoadForm("MiscTab", pnl)
		local form = parent:FindChild("DefaultTab")
		form:FindChild("Title"):SetText("Misc - "..modKey)

		MRF:applyCheckbox(form:FindChild("CheckboxActivated"), activeOpt, L["Activated"])
		
		local mod = modules[modKey]
		if mod.InitMiscSettings then
			mod:InitMiscSettings(parent:FindChild("ModuleSpace"))
		end
		parent:RecalculateContentExtents()
		modOpt:ForceUpdate()
	end
end


