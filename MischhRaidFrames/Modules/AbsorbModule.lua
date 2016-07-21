--[[]]

local modKey = "Absorb"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local AbsorbMod, ModuleOptions = MRF:newModule(modKey , "bar", true, "text", true)

local floor = math.floor

local absorbText;
local customMax = 10000;
local supportedRefs = {GetAbsorbtionMax = true, GetMaxHealth = true, GetShieldCapacityMax = true, ["Custom Maximum"] = true}
local references = {"GetAbsorbtionMax", "GetMaxHealth", "GetShieldCapacityMax", "Custom Maximum"}

local textOption = MRF:GetOption(ModuleOptions, "text")
local referenceOption = MRF:GetOption(ModuleOptions, "reference")
local customOption = MRF:GetOption(ModuleOptions, "customMax")

function AbsorbMod:TextOptionChanged(text)
	if not text then
		textOption:Set("%p%%")
	else
		absorbText = text
	end
end
textOption:OnUpdate(AbsorbMod, "TextOptionChanged")

function AbsorbMod:ReferenceOptionChanged(refMode)
	if not refMode or not supportedRefs[refMode] then
		textOption:Set("GetAbsorptionMax")
	else
		self.GetMaxReference = self[refMode]
	end
end
referenceOption:OnUpdate(AbsorbMod, "ReferenceOptionChanged")

function AbsorbMod:CustomMaximumChanged(newMax)
	if not newMax or not tonumber(newMax) then
		customOption:Set("10000")
	else
		customMax = tonumber(newMax)
	end
end
customOption:OnUpdate(AbsorbMod, "CustomMaximumChanged")

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- BAR -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --

function AbsorbMod:GetAbsorbtionMax(unit)
	return unit:GetAbsorbtionMax()
end

function AbsorbMod:GetMaxHealth(unit)
	return unit:GetMaxHealth()
end

function AbsorbMod:GetShieldCapacityMax(unit)
	return unit:GetShieldCapacityMax()
end

AbsorbMod["Custom Maximum"] = function(self, unit)
	return customMax
end

function AbsorbMod:GetMaxReference(unit) --this one will be overwritten very early by one of the above.
	return unit:GetAbsorbtionMax()
end

function AbsorbMod:progressUpdate(frame, unit)
	local max = self:GetMaxReference(unit)
	local cur = unit:GetAbsorptionValue()
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end

	local val = cur/max
	
	if val > 1 then val = 1 end
	
	--frame:SetVar("progress", modKey, val)
	return val
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

local tAbsorb = setmetatable({ --makes the text pattern easier & faster
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

function AbsorbMod:textUpdate(frame, unit)
	local max = unit:GetAbsorptionMax()
	local cur = unit:GetAbsorptionValue()
	if not cur then cur = 0 end
	if not max or max<1 then max = 1 end
	
	tAbsorb["C"] = max
	tAbsorb["c"] = cur
		
	local val = absorbText:gsub("%%(.)", tAbsorb) --replace any %* with the requested value.
	
	return val
end

function AbsorbMod:InitBarSettings(parent)
	local L = MRF:Localize({--English
		["ttSrc"] = [[To get a better idea on how much Absorb is on a unit, select the bars maximum.]],
		["ttMax"] = [[The value to the 'Custom Maximum' setting. Only insert numeric values.]],
		
		["GetAbsorbtionMax"] = "Current Absorb Max",
		["GetMaxHealth"] = "Maximal Health",
		["GetShieldCapacityMax"] = "Maximal Shield",
		["Custom Maximum"] = "Custom Maximum",
	}, {--German
		["Source for Maximum:"] = "Zu verwendendes Maximum:",
		["Custom Maximum:"] = "Benutzerdefiniertes Maximum:",
		
		["ttSrc"] = "Für eine repräsentativere Darstellung kann die Absorbtion relativ zu einem anderen Maximum gezeichnet werden.",
		["ttMax"] = "Wert zur Einstellung 'Benutzerdefiniertes Maximum' falls nicht gewählt, ändert dieser Wert nichts. Nur Ganzzahlige Werte einfügen.",
		
		["GetAbsorbtionMax"] = "Jetziger maximaler Absorb",
		["GetMaxHealth"] = "Maximale Lebenspunkte",
		["GetShieldCapacityMax"] = "Maximales Schild",
		["Custom Maximum"] = "Benutzerdefiniertes Maximum",
	}, {--French
	})
	
	local transRef = function(mode)
		return L[mode or ""]
	end

	local selRow = MRF:LoadForm("HalvedRow", parent)
	local selQuest = MRF:LoadForm("QuestionMark", selRow:FindChild("Left"))
	selRow:FindChild("Left"):SetText(L["Source for Maximum:"])
	selQuest:SetTooltip(L["ttSrc"])
	MRF:applyDropdown(selRow:FindChild("Right"), references, referenceOption, transRef)
	
	local maxRow = MRF:LoadForm("HalvedRow", parent)
	local maxQuest = MRF:LoadForm("QuestionMark", maxRow:FindChild("Left"))
	maxRow:FindChild("Left"):SetText(L["Custom Maximum:"])
	maxQuest:SetTooltip(L["ttMax"])
	MRF:applyTextbox(maxRow:FindChild("Right"), customOption)
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 60
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

function AbsorbMod:InitTextSettings(parent)
	local L = MRF:Localize({--English
		["ttPattern"] = [[Within this pattern specific characters will be replaced:
			%c = current value 
			%C = current maximum
			%s = shortened value 
			%S = shortened maximum
			%m = missing till maximum
			%n = shortened missing
			%p = percent (floored 0-100)]],--i know this doesnt look like a string in houston, but it is. Love this Editor...
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
	}, {--French
	})
	
	local row = MRF:LoadForm("HalvedRow", parent)
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	
	row:FindChild("Left"):SetText(L["Pattern:"])
	question:SetTooltip(L["ttPattern"])	
	MRF:applyTextbox(row:FindChild("Right"), textOption)

	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
