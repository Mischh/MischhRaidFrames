--[[]]

local modKey = "Gradient Colors"
local MRF = Apollo.GetAddon("MischhRaidFrames")
local GradientMod, ModuleOptions = MRF:newModule(modKey , "color", true)
MRF:GatherUpdates(ModuleOptions) --any change done to the Addon-Options will push a Update to this Option.

local ceil = math.ceil;
local colors = {};
local buildColorObj = function(cObj) end --returns a table [0]-[100] containing the gradient colors

local transMeta = {__index = function(t, cObj) 
	t[cObj] = buildColorObj(cObj)
	return t[cObj]
end}
local colorTrans = setmetatable({}, transMeta)

local function wipeTbl(tbl)
	for i,v in pairs(tbl) do
		tbl[i] = nil
	end
end

local function getColor(colorObj, unit, progress) --will get unit, but wont need it.
	local p = ceil((progress or 0) * 100) --just a preferation to ceil instead of flooring
	return colorTrans[colorObj][p] --this will build the color, if not yet done.
end

local function cSub(color2, color1)
	return {
		r = color2.r - color1.r,
		g = color2.g - color1.g,
		b = color2.b - color1.b,
		a = color2.a - color1.a,
	}
end

local function cAdd(color2, color1, a)
	a = a or 1
	return{
		r = color2.r + a*color1.r,
		g = color2.g + a*color1.g,
		b = color2.b + a*color1.b,
		a = color2.a + a*color1.a,
	}
end

local function cHelp(cBase, cDiff, vMax, v)
	local p = v/vMax
	return cAdd(cBase, cDiff, p)
end

