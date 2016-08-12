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
	
	-- okay, this one is a little bit of a problem. We do not want to push updates on the
	-- frame template, before all Color-Modules have been loaded. Else we risk a Error once
	-- the Manager tries to apply colors, which do not yet have been updated and do not yet
	-- have their :Get Method.
	local frameOpt = MRF:GetOption(options, "frame")
	frameOpt:BlockUpdates() --everything below will get blocked aswell, because all updates below are gathered.
	options:Set(profiles[prof])
	frameOpt:UnblockUpdates() --this will do a :ForceUpdate()
	
	profile:Set(prof)
	self.blockSwitch = false
	
	if self:CheckFrameTemplate(frameOpt:Get()) then
		frameOpt:ForceUpdate()
		Print("MRF: Finished checking frame-template with Errors. See Changes above.")
	end
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
	local err, traceback;
	local succ, err = xpcall(function()
		if self.blockSwitch or oldLevel == eLevel then return end
		oldLevel = eLevel
		self:SwitchToProfile(eLevel)
	end, function(err)
		Print("Error while switching Profiles:")
		Print(err)
		Print(debug.traceback())
	end)	
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

function MRF:CheckFrameTemplate(frame)
	local default = self:GetDefaultColor()
	local valHPos = {l = true, c = true, r = true}
	local valVPos = {t = true, c = true, b = true}
	local dupBar = {}
	local dupTxt = {}
	local changed = false
	
	if not frame.size then
		Print("The Template had no size. Default to 250x25")
		frame.size = {0,0,250,25}
		changed = true
	end
	if not frame.backcolor then
		Print("The Template had no background color. Default to black.")
		frame.backcolor = "FF000000"
		changed = true
	end
	if not frame.inset then
		Print("The Template had no inset settings. Default to 1.")
		frame.inset = 1
		changed = true
	end
	for pos, bar in pairs(frame) do
		if type(pos) ~= "string" then
			--check all colors in all bars and look, if it has a color without a :Get() function
			if not bar.lColor then
				Print("Found a bar("..tostring(bar.modKey)..") without a filled color - set to default.")
				bar.lColor = default
				changed = true
			elseif type(bar.lColor.Get) ~= "function" then
				Print("Broken filled color on bar '"..tostring(bar.modKey).."' ("..bar.lColor.name..") - replaced with default.")
				bar.lColor = default
				changed = true
			end
			
			if not bar.rColor then
				Print("Found a bar("..tostring(bar.modKey)..") without a missing color - set to default.")
				bar.rColor = default
				changed = true
			elseif type(bar.rColor.Get) ~= "function" then
				Print("Broken missing color on bar '"..tostring(bar.modKey).."' ("..bar.rColor.name..") - replaced with default.")
				bar.rColor = default
				changed = true
			end
			
			if bar.textColor and type(bar.textColor.Get) ~= "function" then
				Print("Broken text color on bar '"..tostring(bar.modKey).."' ("..bar.textColor.name..") - replaced with default.")
				bar.textColor = default
				changed = true
			end
			
			--check textures are selected.
			if not bar.lTexture then
				Print("Found a bar("..tostring(bar.modKey)..") without a filled texture - default to 'Fill'")
				bar.lTexture = "WhiteFill"
				changed = true
			end
			if not bar.rTexture then
				Print("Found a bar("..tostring(bar.modKey)..") without a missing texture - default to 'Fill'")
				bar.rTexture = "WhiteFill"
				changed = true
			end
			
			--check, if the modKeys for the bar & text exist and have no duplicates.
			if not bar.modKey or not self:HasModule(bar.modKey) then
				Print("Found a bar which had no existing Module assigned to it ("..tostring(bar.modKey)..") - removed from template.")
				frame[pos] = nil
				changed = true
			elseif dupBar[bar.modKey] then
				Print("The frame-template had multiple instaces of the bar '"..tostring(bar.modKey).."' - removed the last found instance.")
				frame[pos] = nil
				changed = true
			else
				dupBar[bar.modKey] = true
			end
			
			if bar.textSource then
				if not self:HasModule(bar.textSource) then
					Print("Found a bar("..tostring(bar.modKey)..") with a text("..tostring(bar.textSource).."), which is not part of a Module. - removed the text")
					bar.textSource = nil
					changed = true
				elseif dupTxt[bar.textSource] then
					Print("The frame-template had multiple instaces of the text '"..tostring(bar.textSource).."' - removed the last found instance.")
					bar.textSource = nil
					changed = true
				else
					dupTxt[bar.textSource] = true
				end
				if bar.textSource and not bar.textColor then--check, if the bar has a text, but no textColor.
					Print("The bar "..tostring(bar.modKey).." had a text("..tostring(bar.textSource)..") without a color - set to default.")
					bar.textColor = default
					changed = true
				end
				if bar.textSource and not valHPos[bar.hTextPos or ""] then
					Print("The bar "..tostring(bar.modKey).." had a text("..tostring(bar.textSource)..") without a horizontal position - set to center.")
					bar.hTextPos = 'c'
					changed = true
				end
				if bar.textSource and not valVPos[bar.vTextPos or ""] then
					Print("The bar "..tostring(bar.modKey).." had a text("..tostring(bar.textSource)..") without a vertical position - set to center.")
					bar.vTextPos = 'c'
					changed = true
				end
			end
		end
	end
	return changed
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
