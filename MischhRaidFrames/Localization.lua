local MRF = Apollo.GetAddon("MischhRaidFrames")

local selfMeta = { __index = function(t,k)
		return k
	end
}

function MRF:Localize(eng, ger, fre)
	local strCancel = Apollo.GetString(1)
	
	setmetatable(eng, selfMeta) 
	
	local m = {__index = function(t,k)
		return eng[k]
	end}
	setmetatable(ger, m)
	setmetatable(fre, m)
	
	-- German
	if strCancel == "Abbrechen" then 
		return ger or eng
	end
	
	-- French
	if strCancel == "Annuler" then
		return fre or eng
	end
	
	return eng
end