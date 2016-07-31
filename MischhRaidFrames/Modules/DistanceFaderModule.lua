--[[]]

local modKey = "Distance Fader"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local DistMod, ModOptions = MRF:newModule(modKey , "misc", true)

local pow, sqrt = math.pow, math.sqrt

--Options
local activeOption = MRF:GetOption(ModOptions, "activated")

local fadingDistance = 40
local distOption = MRF:GetOption(ModOptions, "distance")

local fadingFraq = 0.5
local invertFraq = 2
local fraqOption = MRF:GetOption(ModOptions, "fraction")

function DistMod:UpdateActivated(active)--this one is important.
	if active == nil then
		activeOption:Set(true) --default to true
	elseif not active then
		self:UnfadeAll()
	end
end
activeOption:OnUpdate(DistMod, "UpdateActivated")

function DistMod:UpdateDistance(dist)
	if type(dist) == "number" and dist > 0 then
		fadingDistance = dist
	else
		distOption:Set(40) --default to 40
	end
end
distOption:OnUpdate(DistMod, "UpdateDistance")

function DistMod:UpdateFraction(fraq)
	if type(fraq) == "number" and fraq > 0 and fraq <= 1  then
		self:RefadeAll(fraq) --update how much the Faded Frames are faded.
		fadingFraq = fraq
		invertFraq = 1/fraq
	else
		fraqOption:Set(0.5) --default to 0.5
	end
end
fraqOption:OnUpdate(DistMod, "UpdateFraction")

local function checkRange(unit)
	local pos = unit:GetPosition()
	if pos then
		local Ppos = GameLib.GetPlayerUnit():GetPosition()
		local dist = sqrt(pow(Ppos.x-pos.x,2) + pow(Ppos.y-pos.y,2) + pow(Ppos.z-pos.z,2))
		return dist<fadingDistance
	end
	return false -- not in range or havnt got information
end

local function multOpacity(frame, a)
	local x = frame:GetTargetedOpacity() or frame:GetOpacity()
	frame:SetOpacity(x*a)
end

local frameFaded = {}
function DistMod:miscUpdate(frame, unit)
	if checkRange(unit) then 				--if is in Range
		if frameFaded[frame] then 			--and the Frame is Faded
			frameFaded[frame] = nil
			multOpacity(frame, invertFraq) 	-->then Unfade.
		end
	elseif not frameFaded[frame] then 		--if not in Range and the Frame isnt Faded
		frameFaded[frame] = true
		multOpacity(frame, fadingFraq) 		-->then Fade.
	end
end

function DistMod:RefadeAll(newFraq)
	for frame in pairs(frameFaded) do
		multOpacity(frame, invertFraq)
		multOpacity(frame, newFraq)
	end
end

function DistMod:UnfadeAll()
	for frame in pairs(frameFaded) do
		frameFaded[frame] = nil
		multOpacity(frame, invertFraq)
	end
end

function DistMod:InitMiscSettings(parent)
	local L = MRF:Localize({--English
		["ttFade"] = [[Set the value, from which on the unit will have a faded frame.]],
	}, {--German
		["Faded Distance:"] = "Verblassende Distanz:",
		["Fade by:"] = "Verblassen auf:",
		["ttFade"] = [[Setze die Distanz, ab dem ein Spieler Verblassen soll.]],
	}, {--French
	})

	local distRow = MRF:LoadForm("HalvedRow", parent)
	local fraqRow = MRF:LoadForm("HalvedRow", parent)
	
	distRow:FindChild("Left"):SetText(L["Faded Distance:"])
	fraqRow:FindChild("Left"):SetText(L["Fade by:"])
	
	local question = MRF:LoadForm("QuestionMark", distRow:FindChild("Left")) 
	question:SetTooltip(L["ttFade"])
	
	MRF:applySlider(distRow:FindChild("Right"), distOption, 1, 100, 1)
	MRF:applySlider(fraqRow:FindChild("Right"), fraqOption, 0.1, 1, 0.05, true) --textbox: ignore steps
	
	local anchor = {parent:GetAnchorOffsets()}
	anchor[4] = anchor[2] + 2*30 --we want to display two 30-high rows.
	parent:SetAnchorOffsets(unpack(anchor))
	parent:ArrangeChildrenVert()
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
end

