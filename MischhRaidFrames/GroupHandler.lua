--[[]]

local GroupHandler = {}
local MRF = Apollo.GetAddon("MischhRaidFrames")
local UnitHandler = nil --applied in GetGroupHandlersRegroup
local groups = nil --applied in GetGroupHandlersRegroup
local units = nil --applied in GetGroupHandlersRegroup


local Options = MRF:GetOption(nil, "Group Handler")
--MRF:AddMainTab("Group Handler", GroupHandler, "InitSettings")


local useUserDef = false
local userdef = {
	--[1] = "Group1"
	--[2] = "Group2" --this Group will end up empty -> not shown.
	--[3] = "Group3"
	--[5] = "Group5" --this Group cant be filled with stuff, scince [4] is missing. ->keep in mind.
	--["PlayerName1"] = 1 --ref to Group1
	--["PlayerName2"] = 1 --the Sort-Order of these is dependant on carbines sorting of units within groups
	--["PlayerName3"] = 3
	--["PlayerName4"] = 4 --this unit will end up in 'Ungrouped', because its Group doesnt exist
	--["PlayerName5"] = 5 --this unit will end up in 'Ungrouped', because its Group wasnt correctly defined.
}

local function iwipe(tbl)
	for i in ipairs(tbl) do
		tbl[i] = nil
	end
end

function GroupHandler:Regroup()
	if not groups then return end
	if useUserDef then
		GroupHandler:Regroup_User() --dont change to self!
	else
		GroupHandler:Regroup_Default() --dont change to self!
	end
end

function GroupHandler:Regroup_User()
	iwipe(groups)
	for i, name in ipairs(userdef) do
		groups[i] = {["name"] = name}
	end
	local unI = #userdef+1 --ungrouped Index
	groups[unI] = {name = "Ungrouped"}
	
	for i, unit in ipairs(units) do
		local n = unit:GetName()
		local grI = userdef[n] or unI --group = the user-defenition, or ungrouped
		local gr = groups[grI] or groups[unI]
		print(n, grI, groups[grI], gr)
		gr[#gr+1] = i
	end
end

function GroupHandler:Regroup_Default()
	iwipe(groups)
	groups[1] = {name = "Tanks"}
	groups[2] = {name = "Heals"}
	groups[3] = {name = "DPS"}
	
	for i,unit in ipairs(units) do
		if unit:IsTank() then
			groups[1][#groups[1]+1] = i;
		elseif unit:IsHeal() then
			groups[2][#groups[2]+1] = i;
		else
			groups[3][#groups[3]+1] = i;
		end
	end
end

function MRF:GetGroupHandlersRegroup(unithandler_groups, unithandler_units, unitHandler)
	groups = unithandler_groups
	units = unithandler_units
	UnitHandler = unitHandler
	
	return GroupHandler.Regroup
end

function GroupHandler:InitSettings(parent, name)
	
end

