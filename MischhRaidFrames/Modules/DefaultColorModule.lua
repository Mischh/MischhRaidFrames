--[[
--]]

local modKey = "Default Color"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local DefaultMod, ModuleOptions = MRF:newModule(modKey , "color", false)
MRF:GatherUpdates(ModuleOptions)

local color = ApolloColor.new("FFFFFFFF")
local function getColor()
	return color
end
local colorTbl = {
	{name = "Default", c = "FFFFFFFF", frequent = false, Get = getColor}
}

function DefaultMod:UpdateOptions(newColor)
	if not newColor or not newColor.c then
		ModuleOptions:Set({c = "FFFFFFFF"})
	else
		newColor.name = "Default"
		newColor.Get = getColor;
		newColor.frequent = false
		colorTbl[1] = newColor
		
		color = ApolloColor.new(newColor.c)
	end
end
ModuleOptions:OnUpdate(DefaultMod, "UpdateOptions")

function DefaultMod:GetColorTable()
	return colorTbl;
end

function DefaultMod:InitColorSettings(parent)	
	local L = MRF:Localize({--English
		["ttDefault"] = [[This color is used whenever the AddOn encounters a bar/text without a color.]],
	}, {--German
		["ttDefault"] = [[Diese Farbe wird immer dann genutzt, wenn das Addon eine Bar bzw. einen Text ohne Farbe entdeckt.]],
		["Default:"] = "Standard:",
	}, {--French
	})
	
	local row = MRF:LoadForm("HalvedRow", parent)
	row:FindChild("Left"):SetText(L["Default:"])
	MRF:applyColorbutton(row:FindChild("Right"), MRF:GetOption(ModuleOptions, "c"))
	
	local question = MRF:LoadForm("QuestionMark", row:FindChild("Left"))
	question:SetTooltip(L["ttDefault"])
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 30
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end
