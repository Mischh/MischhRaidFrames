--[[]]

local modKey = "Focus"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local FocusMod, ModuleOptions = MRF:newModule(modKey , "bar", true, "text", true) --we will support a Focus-bar and Focus-text

local floor = math.floor

local focustext = "";
local noText = true; --have no text, if focusless class?
local defFull = 0; --full bar for focusless classes? (barvalue for those)
local emtFull = 0; --empty bar for full focus? (barvalue for that encounter)

local patternOpt = MRF:GetOption(ModuleOptions, "text")
patternOpt:OnUpdate(FocusMod, "UpdateTextPattern")
function FocusMod:UpdateTextPattern(newPattern)
	if not newPattern then
		patternOpt:Set("%p%%")
	else
		focustext = newPattern
	end
end

local noTxtOpt = MRF:GetOption(ModuleOptions, "focusless_noText")
local defFullOpt = MRF:GetOption(ModuleOptions, "focusless_fullBar")
local emtFullOpt = MRF:GetOption(ModuleOptions, "focusfull_emptyBar")
noTxtOpt:OnUpdate(FocusMod, "UpdateFocuslessText")
defFullOpt:OnUpdate(FocusMod, "UpdateFocuslessBar")
emtFullOpt:OnUpdate(FocusMod, "UpdateFocusfullBar")
function FocusMod:UpdateFocuslessText(bVar)
	if bVar == nil then
		noTxtOpt:Set(true)
	else
		noText = bVar
	end
end
function FocusMod:UpdateFocuslessBar(bVar)
	if bVar == nil then
		defFullOpt:Set(false)
	else
		defFull = bVar and 1 or 0
	end
end
function FocusMod:UpdateFocusfullBar(bVar)
	if bVar == nil then
		defFullOpt:Set(true)
	else
		emtFull = bVar and 0 or 1
	end
end


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- BAR -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

function FocusMod:progressUpdate(frame, unit)
	local max = unit:GetMaxFocus()
	local cur = unit:GetFocus()
	if not max or max == 0 then --focusless
		return defFull
	elseif max == cur then --if true: cur is not nil, not 0 and equal to max
		return emtFull
	else
		if not cur then cur = 0 end
		if not max or max<1 then max = 1 end

		local val = cur/max
		
		return val
	end
end


--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- TEXT -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

local function shorten(num)	--stolen from ForgeUI
	local tmp = tostring(num)
    if not num then
        return "0"
    elseif num >= 1000000 then
        tmp = string.sub(tmp, 1, string.len(tmp) - 6) .. "." .. string.sub(tmp, string.len(tmp) - 5, string.len(tmp) - 5) .. "M"
    elseif num >= 1000 then
        tmp = string.sub(tmp, 1, string.len(tmp) - 3) .. "." .. string.sub(tmp, string.len(tmp) - 2, string.len(tmp) - 2) .. "k"    
	else
        tmp = num -- hundreds
    end
    return tmp
end

--[[
	%c = current; %C = current Max
	%s = short; %S = short Max
	%m = missing;
	%n = short missing;
	%p = percent (floored 0-100)
]]--

local tHealth = setmetatable({ --makes the text pattern easier & faster
	--[[c and C are supposed to be given]]
	_s = function(tbl) return shorten(tbl.c); end, -- if you want to add a %x , just add a function _x to this table.
	_S = function(tbl) return shorten(tbl.C); end,
	_m = function(tbl) return tbl.C - tbl.c; end,
	_n = function(tbl) return shorten(tbl.m); end,
	_p = function(tbl) return floor(100* tbl.c / tbl.C); end,
} , { __index = function(tbl, key)
	--[[key = c C s S m n, while c&C will be set (and never get called) ]]
	local f = rawget(tbl, "_"..key) -- see functions above. 
	if f then
		return f(tbl)
	else
		rawset(tbl, key, key) --invalid stuff will stay invalid - just save this funcs return.
		return key;-- if ppl do invalid stuff, the key will be returned (this will make %% work aswell)
	end
end})

function FocusMod:textUpdate(frame, unit)
	local max = unit:GetMaxFocus()
	local cur = unit:GetFocus()
	
	if noText and not max or max == 0 then
		return ""
	end
	
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end
	
	tHealth["C"] = max
	tHealth["c"] = cur 
		
	local val = focustext:gsub("%%(.)", tHealth) --replace any %* with the requested value.
	
	return val
end

function FocusMod:InitBarSettings(parent)
	local L = MRF:Localize({--English
		["ttFull"] = [[If Checked: Units without Focus (either by being the wrong class or having no information) will have a full bar, instead of an empty one.]],
		["ttEmpty"] = [[If Checked: Units with completely full focus get a empty bar.]],
	}, {--German
		["ttFull"] = [[Einheiten ohne Fokus (bei fokuslosen Klassen oder fehlender Information) erhalten eine gefüllte Bar, statt einer leeren.]],
		["ttEmpty"] = [[Einheiten mit komplett vollständigem Fokus haben eine leere Bar, statt einer gefüllten.]],
		["Filled by default"] = "Standardmäßig gefüllt",
		["Empty bar, if full Focus"] = "Leer bei vollem Fokus",
	}, {--French
	})
	
	local fulRow = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("QuestionMark", fulRow:FindChild("Left")):SetTooltip(L["ttFull"])
	MRF:applyCheckbox(fulRow:FindChild("Right"), defFullOpt, L["Filled by default"])
	
	local emtRow = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("QuestionMark", emtRow:FindChild("Left")):SetTooltip(L["ttEmpty"])
	MRF:applyCheckbox(emtRow:FindChild("Right"), emtFullOpt, L["Empty bar, if full Focus"])
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

function FocusMod:InitTextSettings(parent)
	local L = MRF:Localize({--English
		["ttPattern"] = [[Within this pattern specific characters will be replaced:
			%c = current value 
			%C = current maximum
			%s = shortened value 
			%S = shortened maximum
			%m = missing till maximum
			%n = shortened missing
			%p = percent (floored 0-100)]],--i know this doesnt look like a string in houston, but it is. Love this Editor...
		["ttNoText"] = [[Show no text for focusless units]],
	}, {--German
		["Pattern:"] = "Schema:",
		["ttPattern"] = [[Innerhalb dieses Schemas werden bestimmte Zeichenkombinationen ersetzt:
			%c = jetziger Wert 
			%C = jetziges Maximum
			%s = gekürzter Wert 
			%S = gekürztes Maximum
			%m = fehlend bis Maximum
			%n = fehlend, gekürzt
			%p = prozentual (abgerundet 0-100)]],
		["Default: No Text"] = "Standard: Kein Text",
		["ttNoText"] = [[Kein Text für fokuslose Einheiten]],
	}, {--French
	})

	local row = MRF:LoadForm("HalvedRow", parent)
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	
	row:FindChild("Left"):SetText(L["Pattern:"])
	question:SetTooltip(L["ttPattern"]) 	
	
	MRF:applyTextbox(row:FindChild("Right"), patternOpt)
	
	row = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("QuestionMark", row:FindChild("Left")):SetTooltip(L["ttNoText"])
	MRF:applyCheckbox(row:FindChild("Right"), noTxtOpt, L["Default: No Text"])
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end


