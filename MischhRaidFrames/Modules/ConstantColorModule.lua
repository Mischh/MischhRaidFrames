--[[
--]]

local modKey = "Constant Colors"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local CColMod, ModuleOptions = MRF:newModule(modKey , "color", false)
MRF:GatherUpdates(ModuleOptions) --any change done to the Addon-Options will push a Update to this Option.

local colors = {}; 

local defaults = {
	{name = "White", c="FFFFFFFF"},
	{name = "Black", c="FF000000"},
	{name = "FUIGray", c="FF272727"},
	{name = "Red", c="FFFF0000"},
}

local transMeta = {__index = function(t, cObj) 
	t[cObj] = ApolloColor.new(cObj.c)
	return t[cObj]
end}
local colorTrans = setmetatable({}, transMeta)

local function wipeTbl(tbl)
	for i,v in pairs(tbl) do
		tbl[i] = nil
	end
end

local function getColor(colorObj)
	return colorTrans[colorObj]
end

function CColMod:UpdateOptions(options)
	if not options then
		ModuleOptions:Set(defaults)
	else
		wipeTbl(colorTrans)-- = setmetatable({}, transMeta) --wipe the table
		wipeTbl(colors)
		for i, colorObj in ipairs(options) do
			if colorObj.c then
				colorObj.Get = getColor;
				colorObj.frequent = false
				colors[i] = colorObj;
			end
		end
	end
end
ModuleOptions:OnUpdate(CColMod, "UpdateOptions")

--called directly after InitModule, each time InitModule is called.
--the Table is supposed to be a Array of Tables, each representing a Color.
--a ColorObj = {name = "asdf", frequency = "constant", Get(self, unit, progress) } - unit&progress only supported for unit/progresscolor
function CColMod:GetColorTable()
	return colors;
end

local removeTrans = function(color)
	if color then
		return color.name
	else
		return ""
	end
end

function CColMod:InitColorSettings(parent)
	local handler = {hiddenRows = 0}
	function handler:UpdateSize()
		local children = parent:GetChildren()
		local anchor = {parent:GetAnchorOffsets()}
		anchor[4] = anchor[2] + (#children - handler.hiddenRows)*30 --we want to display six 30-high rows.
		parent:SetAnchorOffsets(unpack(anchor))
		parent:ArrangeChildrenVert()
		parent:GetParent():RecalculateContentExtents()
	end
	
	function handler:ButtonClick( wndHandler, wndControl, eMouseButton )
		local i = #colors+1
		local col = {c = "FFFFFFFF", name="New Color"}
		ModuleOptions:Get()[i] = col
		ModuleOptions:ForceUpdate() --put the new Color into 'colors'
		if handler.hiddenRows>0 then
			handler.hiddenRows = handler.hiddenRows-1
		else
			handler:AddRow(i)
		end
		handler:UpdateSize()
	end
	
	function handler:AddRow(i)
		local nameOpt = MRF:GetOption(ModuleOptions, i, "name")
		local colorOpt = MRF:GetOption(ModuleOptions, i, "c")
		local rowColor = MRF:LoadForm("HalvedRow", parent)
		
		parent:ArrangeChildrenVert()
		
		MRF:applyTextbox(rowColor:FindChild("Left"), nameOpt)
		MRF:applyColorbutton(rowColor:FindChild("Right"), colorOpt)
		
		MRF:GetOption(ModuleOptions, i):ForceUpdate()
	end

	local removeOpt = MRF:GetOption("CColMod_Remove")
	removeOpt:OnUpdate(function(newVal) --a little workaround to use a dropdown for this.
		if newVal then	
			local num = nil
			for i, col in ipairs(colors) do
				if col == newVal then 
					handler.hiddenRows = handler.hiddenRows+1
					handler:UpdateSize()
					table.remove(ModuleOptions:Get(), i)
					ModuleOptions:ForceUpdate()
					MRF:RemovedColor(col)
					break;
				end
			end
			
			removeOpt:Set(nil)
		end
	end)
	
	local rowRemove = MRF:LoadForm("HalvedRow", parent)
	rowRemove:FindChild("Left"):SetText("Remove this Color:")
	MRF:applyDropdown(rowRemove:FindChild("Right"), colors, removeOpt, removeTrans)
	
	local rowAdd = MRF:LoadForm("HalvedRow", parent)
	rowAdd:FindChild("Left"):SetText("Add a new Color:")
	MRF:LoadForm("Button",rowAdd:FindChild("Right"), handler):SetText("Add")
	
	MRF:LoadForm("HalvedRow", parent) --just to make some Space.
		
	local header = MRF:LoadForm("HalvedRow", parent)
	header:FindChild("Left"):SetText("Color Name")
	header:FindChild("Right"):SetText("Color")
	
	for i,v in ipairs(colors) do
		local nameOpt = MRF:GetOption(ModuleOptions, i, "name")
		local colorOpt = MRF:GetOption(ModuleOptions, i, "c")
		local rowColor = MRF:LoadForm("HalvedRow", parent)
		
		MRF:applyTextbox(rowColor:FindChild("Left"), nameOpt)
		MRF:applyColorbutton(rowColor:FindChild("Right"), colorOpt)
	end
	
	
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	handler:UpdateSize()
end



--For the Settings:
--[[
	-Select a Color Object
		-Set the name
		-Set the Color
--]]


