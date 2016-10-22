require "ICComm"

local MRF = Apollo.GetAddon("MischhRaidFrames")


local getInsertable, copyInto --these need to know each other.
local keyTbl = setmetatable({}, {__index = function(t,k)
	local x = (rawget(t,"idx") or 0)+1
	rawset(t,"idx", x)
	rawset(t,k,x)
	return x
end})

function getInsertable(self, value)
	local t = type(value)
	if t == "string" or t == "number" or t == "boolean" then
		return value
	elseif t == "table" then
		local key = keyTbl[tostring(value)]
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
	rawset(self, key, copy) --this early, to prevent loops like 'tbl[key1][key2][key3] = tbl' to call copyInto again (only works, because we check within getInsertable)
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
	local origKey = keyTbl[tostring(tbl)]
	local copy = {[0] = origKey}
	copyInto(copy, origKey, tbl)
	return copy
end

local function restoreConverted(orig)
	local cache = createCache(orig)
	return restore(orig[orig[0]], cache)
end

function MRF:ToSaveData(tbl)
	keyTbl = setmetatable({}, getmetatable(keyTbl))
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
		profiles[prof] = self:GetDefaults()
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

function MRF:LoadProfileFromTable(tbl, prof)
	prof = prof or profile:Get() or ""
	if not saving[prof] then return end
	profiles[prof] = tbl
	
	self:LoadProfile(prof)
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
		if self.blockSwitch or oldLevel == eLevel then oldLevel = eLevel; return end
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

local function posToMode(pos)
	if type(pos) == "number" then
		return "Stacking"
	elseif type(pos) == "table" then
		if pos[0] then
			return "Offset"
		else
			return "Fixed"
		end
	end
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
		local mode = posToMode(pos)
		if mode then
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
			
			--check bar is on a layer.
			if not bar.layer or type(bar.layer) ~= "number" then
				local layer = (mode == "Stacking" and 1 or mode == "Offset" and 2 or 3)
				Print("Found a bar("..tostring(bar.modKey)..") without a layer. Defaulted according to Positioning-Mode ("..mode.." - "..layer..")")
				bar.layer = layer
				changed = true
			end
			
			--check the bars orientation
			if not bar.barOrientation or type(bar.barOrientation) ~= "string" or bar.barOrientation:len()~=1 then
				Print("Found a bar("..tostring(bar.modKey)..") without an valid orientation. Applied default: 'Left to Right'")
				bar.barOrientation = 'R'
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


--CAREFUL FROM HERE ON, EVERYTHING MAGIC!

--Two things to do for Strings: (1) the actual \ character needs to be replaced properly
-- (2) '|' and '}' need to be properly replaced, because we need these for encoding.

--replace \ with _], _] with _.], _.] with _..], and so on.
--replace | with _/ , _/  with _./ , _./  with _../  and so on.
--replace } with _) , _) with _.) , _.) with _..) and so on. 


local gsubPatternRmv1 = "_(%.*[%]/%)])" --MAAAAAAAGIC!
local gsubPatternRmv2 = "[\092|%}]"
local gsubRmvBraces = setmetatable({ 
	["\092"] = "_]", ["\124"] = "_/", ["\125"] = "_)",
}, {__index = function(t,k)
	local v = "_."..k
	rawset(t,k,v)
	return v
end})


--we need to revert the changes made when Removing special Characters:
local gsubPatternFill1 = "_([%]/%)])"
local gsubPatternFill2 = "_(%.+[%]/%)])" --no more magic - thats witchery!
local gsubFillBraces = setmetatable({
	["]"] = "\092", ["/"] = "|", [")"] = "}",
},{__index = function(t,k)
	local v = "_"..k:sub(2,-1)
	rawset(t,k,v)
	return v
end})

local function makeValidString(str)
	str = str:gsub(gsubPatternRmv1, gsubRmvBraces)
	return str:gsub(gsubPatternRmv2, gsubRmvBraces), nil
end

local function fromValidString(str)
	str = str:gsub(gsubPatternFill1, gsubFillBraces)
	return str:gsub(gsubPatternFill2, gsubFillBraces), nil
end

