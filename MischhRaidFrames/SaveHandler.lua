local MRF = Apollo.GetAddon("MischhRaidFrames")


local getInsertable, copyInto --these need to know each other.

function getInsertable(self, value)
	local t = type(value)
	if t == "string" or t == "number" or t == "boolean" then
		return value
	elseif t == "table" then
		local key = tostring(value)
		if not self[key] then
			copyInto(self, key, value)
		end
		return {key}
	else
		return true
	end
	--functions, unserdata etc. will be completely ignored and will return true.
end

function copyInto(self, key, tbl)
	local copy = {}
	local ind = 1
	rawset(self, key, copy) --this early, to prevent loops like 'tbl[key1][key2][key3] = tbl' to call copyInto again (only works, because we check within getCopyable)
	for i,v in pairs(tbl) do
		local index = getInsertable(self, i) --can be string, number, {tableName}
		local value = getInsertable(self, v)
		if index ~= nil and value ~= nil then
			copy[ind] = value
			copy[ind+1] = index
			ind = ind+2
		end
	end
end

local function restoreValue(cache, value)
	local t = type(value)
	if t == "string" or t == "number" or t == "boolean" then
		return value
	elseif t == "table" then
		return cache[unpack(value)]
	end
end

local function restore(tbl, cache)
	local copy = {}
	local i = 1
	while true do
		local value = restoreValue(cache, tbl[i])
		local index = restoreValue(cache, tbl[i+1])
		i = i+2
		if value ~= nil and index ~= nil then
			copy[index] = value
		else
			break;
		end
	end
	return copy
end

local function createCache(copy)
	return setmetatable({}, {__index = function(self, index)
		self[index] = restore(copy[index], self)
		return self[index]
	end})
end

local function convert(tbl)
	local origKey = tostring(tbl)
	local copy = {[0] = origKey}
	copyInto(copy, origKey, tbl)
	return copy
end

local function restoreConverted(orig)
	local cache = createCache(orig)
	return restore(orig[orig[0]], cache)
end

function MRF:ToSaveData(tbl)
	return convert(tbl)
end

function MRF:FromSaveData(tbl)
	if not tbl or not tbl[0] or not tbl[tbl[0]] then return end
	
	return restoreConverted(tbl)
end

local saving = {[GameLib.CodeEnumAddonSaveLevel.Character] = true, 
			[GameLib.CodeEnumAddonSaveLevel.Account] = true, 
			[GameLib.CodeEnumAddonSaveLevel.General] = true,
			[GameLib.CodeEnumAddonSaveLevel.Realm] = true}
local profiles = {}
local options = MRF:GetOption()
local profile = MRF:GetOption("profile")
profile:OnUpdate(MRF, "SelectedProfile")

function MRF:OnSave(eType)
	if saving[eType] then
		if profiles[eType] then
			return self:ToSaveData(profiles[eType])
		else
			return nil
		end
	end
end

function MRF:OnRestore(eType, tbl)
	if saving[eType] then
		profiles[eType] = self:FromSaveData(tbl)
	end
end

function MRF:LoadProfile(prof)
	if not saving[prof] then return end
	
	--the character level is always loaded
	profiles[GameLib.CodeEnumAddonSaveLevel.Character].profile = prof
	
	if not profiles[prof] then
		profiles[prof] = MRF:GetDefaults()
	end
	
	self.blockSwitch = true
	options:Set(profiles[prof])
	profile:Set(prof)
	self.blockSwitch = false
end

function MRF:SwitchToProfile(eLevel) 
	if not saving[eLevel] then return end --we dont support such a profile-index
	
	if not profiles[eLevel] then
		profiles[eLevel] = self:GetDefaults()
	end
	
	self:LoadProfile(eLevel)
end

local oldLevel = nil
function MRF:SelectedProfile(eLevel)
	local succ, err = pcall(function()
	if self.blockSwitch or oldLevel == eLevel then return end
	oldLevel = eLevel
	self:SwitchToProfile(eLevel)
	end)
	if succ then return end
	print("Error while switching Profiles:")
	print(err)
	print(debug.traceback())
end


-- We Assume 'to' is the currently displayed Profile, it will switch to it if not
function MRF:CopyProfile(from, to) --both are of GameLib.CodeEnumAddonSaveLevel
	if not saving[to] then return end --we dont support such a profile-index
	
	local fromOpt = nil
	if from and saving[from] and profiles[from] then 
		fromOpt = profiles[from]
	else --copy Defaults into there!
		fromOpt = self:GetDefaults()
	end
	
	--this is essentially a Deep-Copy which keeps internal references: (may want to implement an actual copy like this)
	local save = self:ToSaveData(fromOpt)
	profiles[to] = self:FromSaveData(save)
	
	self:LoadProfile(to)	
end

do
	local f = MRF.OnDocLoaded
	function MRF:OnDocLoaded(...)
		local char = GameLib.CodeEnumAddonSaveLevel.Character
				
		if not profiles[char] then
			profiles[char] = self:GetDefaults()
		end
		
		if not profiles[char].profile then
			profiles[char].profile = char
		end
		
		local new = profiles[char].profile
	
		profile:Set(new)
	
		f(self,...)
	end
end
