--[[]]

local MRF = Apollo.GetAddon("MischhRaidFrames")

--all of these are self-creating tables.
local icons = {}--[modKey] = {[unitFrame] = icon}
local xPos = {}--[modKey] = x
local yPos = {}--[modKey] = y
local xOptions = {} --[modKey] = xOpt
local yOptions = {} --[modKey] = yOpt
local xUpdates = {} --[modKey] = updateHandler
local yUpdates = {} --[modKey] = updateHandler

local function updateAllOf(modKey)
	local x, y = xPos[modKey], yPos[modKey]
	for _, icon in pairs(icons[modKey]) do
		icon:SetAnchorPoints(x,y,x,y)
	end
end

local handler = {}--need to pass a Handler into :LoadForm - we dont use it.
local function getIconCreatorMeta(modKey) 
	return {__index = function(t, parent)
		local icon = MRF:LoadForm("IconTemplate", parent, handler)
		local x, y = xPos[modKey], yPos[modKey]
		icon:SetAnchorPoints(x,y,x,y)
		
		t[parent] = icon
		return t[parent]
	end}
end

icons = setmetatable(icons,{__index = function(t, modKey) 
	rawset(t, modKey, setmetatable({}, getIconCreatorMeta(modKey)))
	return t[modKey]
end})

xPos = setmetatable(xPos,{__index = function(self, modKey)
	rawset(self, modKey, xOptions[modKey]:Get() or 0)
	return self[modKey]
end})

yPos = setmetatable(yPos,{__index = function(self, modKey)
	rawset(self, modKey, yOptions[modKey]:Get() or 0)
	return self[modKey]
end})

xOptions = setmetatable(xOptions, {__index = function(self, modKey)
	local opt = MRF:GetOption(nil, "modules", modKey, "xOffset")
	opt:OnUpdate(xUpdates, modKey)
	rawset(self, modKey,opt)
	return opt
end})

yOptions = setmetatable(yOptions, {__index = function(self, modKey)
	local opt = MRF:GetOption(nil, "modules", modKey, "yOffset")
	opt:OnUpdate(yUpdates, modKey)
	rawset(self, modKey,opt)
	return opt
end})

xUpdates = setmetatable(xUpdates, {__index = function(self, modKey)
	local f = function(_, newX)
		if type(newX) == "number" then
			xPos[modKey] = newX
			updateAllOf(modKey)
		end
	end
	rawset(self, modKey, f)
	return f
end})

yUpdates = setmetatable(yUpdates, {__index = function(self, modKey)
	local f = function(_, newY)
		if type(newX) == "number" then
			yPos[modKey] = newY
			updateAllOf(modKey)
		end
	end
	rawset(self, modKey, f)
	return f
end})

function MRF:GetModIconForFrame(modKey, frame) --most code for short function evar xD
	return icons[modKey][frame]
end

function MRF:GetModIcons(modKey) --index the returned table with the Frame, which the icon shall be displayed on.
	return icons[modKey] --do not Set any key in this tbl, only retrieve Data.
end

function MRF:ShowAllIcons(modKey)
	for _, icon in pairs(icons[modKey]) do
		icon:Show(true, false)
	end
end

function MRF:HideAllIcons(modKey)
	for _, icon in pairs(icons[modKey]) do
		icon:Show(false, false)
	end
end

