local MRF = Apollo.GetAddon("MischhRaidFrames")

local units, UnitHandler = MRF:GetUnits()
local frames = MRF:GetFrameTable()

local groupMembers = {
	{ --playerUnit
		nMemberIdx = 1,
		nMarkerId = nil,
		nLevel = 50,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bReady = true,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},{ --warr Tank
		nMemberIdx = 11,
		nMarkerId = 3,
		eClassId = GameLib.CodeEnumClass.Warrior,
		strCharacterName = "Warrior Tank",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 1,
		nInterruptArmor = 1,
		nHealthMax = 69452,
		nHealth = 69452,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29000,
		nShield = 29000,
		nHealingAbsorb = 30000,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Chua,
		ePathType = PlayerPathLib.PlayerPathType_Soldier,
		bHealer = false,
		bTank = true,
		bIsLeader = false,
		bCanInvite = true,
		bCanKick = true,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = true,
		bReady = true,
		bHasSetReady = true,
		bDisconnected = false,
		bIsOnline = true,
	},{ --esper DPS
		nMemberIdx = 2,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Esper,
		strCharacterName = "Esper DPS",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 49560,
		nHealth = 5234,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 25000,
		nShield = 0,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Aurin,
		ePathType = PlayerPathLib.PlayerPathType_Explorer,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bReady = false,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},{ --warr DPS
		nMemberIdx = 3,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Warrior,
		strCharacterName = "Warrior DPS",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 53480,
		nHealth = 24682,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 28000,
		nShield = 0,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Mordesh,
		ePathType = PlayerPathLib.PlayerPathType_Scientist,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bReady = true,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},{--Spellslinger Heal
		nMemberIdx = 4,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Spellslinger,
		strCharacterName = "Spellslinger Heal",
		nAbsorbtionMax = 13457,
		nAbsorbtion = 7564,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 52920,
		nHealth = 30486,
		nManaMax = 1852,
		nMana = 1534,
		nShieldMax = 30000,
		nShield = 13000,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Human,
		ePathType = PlayerPathLib.PlayerPathType_Settler,
		bHealer = true,
		bTank = false,
		bIsLeader = false,
		bCanInvite = true,
		bCanKick = true,
		bRaidAssistant = true,
		bMainAssist = false,
		bMainTank = false,
		bReady = false,
		bHasSetReady = true,
		bDisconnected = false,
		bIsOnline = true,
	}, {--Engi DPS
		nMemberIdx = 5,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Engineer,
		strCharacterName = "Engineer DPS",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 54235,
		nHealth = 54235,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29500,
		nShield = 29500,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Granok,
		ePathType = PlayerPathLib.PlayerPathType_Explorer,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bReady = false,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	}, { --Medic Heal
		nMemberIdx = 6,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Medic,
		strCharacterName = "Medic Heal",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 1,
		nInterruptArmor = 1,
		nHealthMax = 52496,
		nHealth = 12456,
		nManaMax = 1532,
		nMana = 1456,
		nShieldMax = 29500,
		nShield = 5423,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Mechari,
		ePathType = PlayerPathLib.PlayerPathType_Scientist,
		bHealer = true,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bReady = true,
		bHasSetReady = false,
		bDisconnected = true,
		bIsOnline = false,
	},{--Medic DPS
		nMemberIdx = 7,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Medic,
		strCharacterName = "Medic DPS",
		nAbsorbtionMax = 2255,
		nAbsorbtion = 2255,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 48985,
		nHealth = 48985,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29500,
		nShield = 29500,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Chua,
		ePathType = PlayerPathLib.PlayerPathType_Soldier,
		bHealer = false,
		bTank = false,
		bIsLeader = true,
		bCanInvite = true,
		bCanKick = true,
		bRaidAssistant = true,
		bMainAssist = true,
		bMainTank = false,
		bReady = true,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	}, {--Stalker DPS
		nMemberIdx = 8,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Stalker,
		strCharacterName = "Stalker DPS",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 50369,
		nHealth = 3254,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29500,
		nShield = 0,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Draken,
		ePathType = PlayerPathLib.PlayerPathType_Explorer,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bReady = false,
		bHasSetReady = true,
		bDisconnected = false,
		bIsOnline = true,
	}, { --Engi Tank
		nMemberIdx = 9,
		nMarkerId = 1,
		eClassId = GameLib.CodeEnumClass.Engineer,
		strCharacterName = "Engineer Tank",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 59856,
		nHealth = 12456,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29500,
		nShield = 3000,
		nHealingAbsorb = 30000,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Aurin,
		ePathType = PlayerPathLib.PlayerPathType_Scientist,
		bHealer = false,
		bTank = true,
		bIsLeader = false,
		bCanInvite = true,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = true,
		bReady = false,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},{ --Stalker Tank
		nMemberIdx = 10,
		nMarkerId = 2,
		eClassId = GameLib.CodeEnumClass.Stalker,
		strCharacterName = "Stalker Tank",
		nAbsorbtionMax = 3500,
		nAbsorbtion = 3200,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 54682,
		nHealth = 0,
		nManaMax = 1000,
		nMana = 0,
		nShieldMax = 29500,
		nShield = 0,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Aurin,
		ePathType = PlayerPathLib.PlayerPathType_Explorer,
		bHealer = false,
		bTank = true,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = true,
		bReady = true,
		bHasSetReady = true,
		bDisconnected = false,
		bIsOnline = true,
	},{ --Spellslinger DPS
		nMemberIdx = 12,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Spellslinger,
		strCharacterName = "Spellslinger DPS",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 45892,
		nHealth = 18658,
		nManaMax = 1000,
		nMana = 1000,
		nShieldMax = 29500,
		nShield = 6000,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Mordesh,
		ePathType = PlayerPathLib.PlayerPathType_Soldier,
		bHealer = false,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bMainTank = false,
		bReady = true,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},{ --esper Heal
		nMemberIdx = 13,
		nMarkerId = nil,
		eClassId = GameLib.CodeEnumClass.Esper,
		strCharacterName = "Esper Heal",
		nAbsorbtionMax = 0,
		nAbsorbtion = 0,
		nInterruptArmorMax = 0,
		nInterruptArmor = 0,
		nHealthMax = 52684,
		nHealth = 48234,
		nManaMax = 2250,
		nMana = 845,
		nShieldMax = 29500,
		nShield = 25000,
		nHealingAbsorb = 0,
		nLevel = 50,
		eRaceId = GameLib.CodeEnumRace.Mechari,
		ePathType = PlayerPathLib.PlayerPathType_Settler,
		bHealer = true,
		bTank = false,
		bIsLeader = false,
		bCanInvite = false,
		bCanKick = false,
		bRaidAssistant = false,
		bMainAssist = false,
		bMainTank = false,
		bMainTank = false,
		bReady = false,
		bHasSetReady = false,
		bDisconnected = false,
		bIsOnline = true,
	},
}


function MRF:TestMode()
	for i, member in ipairs(groupMembers) do
		if units[i] then
			units[i]:ApplyUnit(member, nil)
		else
			units[i] = UnitHandler:newUnit(member, nil)
		end
		frames[i]:Show(true, true)
		UnitHandler:UpdateUnit(i)
	end
	
	UnitHandler:Regroup()
	UnitHandler:Reposition()
	UnitHandler:HideAdditionalFrames()
end