--[[Example:
	{1,2,"abc",{3,4,"cde"},5}
	turns into:
	n1|n2|sabc|{n3|n4|scde|}n5|
]]--
local function indexedTblToString(tbl)
	local str = ""
	for _, val in ipairs(tbl) do
		local t = type(val)
		if t == "string" then
			str = str.."s"..makeValidString(val).."|"
		elseif t == "number" then
			str = str.."n"..tostring(val).."|"
		elseif t == "boolean" then
			str = str..(val and "+" or "-") --doesnt need no limiter, they are only 1 character long.
		elseif t == "table" then
			str = str.."{"..indexedTblToString(val) --provides its own limiter. '}'
		end
	end
	return str.."}" --provide limiter
end


local function stringToIndexedTbl(str)
	local tbl = {}
	
	local type, val = nil, nil --local variables for the loop.
	while true do
		type, str = str:match("^([sn%+%-%{%}])(.*)$")
		if type == "s" then
			val, str = str:match("^(.-)%|(.*)$")
			if not val then --didn't expect -> return with error.
				return tbl, "", "invalid string"
			end 
			tbl[#tbl+1] = fromValidString(val)
		elseif type == "n" then
			val, str = str:match("^(.-)%|(.*)$")
			val = tonumber(val)
			if not val then --didn't expect -> return with error.
				return tbl, "", "invalid number"
			end 
			tbl[#tbl+1] = val
		elseif type == "+" then
			tbl[#tbl+1] = true
		elseif type == "-" then
			tbl[#tbl+1] = false
		elseif type == "{" then
			tbl[#tbl+1], str, val = stringToIndexedTbl(str)
			if val then --the table returned with error. -> pass on.
				return tbl, "", val
			end 
		elseif type == "}" then
			-- we reached the end of this table.
			-- str is probably the rest of the parent table, or empty.
			return tbl, str --this is the proper end of this function.
		else
			return tbl, "", "no or invalid identifier" -- ->returning with error. (do we even want to return tbl?)
		end
	end
end

local function spread(tbl)
	local cache = {}
	local idx = 1
	for i, v in pairs(tbl) do --neither i nor v can be nil, because how tables work.
		cache[idx] = v
		cache[idx+1] = i
		idx = idx+2
	end
	return cache
end

local function gather(tbl)
	local cache = {}
	for i = 2, #tbl, 2 do
		cache[tbl[i]] = tbl[i-1]
	end
	return cache
end
	

function MRF:CurrentProfileToString()
	local data = self:ToSaveData( self:GetOption(nil):Get() )
	--very important: THIS TABLE IS NOT INDEXED, we LOSE data[0] = 1.
	local str = indexedTblToString(data)
	
	--some integrity checks to make sure we get all data on the recieving end:
	--add the number of tables in the indexed part of data to the String, 
	--this way we try to make sure the structure is going to be kept.
	--surround with < > mainly to make sure we have both the start and the end of the string.
	
	return "<"..#data.."|"..str..">"
end

function MRF:StringToProfile(str)
	local num, str = str:match("^<(%d+)|(.*)>$")
	num = tonumber(num)
	
	if not num then
		return nil, "malformed string"
	end

	local data, left, error = stringToIndexedTbl(str)
	if error then
		return nil, error
	elseif not data then
		return nil, "failed decoding"
	elseif left ~= "" then
		return nil, "table ended early"
	end
	
	data[0] = 1
	
	if #data ~= num then
		return nil, "missing data", #data, num
	end
	
	local data = MRF:FromSaveData(data)
	
	return data
end

-- ################################# PROFILE TAB ######################################## --

local ProfileTab = {}

MRF:AddMainTab("Profile", ProfileTab, "InitProfileTab")

function ProfileTab:InitProfileTab(parent, name)
	local Options = MRF:GetOption("SaveHandler:Profiles")
	local L = MRF:Localize({--English
		["ttProfile"] = "The to be used profile can be chosen here. These profiles define their visibility to other characters. The profile 'Character' is only visible for this character, while 'Realm' can be used by any character of this account on this realm on this PC.",
		["ttCopy"] = "Insert the contents of this Profile into your current one. Selecting one will instantly replace.",
	
		--ICComm
		["ttStatus"] = "Displays what the AddOn just did. The ICComm Library very reliably breaks on first use. Please follow the /reloadui instructions.",
		["ttShare"] = "Share your current profile with your group. Only those waiting on an input will recieve this.",
		["ttWait"] = "Wait for a profile being shared by one of your groupmembers. They need to share their profile while you are waiting.",
		["ttImport"] = "Once you successfully recieved a profile, you can import it by clicking this button. Note: This will replace your current profile.",
		
		--Text
		["ttTxExport"] = "Exports your current profile to the textbox below. This text can then be shared with other people to be imported by them.",
		["ttTxImport"] = "Imports the profile from the textbox below. Valid profiles start with a '<*number*|', and end with a '>'. Leave no spaces in front or behind the text. The *number* is dependant on the profiles size, a wrong *number* will invalidate the profile.",
	}, {--German
		["ttProfile"] = "Hier kann das verwendete Profil gewählt werden. Diese Profile geben auch ihre Sichtbarkeit an. So ist das Profil 'Charakter' nur für diesen Charakter sichtbar, 'Realm' hingegen kann von jedem Charakter dieses Accounts auf diesem Realm auf diesem Computer genutzt werden.",
		["ttCopy"] = "Ersetzt den Inhalt des momentanen Profils mit dem Ausgewählten. Achtung! Wählen eines Profils wird das momentane SOFORT ersetzen.",
	
		["Selected profile:"] = "Ausgewähltes Profil:",
		["Replace Profile:"] = "Profil ersetzten:",
		["Copy profile from:"] = "Kopiere dieses Profil:",
		
		["Character"] = "Charakter",
		["Account"] = "Account",
		["General"] = "Generell",
		["Realm"] = "Realm",
		["Default: "] = "Standard: ",
		["- select to copy -"] = "- Auswählen zum Kopieren -",
		
		--ICComm stuff:
		["Import/Export: ICComm Group"] = "Importieren/Exportieren: ICComm Gruppe",
		["Recieved Invalid Data: "] = "Fehlerhafte Daten erhalten: ",
		["Failed to join. /reloadui and try again."] = "Beitritt schlug fehl. /reloadui und neu versuchen.",
		["Joined Channel."] = "Channel beigetreten.",
		["Current Status:"] = "Momentanter Status:",
		["Ready."] = "Bereit.",
		["Sent Profile."] = "Profil gesendet.",
		["Share with Group:"] = "Mit Gruppe teilen:",
		["Share"] = "Teilen",
		["Waiting... (1 minute)"] = "Warte... (1 Minute)",
		["Wait for Input:"] = "Auf Daten warten:",
		["Wait"] = "Warten",
		["Import the resulting profile:"] = "Importiere das erhaltene Profil",
		["No profile recieved."] = "Kein Profil erhalten.",
		["Profile imported."] = "Profil importiert.",
		["Profile: "] = "Profil: ",
		["Profile too big. Aborted."] = "Profil zu groß. Abgebrochen.",
		["ttStatus"] = "Beschreibt, was das AddOn gerade getan hat. Die ICComm Bibliothek schlägt meist beim ersten Versuch fehl. Bitte dem '/reloadui'-Vorschlag folge leisten.",
		["ttShare"] = "Teile dein momentanes Profil mit deiner Gruppe. Nur wartende Mitglieder werden dieses erhalten.",
		["ttWait"] = "Warte auf ein Profil, dass von einem Gruppenmitglied geteilt wird. Damit du dieses Profil erhalten kannst muss das Gruppenmitglied währenddem du wartest sein Profil teilen.",
		["ttImport"] = "Sobald ein Profil erfolgreich erhalten wurde, kann dieser Knopf zum Importieren des Profils gedrückt werden. Achtung! Dies wird das momentane Profil überschreiben.",		
	
		--Text import stuff:
		["Import/Export: Text"] = "Importieren/Exportieren: Text",
		["Export current Profile:"] = "Profil exportieren:",
		["Import Profile from Text:"] = "Profil importieren:",
		["Profile too big for text export."] = "Profil zu groß für Textexportierung",
		["Export"] = "Exportiere",
		["Import Profile"] = "Profil importieren",
		["Successfully imported Profile."] = "Profil erfolgreich importiert.",
		["Invalid Profile"] = "Fehlerhaftes Profil",
		["ttTxExport"] = "Exportiert das momentane Profil in die Textbox unten. Dieser Text kann dann mit anderen geteilt und von ihnen importiert werden.",
		["ttTxImport"] = "Importiert das Profil aus der Textbox unten. Fehlerfreie Profile starten mit '<*zahl*|' und enden mit einem '>'. Es dürfen keine Leerstellen vor/nach dem Profil existieren. Die *zahl* ist abhängig von der Profilgröße, mit einer falschen *zahl* ist das Profil Fehlerhaft.",
	}, {--French
	})

	local invProf = {
		[GameLib.CodeEnumAddonSaveLevel.Character] = "Character", 
		[GameLib.CodeEnumAddonSaveLevel.Account] = "Account", 
		[GameLib.CodeEnumAddonSaveLevel.General] = "General",
		[GameLib.CodeEnumAddonSaveLevel.Realm] = "Realm",
	}
	local profiles = {
		GameLib.CodeEnumAddonSaveLevel.Character,
		GameLib.CodeEnumAddonSaveLevel.Realm,
		GameLib.CodeEnumAddonSaveLevel.Account,
		GameLib.CodeEnumAddonSaveLevel.General,
	}
	local profiles_copy = {
		GameLib.CodeEnumAddonSaveLevel.Character,
		GameLib.CodeEnumAddonSaveLevel.Realm,
		GameLib.CodeEnumAddonSaveLevel.Account,
		GameLib.CodeEnumAddonSaveLevel.General,
	}
	local defaults = MRF:GetDefaultProfiles()
	for name in pairs(defaults) do profiles_copy[#profiles_copy+1] = name end
	
	local function transProf(idx)
		if type(idx) == "number" then
			return L[invProf[idx]]
		elseif type(idx) == "string" then
			return L["Default: "]..idx
		else
			return L["- select to copy -"]
		end
	end

	local form = MRF:LoadForm("SimpleTab", parent)
	form:FindChild("Title"):SetText(name)
	parent = form:FindChild("Space")

	local optProf = MRF:GetOption("profile")
	local profRow = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("QuestionMark", profRow:FindChild("Left")):SetTooltip(L["ttProfile"])
	profRow:FindChild("Left"):SetText(L["Selected profile:"])
	MRF:applyDropdown(profRow:FindChild("Right"), profiles, optProf, transProf)
	
	MRF:LoadForm("HalvedRow", parent):SetText(L["Replace Profile:"])
	
	local optCopy = MRF:GetOption(Options, "ProfileCopy")
	local copyRow = MRF:LoadForm("HalvedRow", parent)
	MRF:LoadForm("QuestionMark", copyRow:FindChild("Left")):SetTooltip(L["ttCopy"])
	copyRow:FindChild("Left"):SetText(L["Copy profile from:"])
	MRF:applyDropdown(copyRow:FindChild("Right"), profiles_copy, optCopy, transProf)
	optCopy:OnUpdate(function(prof)
		if type(prof) == "string" then
			local p = defaults[prof]()
			MRF:LoadProfileFromTable(p)
			optCopy:Set(nil)
		elseif prof then
			local cur = optProf:Get()
			MRF:CopyProfile(prof, cur)
			optCopy:Set(nil)
		end
	end)
	
	-- ########### ICOmm Lib ############# --
	MRF:LoadForm("HalvedRow", parent):SetText(L["Import/Export: ICComm Group"])
	
	local icprofile
	local icchannel = nil
	
	local icstatusOpt = MRF:GetOption(Options, "icstatus") --contains the currently displayed status-message
	local icbusyOpt = MRF:GetOption(Options, "icbusy") --'wait', 'share' or false/nil. Whats keeping the channel busy.
	local icimportOpt = MRF:GetOption(Options, "icimport") --the currently importable profiles owners name. (nil if none)
	
	function MRF:SaveHandler_OnICCommMessageReceived(channel, strMessage, srcName)
		if icbusyOpt:Get() == "wait" then --if we are not waiting for messages, we ignore anything.		
			local tbl = self:StringToProfile(strMessage)
			if not tbl then
				icstatusOpt:Set(L["Recieved Invalid Data: "]..tostring(srcName))
			end
			
			icprofile = tbl
			icimportOpt:Set(srcName)
			icbusyOpt:Set(false)
		end
	end
	
	local function joinedChannel(self)
		if not icchannel or not icchannel:IsReady() then
			icchannel = ICCommLib.JoinChannel("MRFSaveHandler", ICCommLib.CodeEnumICCommChannelType.Group)
			
			if not icchannel:IsReady() then
				icstatusOpt:Set(L["Failed to join. /reloadui and try again."])
				return false
			else
				icchannel:SetReceivedMessageFunction("SaveHandler_OnICCommMessageReceived", MRF)
			end
		end
		icstatusOpt:Set(L["Joined Channel."])
		return true
	end
	
	local icstatusRow = MRF:LoadForm("HalvedRow", parent)
	icstatusRow:FindChild("Left"):SetText(L["Current Status:"])
	MRF:applyTextbox(icstatusRow:FindChild("Right"), icstatusOpt).text:Enable(false)
	
	-- ## ICCOMM PUSH/SHARE ROW
	local icshareHandler = {
		misctimer = nil,
		aborttimer = nil, --not needed
		ButtonClick = function(self,...)
			icbusyOpt:Set("share")
		
			if not joinedChannel(self) then return end --this will handle retry
			self.misctimer = ApolloTimer.Create(2, false, "SendData", self)
		end,
		SendData = function(self)
			local msg = MRF:CurrentProfileToString()
			if msg:len() > 32750 then
				icstatusOpt:Set(L["Profile too big. Aborted."])
			else
				icchannel:SendMessage(msg)
				icstatusOpt:Set(L["Sent Profile."])
			end
			self.misctimer = ApolloTimer.Create(2, false, "ShareComplete", self)
		end,
		ShareComplete = function()
			icbusyOpt:Set(false)
		end,
	}
	local icshareRow = MRF:LoadForm("HalvedRow", parent)
	icshareRow:FindChild("Left"):SetText(L["Share with Group:"])
	local icshareBtn = MRF:LoadForm("Button", icshareRow:FindChild("Right"), icshareHandler)
	icshareBtn:SetText(L["Share"])
	
	-- ## ICCOMM WAIT ROW
	local icwaitHandler = {
		misctimer = nil,
		aborttimer = nil,
		ButtonClick = function(self,...)
			icbusyOpt:Set("wait")
			
			if not joinedChannel(self) then return end --this will handle retry
			self.misctimer = ApolloTimer.Create(2, false, "SetWaitText", self)
			self.aborttimer = ApolloTimer.Create(60, false, "AbortWait", self)
		end, 
		SetWaitText = function() 
			icstatusOpt:Set(L["Waiting... (1 minute)"]) 
		end,
		AbortWait = function()
			icbusyOpt:Set(false)
		end,
	}
	local icwaitRow = MRF:LoadForm("HalvedRow", parent)
	icwaitRow:FindChild("Left"):SetText(L["Wait for Input:"])
	local icwaitBtn = MRF:LoadForm("Button", icwaitRow:FindChild("Right"), icwaitHandler)
	icwaitBtn:SetText(L["Wait"])
	
	-- ## ICCOMM IMPORT ROW 
	local icimportRow = MRF:LoadForm("HalvedRow", parent)
	icimportRow:FindChild("Left"):SetText(L["Import the resulting profile:"])
	local icimportBtn = MRF:LoadForm("Button", icimportRow:FindChild("Right"), {ButtonClick = function(self,...)
		MRF:LoadProfileFromTable(icprofile)
		icprofile = nil
		icimportOpt:Set(false)
	end})
	
	icimportOpt:OnUpdate(function(name)
		if name == nil then
			icimportBtn:Enable(false)
			icimportBtn:SetText(L["No profile recieved."])
		elseif not name then
			icimportBtn:Enable(false)
			icimportBtn:SetText(L["Profile imported."])
		else
			icimportBtn:Enable(true)
			icimportBtn:SetText(L["Profile: "]..name)
		end
	end)
	
	icbusyOpt:OnUpdate(function(busy) 
		if busy then
			icshareBtn:Enable(false)
			icwaitBtn:Enable(false)
		else
			if icshareHandler.aborttimer then icshareHandler.aborttimer:Stop() end
			if icshareHandler.misctimer then icshareHandler.misctimer:Stop() end
			if icwaitHandler.aborttimer then icwaitHandler.aborttimer:Stop() end
			if icwaitHandler.misctimer then icwaitHandler.misctimer:Stop() end
			icstatusOpt:Set(L["Ready."])
			icshareBtn:Enable(true)
			icwaitBtn:Enable(true)
		end
	end)
	
	MRF:LoadForm("QuestionMark", icstatusRow:FindChild("Left")):SetTooltip(L["ttStatus"])
	MRF:LoadForm("QuestionMark", icshareRow:FindChild("Left")):SetTooltip(L["ttShare"])
	MRF:LoadForm("QuestionMark", icwaitRow:FindChild("Left")):SetTooltip(L["ttWait"])
	MRF:LoadForm("QuestionMark", icimportRow:FindChild("Left")):SetTooltip(L["ttImport"])
	
	-- ########### Text Output ############# --
	MRF:LoadForm("HalvedRow", parent):SetText(L["Import/Export: Text"])
	
	local txprofile = nil --this one will hold the importable profile (if there is one)
	local txtextOpt = MRF:GetOption(Options, "txtext") --the Option for the current text in the textbox.
	
	local txexportRow = MRF:LoadForm("HalvedRow", parent)
	txexportRow:FindChild("Left"):SetText(L["Export current Profile:"])
	local txexportBtn = MRF:LoadForm("Button", txexportRow:FindChild("Right"), {
		ButtonClick = function(self,...) 			
			local txt = MRF:CurrentProfileToString()
			if txt:len() > 30000 then
				txt = L["Profile too big for text export."]
			end
			txtextOpt:Set(txt)
		end
	}); txexportBtn:SetText(L["Export"])
	
	local tximportRow = MRF:LoadForm("HalvedRow", parent)
	tximportRow:FindChild("Left"):SetText(L["Import Profile from Text:"])
	local tximportBtn = MRF:LoadForm("Button", tximportRow:FindChild("Right"), {
		ButtonClick = function(self, btn, ...)
			if txprofile then
				MRF:LoadProfileFromTable(txprofile)
				txprofile = nil
				txtextOpt:Set(L["Successfully imported Profile."])
			end
		end
	}); --text will be applied in txtextOpt:OnUpdate()
	
	local txtextRow = MRF:LoadForm("HalvedRow", parent)
	txtextRow:SetAnchorOffsets(0,0,0,180)
	local txtextBox = MRF:applyTextbox(txtextRow, txtextOpt).text
	txtextBox:SetAnchorOffsets(5,-87, 5, 82)
	txtextBox:SetTextFlags('DT_CENTER', false); txtextBox:SetTextFlags('DT_VCENTER', false);
	txtextBox:SetTextFlags('DT_WORDBREAK', true); txtextBox:SetStyleEx('MultiLine', true);
	txtextBox:SetStyle('VScroll', true);
	
	txtextOpt:OnUpdate(function(txt)
		if not txt then
			txprofile = nil
			tximportBtn:Enable(false)
			tximportBtn:SetText(L["Invalid Profile"])
		else
			local tbl, err = MRF:StringToProfile(txt)
			if not tbl then
				txprofile = nil
				tximportBtn:Enable(false)
				tximportBtn:SetText(L["Invalid Profile"])
			else
				txprofile = tbl
				tximportBtn:Enable(true)
				tximportBtn:SetText(L["Import Profile"])
			end
		end
	end)
	
	MRF:LoadForm("QuestionMark", txexportRow:FindChild("Left")):SetTooltip(L["ttTxExport"])
	MRF:LoadForm("QuestionMark", tximportRow:FindChild("Left")):SetTooltip(L["ttTxImport"])
	
	local children = parent:GetChildren()
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + #children*30 +150-- 150 from textbox (180-30) +5 for the looks.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:GetParent():RecalculateContentExtents()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	
	optProf:ForceUpdate() --this is not a child of Options!
	Options:ForceUpdate()
end