local function orderedPairs(tbl, min, max)
	local t = {}
	for i = min, max, 1 do
		if tbl[i] then
			t[#t+1] = i
		end
	end
	local i = 0
	return function()
		i = i+1
		return t[i], t[i] and tbl[t[i]] or nil
	end
end

buildColorObj = function(colorObj)
	local c = {}
	local w = ApolloColor.new("FFFFFFFF") --white, default.
	
	local lastVal = nil
	local lastTbl = nil
	for val, colorTbl in orderedPairs(colorObj.anchors, 0, 100) do
		if not lastVal then
			for i = 0, val, 100 do --apply the color of the first to all positions before the first color.
				c[i] = ApolloColor.new(colorTbl)
				end
		else
			local dv = val - lastVal;
			local dc = cSub(colorTbl, lastTbl)
			for i = 1, dv, 1 do --i=0 is already applied.
				c[lastVal+i] = ApolloColor.new(cHelp(lastTbl, dc, dv, i))
			end
		end
		lastVal = val
		lastTbl = colorTbl
	end
	
	for i = (lastVal or 0), 100, 1 do --apply the color of the last to all positions past the last color.
		c[i] = lastTbl and ApolloColor.new(lastTbl) or w
	end
	
	return c
end

function GradientMod:UpdateOptions(options)
	wipeTbl(colorTrans)
	wipeTbl(colors)
	for i, colorObj in ipairs(options or {}) do
		colorObj.Get = getColor
		colorObj.frequent = true
		
		colors[i] = colorObj
	end
end
ModuleOptions:OnUpdate(GradientMod, "UpdateOptions")

function GradientMod:GetColorTable()
	return colors
end


function GradientMod:InitColorSettings(parent)
	local L = MRF:Localize({--English
	}, {--German
		["New Color"] = "Neue Farbe",
		["Remove this Color:"] = "Entferne diese Farbe:",
		["Add a new Color:"] = "Füge eine neue Farbe hinzu:",
		["Add"] = "Hinzufügen",
		["Remove"] = "Entfernen",
		["Select a color to be reworked:"] = "Wähle eine zu ändernde Farbe:",
		["Remove the last Color-Point:"] = "Entferne den letzten Anker:",
		["Add a new Color-Point:"] = "Füge einen neuen Anker hinzu",
		["Set Name:"] = "Farb-Name:",
		["Point"] = "Anker",
		["Color"] = "Farbe",
	}, {--French
	})
	
	local handler = {}
	function handler:UpdateSize(offset)
		local children = parent:GetChildren()
		local anchor = {parent:GetAnchorOffsets()}
		anchor[4] = anchor[2] + (#children-(offset or 0))*30 --we want to display six 30-high rows.
		parent:SetAnchorOffsets(unpack(anchor))
		parent:ArrangeChildrenVert()
		parent:GetParent():RecalculateContentExtents()
	end
	
	local function removeTrans(color)
		if color then
			return color.name
		else	
			return ""
		end
	end

	local removeOpt = MRF:GetOption("GradientMod_Remove")
	removeOpt:OnUpdate(function(newVal) --a little workaround to use a dropdown for this.
		if newVal then	
			local num = nil
			for i, col in ipairs(colors) do
				if col == newVal then 
					table.remove(ModuleOptions:Get(), i)
					ModuleOptions:ForceUpdate()
					MRF:RemovedColor(col)
					break;
				end
			end
			
			removeOpt:Set(nil)
		end
	end)
	
	local selector, selected = MRF:SelectRemote("GradientMod_selected", ModuleOptions)
	local selection = {}
	local function double1st(f,s,...)
		return f,f,...
	end
	local function dblIndex(func, ...)
		local replacing = function(...)
			return double1st(func(...))
		end
		return replacing , ...	
	end
	function selection:ipairs()
		return dblIndex(ipairs(colors))
	end
	local function selectTrans(index)
		if index and colors[index] then
			return colors[index].name
		else
			return ""
		end
	end
	ModuleOptions:OnUpdate(function(opt) 
		local i = selector:Get()
		if not i or not opt[i] then
			local j = opt[1] and 1 or nil
			if i~=j then --no moar stack overflow
				selector:Set(j)
			end
		end
	end)
	
	local setHandler = {maxI = 0, curNum = 0, val = {}, col = {}, sliders = {}, switching = false}
	selected:OnUpdate(setHandler, "ChangedSelected")
	function setHandler:AddRow(val, col)
		self.maxI = self.maxI+1
		
		local index = self.maxI
		
		local opt_sli = MRF:GetOption("GradientMod_Sliders", index)
		local opt_col = MRF:GetOption("GradientMod_Colors", index)
		
		local curVal = nil
		opt_sli:OnUpdate(function(newVal) 
			if not self.switching and newVal~=curVal then
				local sel = selected:Get()
				if not sel then curVal = newVal; return end
				sel.anchors[newVal] = sel.anchors[curVal]
				sel.anchors[curVal] = nil
				
				if index>1 then --adjust the slider of point above
					self.sliders[index-1]:SetMinMax(nil,newVal-1)
				end
				if index<self.curNum then --adjust the slider of point below
					self.sliders[index+1]:SetMinMax(newVal+1)
				end
				
				selected:ForceUpdate()
			end
			curVal = newVal
		end)
		
		opt_col:OnUpdate(function(newCol)
			if self.switching or not newCol then return end
			local sel = selected:Get()
			if not sel then return end
			sel.anchors[curVal] = newCol
			
			selected:ForceUpdate()
		end)
		
		
		local min = 0
		if index > 1 then
			self.sliders[index-1]:SetMinMax(nil, val-1) --keep min as it was.
			min = self.val[index-1]:Get()+1
		end
		
		local row = MRF:LoadForm("HalvedRow", parent)
		self.sliders[index] = MRF:applySlider(row:FindChild("Left"), opt_sli, min, 100, 1)
		MRF:applyColorbutton(row:FindChild("Right"), opt_col, true)
		
		
		self.val[index] = opt_sli
		self.col[index] = opt_col
		opt_sli:Set(val)
		opt_col:Set(col)
	end
	
	local addPHandler = {}
	function addPHandler:ButtonClick(...)
		local sel = selected:Get()
		if not sel then return end --if there is none selected, we cant add.
		if sel.anchors[0] and #sel.anchors >= 100 then return end --we filled every single point with a color. cant add a point.
		--make room for a new Point.
		setHandler.switching = true
		
		local n = setHandler.curNum
		if n>0 then
			local last = sel.anchors[100]
			for i = 99, 0, -1 do
				setHandler.sliders[n]:SetMinMax(nil, i)--there is magic involved, which makes it not needed to set the minimum. - see this function in UIComponents
				if not last then break; end
				setHandler.val[n]:Set(i)
				n = n-1
				
				local tmp = sel.anchors[i]
				sel.anchors[i] = last --100 -> 99
				last = tmp
			end
		end
		--insert a new point at 100
		local col = {r=1, g=1, b=1, a=1}
		sel.anchors[100] = col
		--add a row
		
		setHandler.curNum = setHandler.curNum+1
		if setHandler.curNum>setHandler.maxI then
			setHandler:AddRow(100, col)
		else
			setHandler.val[setHandler.curNum]:Set(100)
			setHandler.col[setHandler.curNum]:Set(col)
		end
		
		setHandler.switching = false
		--update the size
		handler:UpdateSize(setHandler.maxI-setHandler.curNum)
		--push the changes
		selected:ForceUpdate()
	end
	
	local remPHandler = {}
	function remPHandler:ButtonClick(...)
		if setHandler.curNum > 1 then --we only remove, if there is more than one point defined.
			--remove the point
			local sel = selected:Get()
			local val = setHandler.val[setHandler.curNum]:Get()
			sel.anchors[val] = nil
			--decrement currently displayed rows
			setHandler.curNum = setHandler.curNum-1
			--set sliders max to 100
			setHandler.sliders[setHandler.curNum]:SetMinMax(nil, 100)
			--update Size
			handler:UpdateSize(setHandler.maxI-setHandler.curNum)
			--push the changes
			selected:ForceUpdate()
		end
	end
	
	local addCHandler = {}
	function addCHandler:ButtonClick(...)
		local i = #colors+1
		ModuleOptions:Get()[i] = {name = L["New Color"], anchors = {[0] = {r=1,g=1,b=1,a=1}}}
		ModuleOptions:ForceUpdate() 
		selector:Set(i)
	end
	
	local last = nil
	function setHandler:ChangedSelected(selected)	
		if selected == last then return end --we actually only want to know, if we actually had a BIG structural change
		last = selected
		
		self.switching = true
		if selected then
			local i = 0
			for val, col in orderedPairs(selected.anchors, 0, 100) do
				i = i+1
				if i>self.maxI then
					self:AddRow(val, col)
				else
					self.val[i]:Set(val)
					self.col[i]:Set(col)
				end
			end
			if i>0 then
				self.sliders[i]:SetMinMax(nil, 100)
			end
			self.curNum = i
		else
			self.curNum = 0
		end
		
		handler:UpdateSize(self.maxI-self.curNum)
		self.switching = false
	end
	
	local rowRemove = MRF:LoadForm("HalvedRow", parent)
	rowRemove:FindChild("Left"):SetText(L["Remove this Color:"])
	MRF:applyDropdown(rowRemove:FindChild("Right"), colors, removeOpt, removeTrans)
	
	local rowAdd = MRF:LoadForm("HalvedRow", parent)
	rowAdd:FindChild("Left"):SetText(L["Add a new Color:"])
	MRF:LoadForm("Button",rowAdd:FindChild("Right"), addCHandler):SetText(L["Add"])
	
	MRF:LoadForm("HalvedRow", parent) --just to make some Space.
	
	local selectRow = MRF:LoadForm("HalvedRow", parent)
	selectRow:FindChild("Left"):SetText(L["Select a color to be reworked:"])
	MRF:applyDropdown(selectRow:FindChild("Right"), selection, selector, selectTrans, selected) --extra updates from selected
	
	local nameRow = MRF:LoadForm("HalvedRow", parent)
	nameRow:FindChild("Left"):SetText(L["Set Name:"])
	MRF:applyTextbox(nameRow:FindChild("Right"), MRF:GetOption(selected, "name"))
	
	local addPRow = MRF:LoadForm("HalvedRow", parent)
	addPRow:FindChild("Left"):SetText(L["Add a new Color-Point:"])
	MRF:LoadForm("Button",addPRow:FindChild("Right"), addPHandler):SetText(L["Add"])
	
	local remPRow = MRF:LoadForm("HalvedRow", parent)
	remPRow:FindChild("Left"):SetText(L["Remove the last Color-Point:"])
	MRF:LoadForm("Button",remPRow:FindChild("Right"), remPHandler):SetText(L["Remove"])
	
	local header = MRF:LoadForm("HalvedRow", parent)
	header:FindChild("Left"):SetText(L["Point"])
	header:FindChild("Right"):SetText(L["Color"])
	
	parent:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
	handler:UpdateSize()
end

