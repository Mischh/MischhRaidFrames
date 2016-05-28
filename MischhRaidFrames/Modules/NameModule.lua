--[[]]

local modKey = "Name"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local NameMod, ModOptions = MRF:newModule(modKey , "text", false)

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -- TEXT -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% --
local patternOpt = MRF:GetOption(ModOptions, "text")
local nicknameOpt = MRF:GetOption(ModOptions, "nicknames")
local nametext;
local nicks = {} --[1] = original; [original] = nick

function NameMod:UpdateTextPattern(newPattern)
	if not newPattern then
		patternOpt:Set("%f")
	else
		nametext = newPattern
	end
end
patternOpt:OnUpdate(NameMod, "UpdateTextPattern")

local function wipe(tbl)
	for i in pairs(tbl) do
		tbl[i] = nil
	end
end

local function copyIndexedNames(from, to)
	for i,v in ipairs(from) do
		if from[v] then
			to[i] = v
			to[v] = from[v]
		end
	end
end

local function copy(from, to)
	for i,v in pairs(from) do
		to[i] = v
	end
end

function NameMod:UpdateNicknames(newVal)
	if type(newVal) ~= "table" then
		nicknameOpt:Set({})
	else
		nicks = {} --just a little intergity-check on loading them. nothing too complicated.
		copyIndexedNames(newVal, nicks)
		wipe(newVal)
		copy(nicks, newVal)
		nicks = newVal
	end
end
nicknameOpt:OnUpdate(NameMod, "UpdateNicknames")

--[[
	%f* = firstName limited to * letters 
	%l* = lastName limited to * letters
	%n* = name limited to * letters
]]--

local t = {} --just a tbl used to help storing the names

local function magic(key, len)
	len = tonumber(len)
		
	local ret = t[key] or key

	if len then
		return ret:sub(1, len)
	end
	return ret;
end

function NameMod:textUpdate(frame, unit)
	local name = unit:GetName()
	
	if name and nicks[name] then
		return nicks[name]
	else
		t.n = name or "no Name"
		t.f, t.l = t.n:match("(.+)%s(.+)")
		
		--patternmatch the name:
		local val = nametext:gsub("%%(.)(%d?%d?)", magic)
		
		return val
	end
end

function NameMod:InitTextSettings(parent)
	local row = MRF:LoadForm("HalvedRow", parent)
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	
	row:FindChild("Left"):SetText("Pattern:")
	question:SetTooltip([[Within this pattern specific characters will be replaced:
	%f* = firstName limited to * letters 
	%l* = lastName limited to * letters
	%n* = name limited to * letters
	
	* can maximally use a two-digit number.
	To get unlimited legths, leave the * empty.]])
	MRF:applyTextbox(row:FindChild("Right"), patternOpt)

	MRF:LoadForm("HalvedRow", parent) --space
	
	local groupNames = {ipairs = function(group) 
		local max = GroupLib.GetMemberCount()
		local i = 0
		if max > 0 then
			return function()
				if i<max then
					i = i+1
					return i, GroupLib.GetGroupMember(i).strCharacterName
				end
				--return nil
			end
		else
			local ret = false
			return function()
				if ret then return end
				ret = true
				return 1, GameLib.GetPlayerUnit():GetName()
			end
		end
	end}
	local optSel = MRF:GetOption("NameModSettings", "selected")
	local optNick = MRF:GetOption("NameModSettings", "nick")
	local optRem = MRF:GetOption("NameModSettings", "remove")
	optRem:OnUpdate(function(rem) 
		if rem then 
			print(rem)
			local n = nicks[rem]
			table.remove(nicks, rem)
			nicks[n] = nil
			optRem:Set()
		end
	end)
	
	local function trans_add(x) return x or "" end
	
	local selRow = MRF:LoadForm("HalvedRow", parent)
	selRow:FindChild("Left"):SetText("Select a name to be nicknamed:")
	MRF:applyDropdown(selRow:FindChild("Right"), groupNames, optSel, trans_add)
	
	local selQuest = MRF:LoadForm("QuestionMark", selRow:FindChild("Left"))
	selQuest:SetTooltip([[Nicknames can be used to use fixed Names instead of the pattern for specific units.
	Doing Add on a already nicknamed unit will replace the old nickname.
	Empty Nicknames are not allowed (the only restriction)
	You can only select form your current group.]])
	
	local nickRow = MRF:LoadForm("HalvedRow", parent)
	nickRow:FindChild("Left"):SetText("Enter a nickname to be applied:")
	MRF:applyTextbox(nickRow:FindChild("Right"), optNick)
	
	local addRow = MRF:LoadForm("HalvedRow", parent)
	addRow:FindChild("Left"):SetText("Add the nickname:")
	MRF:LoadForm("Button", addRow:FindChild("Right"), {ButtonClick = function() 
		local n = optSel:Get()
		local x = optNick:Get()
		if n and n ~= "" and x and x:gsub("%s","") ~= "" then
			if not nicks[n] then
				nicks[#nicks+1] = n
			end
			nicks[n] = x
		end
	end}):SetText("Add")
	
	MRF:LoadForm("HalvedRow", parent) --space
	
	local remove = {
		ipairs = function()
			local tbl = {ipairs(nicks)}
			local f = tbl[1]
			
			local function double(f,s,...)
				return f,f,...
			end
			
			tbl[1] = function(...) 
				return double(f(...))
			end
			
			return unpack(tbl)
		end
	}
	local function trans_rem(idx) return idx and nicks[idx] or "select to remove" end
	
	local remRow = MRF:LoadForm("HalvedRow", parent)
	remRow:FindChild("Left"):SetText("Remove this Nickname:")
	MRF:applyDropdown(remRow:FindChild("Right"), remove, optRem, trans_rem)
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 7*30 --we want to display one 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	MRF:GetOption("NameModSettings"):ForceUpdate()
end

