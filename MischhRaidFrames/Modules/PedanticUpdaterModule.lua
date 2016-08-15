--[[]]

local modKey = "Pedantic Updater"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local UpdtrMod, ModOptions = MRF:newModule(modKey , "misc", true)

local actOpt = MRF:GetOption(ModOptions, "activated")
actOpt:OnUpdate(function(v) if v==nil then actOpt:Set(false) end end)

function UpdtrMod:miscUpdate(frame, unit) --worlds most complicated Module!
	unit.tbl = GroupLib.GetGroupMember(unit:GetMemberIdx())
end

function UpdtrMod:InitMiscSettings(parent)
	local L = MRF:Localize({--English
		["text"] = [[This module does something very simple, yet powerful: While activated it updates the backupdata for units whenever a frequent update occurs on the unit.
		
		Backupdata? This addon is designed to have, whenever possible, access to a 'unit'. This 'unit' is only available in certain situations and as such, not always provided. If the addon has no unit to gain information from, it will fall back to backupdata normally generated with each unit-update. This backupdata is limited to very specific data(basically anything Carbines Raidframes display)
		
		This means: This module feeds the other modules with newer data for units, which are not in range.]],
	}, {--German
		["text"] = [[Solange dieses Modul aktiv ist wird es, wann immer eine regelmäßige Aktualisierung durchgeführt wird, die Backupdaten erneuern.
		
		Backupdaten? Dieses Addon ist konzipiert mit der Idee, dass, wann immer möglich, eine 'unit' hinter den Dargestellten Informationen steht. Diese 'unit' ist aber nicht immer verfügbar und das Addon muss daher hin und wieder auf Daten anderen Ursprungs zurückgreifen. Die Backupdaten. Diese werden normalerweise mit Spieler-Aktualisierungen erneuert und enthalten nur Daten, die auch Carbines Raidframes darstellen.
		
		Das bedeutet: Dieses Modul versucht die Backupdaten so aktuell wie nur möglich zu halten.]],
	}, {--French
	})
	
	parent:SetText(L["text"])
	
	local anchor = {parent:GetAnchorPoints()}
	anchor[4] = 1
	parent:SetAnchorPoints(unpack(anchor))

	anchor = {parent:GetAnchorOffsets()}
	anchor[4] = 0
	parent:SetAnchorOffsets(unpack(anchor))
	
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
