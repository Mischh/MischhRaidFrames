local MRF = Apollo.GetAddon("MischhRaidFrames")

local FORM_DROPDOWN_TEMPLATE = "Dropdown"
local FORM_DROPDOWN_ITEM = "DropdownItem"
local FORM_SLIDER_TEMPLATE = "Slider"
local FORM_CHECKBOX_TEMPLATE = "Checkbox"
local FORM_TEXTBOX_TEMPLATE = "TextBox"
local FORM_COLORPICKER_TEMPLATE = "ColorPicker"
local FORM_COLORBUTTON_TEMPLATE = "ColorButton"

local settingsForm = nil;

 --[[#####  Dropdown  ######]]
local function toggleDropdown(self, wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	if not wndControl:IsMouseTarget() then
		-- wndControl:SetCheck(not wndControl:IsChecked())
		-- local target = Apollo.GetMouseTargetWindow()
		-- if target:GetName() == FORM_DROPDOWN_ITEM then
			-- local handler = select(3, unpack(target:GetData()))
			-- handler:OnItemSelected(target)
		-- end
		-- return
	end
	local container = wndControl:FindChild("ChoiceContainer")
	local choices = container:FindChild("Choices")
	if wndControl:IsChecked() then
		local frames = choices:GetChildren()
		
		local pre = #frames --number of previously created Frames
		local num = 0 --number of items to be displayed
		
		--Fill Space:
		for i, obj in self.ipairs(self.data) do
			local text = self.trans(obj)
			if frames[i] then
				frames[i]:SetText(text)
				frames[i]:SetData({i, obj, self})
			else
				frames[i] = MRF:LoadForm(FORM_DROPDOWN_ITEM, choices, self)
				frames[i]:SetText(text)
				frames[i]:SetData({i, obj, self})
			end
			num = i
		end
		for i = num+1, #frames, 1 do
			frames[i]:Destroy()
		end

		choices:ArrangeChildrenVert()
		
		
		--Make Enought Space for the created Items:
		local l,t,r,b = container:GetAnchorOffsets()
		--32 = Size of a single Item
		pre = pre < 10 and pre or 10 --we didnt display more than 10 items
		num = num < 10 and num or 10 --we do not want to display more than 10 items
		local diff = (pre - num)*25
		b = b - diff --growing = going lower
		container:SetAnchorOffsets(l,t,r,b)
	end
	container:Show(wndControl:IsChecked())
end

local function containerClosed(self, container)
	local btn = container:GetParent()
	btn:SetCheck(false)
end

local function setSelected(self, selected)
	self.sel:Set(selected)
end

local function clickChoice(self, btn)
	local index, data, handler = unpack(btn:GetData())
	
	local container = btn:GetParent():GetParent()
	
	container:Close()
	
	setSelected(self, data, index)
end

local function setIndex(self, index)
	for i,v in self.ipairs(self.data) do
		if i == index then
			return setSelected(self, v)
		end
	end
end

local function registerForDistantUpdates(handler, x,...)
	if not x then return end
	x:OnUpdate(handler, "OnDistantUpdate")
	registerForDistantUpdates(handler, ...)
end

local function setText(self, str)
	self.drop:SetText(str)
end

local function selectorUpdate(self, value)
	self:SetText(self.trans(value))
end

local function distantUpdate(handler)
	handler:SetText(handler.trans(handler.sel:Get()))
end

--parent will be completely filled with the dropdown.
--choices is either a array, or a object with a :ipairs() method. (only ipairs(c)/c:ipairs() will be used to gain access to elements in the choices)
--selector (of type Option) will be :Set() with a value from choices, when the user selects something in the Dropdown - it also supplies the Dropdown with the Object to display as text
--translator is a function which accepts the value from the selector and returns a String. Default: tostring()
--... are addtional Options, to provide more Updates. any recieved :OnUpdate() results in retexting the dropdown - nothing else.
--The Text on the Dropdown will only change whenever the selector or one of the other options push an Update
--if you do not want to display Text - just rewrite the :SetText(str) function.
function MRF:applyDropdown(parent, choices, selector, translator, ...) 
	
	local handler = {data = choices, trans = translator or tostring, sel = selector, ipairs = choices.ipairs or ipairs}
	
	handler.drop = self:LoadForm(FORM_DROPDOWN_TEMPLATE, parent, handler):FindChild("DropdownButton")
	
	handler.OnDropdownToggle = toggleDropdown
	handler.OnContainerClosed = containerClosed
	handler.OnItemSelected = clickChoice
	
	handler.OnSelectorUpdate = selectorUpdate
	handler.OnDistantUpdate = distantUpdate
	handler.SetSelectedIndex = setIndex
	handler.SetSelectedValue = setSelected
	handler.SetText = setText
	
	selector:OnUpdate(handler, "OnSelectorUpdate")
	registerForDistantUpdates(handler, ...)
	
	
	return handler
end


local function sliderChanged(self, wndHandler, wndControl, value, old)
	--somehow the value is not exactly on point.. RECALCUALTE!
	local ticks = math.floor(((value-self.minimum)/self.ticklen)+0.5)
	value = self.minimum + self.ticklen*ticks

	self.block = true --uncool to have the bar be set all the time when dragging it.
	self.opt:Set(value)
	self.block = false
end

local function onUpdate(handler, val)
	if not handler.block then
		handler.slider:SetValue(val or handler.minimum)
	end
	if not handler.blockTxt then
		handler.text:SetText(tostring(val))
	end
end

local function setMinMax(handler, min, max, step)
	handler.minimum = min or handler.minimum
	handler.maximum = max or handler.maximum
	handler.ticklen = step or handler.ticklen
	
	if handler.minimum > handler.maximum then --keep at least one value possible for the slider.
		if min and not max then
			handler.maximum = min
		elseif max and not min then
			handler.minimum = max
		end
	end
	
	handler.slider:SetMinMax(handler.minimum, handler.maximum, handler.ticklen)
end

local function onText(self, wndHandler, wndControl, txt)
	local value = tonumber(txt)
	if not value then return end --non numeric values are not interesting.
	
	if self.tbLimited then
		if value < self.minimum then
			value = self.minimum
		elseif value > self.maximum and self.tbPosLimit then
			value = self.maximum
		end
	end
	
	if self.tbSteps then
		local ticks = math.floor(((value-self.minimum)/self.ticklen)+0.5)
		value = self.minimum + self.ticklen*ticks
	end
	
	self.blockTxt = true
	self.opt:Set(value)
	self.blockTxt = false
end

local function lostFocus(self)
	self.opt:ForceUpdate() --put value onto Slider & Textbox
end

--tbNoSteps, tbNoLimit -> the textbox ignores Steps, Min&Max
function MRF:applySlider(parent, selector, min, max, steps, tbNoSteps, tbNoLimit, tbNoLimitPos)
	min = min or 0
	max = max or min+1
	steps = steps or 0.1
	
	local handler = {opt = selector, block = false, minimum = min, maximum = max, ticklen = steps,
					tbSteps = not tbNoSteps, tbLimited = not tbNoLimit, tbPosLimit = not tbNoLimitPos}
	handler.SliderChanged = sliderChanged
	handler.OnUpdate = onUpdate
	handler.SetMinMax = setMinMax
	handler.OnText = onText
	handler.LostFocus = lostFocus
	handler.form = MRF:LoadForm(FORM_SLIDER_TEMPLATE, parent, handler)
	handler.text = handler.form:FindChild("Label")
	handler.slider = handler.form:FindChild("SliderBar")
		
	handler.slider:SetMinMax(min, max, steps)
		
	selector:OnUpdate(handler, "OnUpdate")
	return handler
end

local function onCheck(handler)
	if handler.block then return end
	handler.block = true
	handler.sel:Set(true)
	handler.block = false
end

local function onUncheck(handler)
	if handler.block then return end
	handler.block = true
	handler.sel:Set(false)
	handler.block = false
end

local function updateCheck(handler, newVal)
	if handler.block then return end
	handler.block = true
	handler.form:SetCheck(newVal and true or false)
	handler.block = false
end

function MRF:applyCheckbox(parent, selector, text)
	local handler = {
		Check = onCheck, 
		Uncheck = onUncheck, 
		OnUpdate = updateCheck, 
		block = false,
		sel = selector,
	}
	handler.form = MRF:LoadForm(FORM_CHECKBOX_TEMPLATE, parent, handler)
	handler.form:SetText(text)
	
	selector:OnUpdate(handler, "OnUpdate")
	return handler
end

local function textChanged(handler, _, _, str)
	if handler.block then return end
	handler.block = true
	handler.sel:Set(str)
	handler.block = false
end

local function updateText(handler, newVal)
	if handler.block then return end
	handler.block = true
	handler.text:SetText(newVal or "")
	handler.block = false
end

function MRF:applyTextbox(parent, selector)
	local handler = {
		OnTextChange = textChanged,
		OnUpdate = updateText, 
		block = false,
		sel = selector,
	}
	handler.form = MRF:LoadForm(FORM_TEXTBOX_TEMPLATE, parent, handler)
	handler.text = handler.form:FindChild("Text")
	
	selector:OnUpdate(handler, "OnUpdate")
	return handler
end

local white = ApolloColor.new(1,1,1,1)
local picker = nil

local function chooseNew(self, wndHandler, wndControl)
	--if not wndControl:IsMouseTarget() then
	--	local target = Apollo.GetMouseTargetWindow()
	--	if target:GetName() == FORM_DROPDOWN_ITEM then
	--		local handler = select(3, unpack(target:GetData()))
	--		handler:OnItemSelected(target)
	--	end
	--	return
	--end
	local init = self.sel:Get() or white
	
	picker:Pick(self, init)
end

local function tblCallback(handler, t, str)
	handler.sel:Set(t)
end

local function strCallback(handler, t, str)
	handler.sel:Set(str)
end

local function updateOpt(handler, newVal)
	handler.colorBG:SetBGColor(ApolloColor.new(newVal or white))
end

function MRF:applyColorbutton(parent, selector, asTbl)
	if not picker then picker = MRF:InitColorPicker() end --dont check if already, its built that way.

	local handler = {sel = selector, ChooseColor = chooseNew, OnUpdate = updateOpt}
	handler.Set = asTbl and tblCallback or strCallback
	
	local form = MRF:LoadForm(FORM_COLORBUTTON_TEMPLATE, parent, handler)
	handler.colorBG = form:FindChild("Button:Color")
	
	handler.Set = asTbl and tblCallback or strCallback
	
	selector:OnUpdate(handler, "OnUpdate")
	
	--selector:ForceUpdate()
end

function MRF:InitColorPicker()
	local L = MRF:Localize({--[[English]]
		["tt2x"] = [[WildStar supports colors with twice as high color-values. These Colors are marked as '2x'. With this you can (for example) apply bright colors to gray textures.]],
	}, {--[[German]]
		["Color Picker"] = "Farbauswahl",
		["New Color:"] = "Neue Farbe:",
		["Old Color:"] = "Alte Farbe:",
		["Copy"] = "Kopieren",
		["Paste"] = "Einfügen",
		["tt2x"] = [[WildStar unterstützt Farben mit doppelten Farbwerten. Diese Farben werden mit '2x' markiert. Auf diese Weise kann zum Beispiel eine helle Farbe auf eine graue Textur gelegt werden.]],
	}, {--[[French]]})

	local colorHandler = {color = ApolloColor.new(1,1,1,1), alpha = 1, copied = ApolloColor.new(1,1,1,1)}
	local colorPicker = nil
	function colorHandler:OnColorChanged( wndHandler, wndControl, color )
		local r = ("%x"):format(color.r*255):gsub("^(%x)$", "0%1")
		local g = ("%x"):format(color.g*255):gsub("^(%x)$", "0%1")
		local b = ("%x"):format(color.b*255):gsub("^(%x)$", "0%1")
		local a = ("%x"):format(self.alpha*255):gsub("^(%x)$", "0%1")
		local pre = self.dbl and "2x:" or ""
		
		local full = pre..a..r..g..b
		
		color = ApolloColor.new(a..r..g..b)
		
		self.color = color
		
		self:SetRText(r)
		self:SetGText(g)
		self:SetBText(b)
		self:SetAText(a)
		self:SetAlphaSlider(color.a)
		self:Set2x(self.dbl)
		
		self.newColor:SetBGColor(ApolloColor.new(full))
		if self.callback then
			self.callback:Set({a=color.a, r=color.r, g=color.g, b=color.b}, full)
		end
	end 
	
	function colorHandler:AlphaSliderChanged(_,_, val)
		self.blockAlpha = true
		self.alpha = val
		self:OnColorChanged(self.picker, self.picker, self.color)
		self.blockAlpha = false
	end
	
	function colorHandler:SetAlphaSlider(a)
		if self.blockAlpha then return end
		self.slider:SetValue(a)
	end
	
	function colorHandler:Check2x()
		self.dbl = true
		self:OnColorChanged(self.picker, self.picker, self.color)
	end
	
	function colorHandler:Uncheck2x()
		self.dbl = false
		self:OnColorChanged(self.picker, self.picker, self.color)
	end
	
	function colorHandler:Set2x(val)
		self.btn2x:SetCheck(val)
	end
	
	
	local blockA = false
	function colorHandler:ColorChangedA( wndHandler, wndControl, strText )
		local str = strText:sub(1,2) --ignore all other
		local num = tonumber(str, 16) --interpret as number in hex.
		if not num then return end --if the Text does not represent a number - cancel overwriting
		
		blockA = true
		self.alpha = num/255
		self:OnColorChanged(self.picker, self.picker, self.color)
		blockA = false
	end
	
	function colorHandler:SetAText(str)
		if blockA then return end
		self.boxA:SetText(str)
	end
	
	local blockR = false
	function colorHandler:ColorChangedR( wndHandler, wndControl, strText )
		local str = strText:sub(1,2) --ignore all other
		local num = tonumber(str, 16) --interpret as number in hex.
		if not num then return end --if the Text does not represent a number - cancel overwriting
		
		blockR = true
		local newColor = ApolloColor.new(num/255, self.color.g, self.color.b, self.color.a)
		self.picker:SetColor(newColor)
		self:OnColorChanged(self.picker, self.picker, newColor )
		blockR = false
	end
	
	function colorHandler:SetRText(str)
		if blockR then return end
		self.boxR:SetText(str)
	end
	
	local blockG = false
	function colorHandler:ColorChangedG( wndHandler, wndControl, strText )
		local str = strText:sub(1,2) --ignore all other
		local num = tonumber(str, 16) --interpret as number in hex.
		if not num then return end --if the Text does not represent a number - cancel overwriting
		
		blockG = true
		local newColor = ApolloColor.new(self.color.r, num/255, self.color.b, self.color.a)
		self.picker:SetColor(newColor)
		self:OnColorChanged(self.picker, self.picker, newColor)
		blockG = false
	end
	
	function colorHandler:SetGText(str)
		if blockG then return end
		self.boxG:SetText(str)
	end
	
	local blockB = false
	function colorHandler:ColorChangedB( wndHandler, wndControl, strText )
		local str = strText:sub(1,2) --ignore all other
		local num = tonumber(str, 16) --interpret as number in hex.
		if not num then return end --if the Text does not represent a number - cancel overwriting
		
		blockB = true
		local newColor = ApolloColor.new(self.color.r, self.color.g, num/255, self.color.a)
		self.picker:SetColor(newColor)
		self:OnColorChanged(self.picker, self.picker, newColor)
		blockB = false
	end
	
	function colorHandler:SetBText(str)
		if blockB then return end
		self.boxB:SetText(str)
	end
	
	function colorHandler:OnNewColorClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	end
	
	function colorHandler:OnOldColorClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
		local color = wndControl:GetBGColor()
		self:Pick(self.callback, color) --treat it as if we have opened the picker with this value.
	end
	
	function colorHandler:ClickCopy(...)
		self.copied = self.newColor:GetBGColor()
	end
	
	function colorHandler:ClickPaste(...)
		local color = self.copied
		self:Pick(self.callback, color) --treat it as if we have opened the picker with this value.
	end
	
	function colorHandler:Is2x(c)
		if c.r > 1 or c.g>1 or c.b>1 then
			return true, ApolloColor.new(c.r/2, c.g/2, c.b/2, c.a)
		else
			return false, c
		end
	end
	
	function colorHandler:Pick(callback, initial)
		if not initial then return end
		local color = ApolloColor.new(initial)
		
		self.dbl, color = self:Is2x(color)
		
		self.callback = callback
		self.color = color
		self.alpha = color.a
		
		self.oldColor:SetBGColor(ApolloColor.new(initial))
		self.picker:SetColor(color)
		self:OnColorChanged(self.picker, self.picker, color)
		
		colorPicker:Show(true)
	end
	
	if not settingsForm then
		MRF:InitSettings()
	end
	
	colorPicker = MRF:LoadForm(FORM_COLORPICKER_TEMPLATE, settingsForm, colorHandler)
	colorHandler.header = colorPicker:FindChild("Header")
	colorHandler.picker = colorPicker:FindChild("Color")
	colorHandler.slider = colorPicker:FindChild("AlphaSlider")
	colorHandler.btn2x = colorPicker:FindChild("Checkbox_2x")
	colorHandler.boxR = colorPicker:FindChild("EditBoxR")
	colorHandler.boxG = colorPicker:FindChild("EditBoxG")
	colorHandler.boxB = colorPicker:FindChild("EditBoxB")
	colorHandler.boxA =	colorPicker:FindChild("EditBoxA")
	colorHandler.oldColor = colorPicker:FindChild("Color_old")
	colorHandler.newColor = colorPicker:FindChild("Color_new")

	colorHandler.header:SetText(L["Color Picker"])
	colorPicker:FindChild("Title_NewColor"):SetText(L["New Color:"])
	colorPicker:FindChild("Title_OldColor"):SetText(L["Old Color:"])
	colorPicker:FindChild("Button_Copy"):SetText(L["Copy"])
	colorPicker:FindChild("Button_Paste"):SetText(L["Paste"])
	
	colorHandler.btn2x:SetTooltip(L["tt2x"])
	
	function MRF:InitColorPicker() --replace the function, we do not want this to be done multiple times.
		return colorHandler
	end
	return colorHandler
end

function MRF:applyPreview(parent, modKey, type) end --defined in 'do' below, just for Houston reference.
do
	local floor, ceil = math.floor, math.ceil

	local bars = {}
	local icons = {}
	local nones = {}
	local suppPrev = {["bar"] = bars, ["icon"] = icons, ["none"] = nones}
	local template = nil;
	local templateOpt = MRF:GetOption(nil, "frame")
	
	local function reposition(frame)
		local h, w = frame.frame:GetHeight(), frame.frame:GetWidth()
		local t = -floor(h/2)
		local b = h+t
		local l = -floor(w/2)
		local r = w+l
		
		frame.frame:SetAnchorPoints(0.5,0.5,0.5,0.5)
		frame.frame:SetAnchorOffsets(l,t,r,b)
	end
	
	local cBlue = ApolloColor.new("FF00A0FF")
	local cRed = ApolloColor.new("A0FF0000")
	local function recolorBar(frame, modKey)
		frame:SetVar("backcolor", nil, cBlue)
		--you can gain access to the barHandler by indexing with the modKey,
		--all shown bars are available throught this. We cant recolor not shown stuff...
		if not frame[modKey] then return end
		frame:SetVar("barcolor", modKey, cRed, cRed)
		frame:SetVar("progress", modKey, 0.5)
	end
	
	local function recolorIcon(frame, modKey)
		frame:SetVar("backcolor", nil, cBlue)
		local icon = MRF:GetModIcons(modKey)[frame.frame]
		icon:SetSprite("WhiteFill")
		icon:SetBGColor(cRed)
	end
	
	local function recolorNone(frame)
		frame:SetVar("backcolor", nil, cBlue)
		for _, modKey in ipairs(frame.oldTemp) do
			frame:SetVar("progress", modKey, 0.5)
			frame:SetVar("barcolor", modKey, cRed, cRed)
		end
	end
	
	templateOpt:OnUpdate(function(newTemplate) 
		template = newTemplate;
		for frame, key in pairs(bars) do
			frame:UpdateOptions(newTemplate)
			reposition(frame)
			recolorBar(frame, key)
		end
		for frame, key in pairs(icons) do
			frame:UpdateOptions(newTemplate)
			reposition(frame)
			recolorIcon(frame, key)
		end
		for frame in pairs(nones) do
			frame:UpdateOptions(newTemplate)
			reposition(frame)
			recolorNone(frame)
		end
	end)
	
	local btnBarHandler = {ButtonClick = function(self, btn) 
		local frame = btn:GetData()
		local modKey = bars[frame]
		
		frame:UpdateOptions(template)
		reposition(frame)
		recolorBar(frame, modKey)
	end}
	
	local btnIconHandler = {ButtonClick = function(self, btn) 
		local frame = btn:GetData()
		local modKey = icons[frame]
		
		frame:UpdateOptions(template)
		reposition(frame)
		recolorIcon(frame, modKey)
	end}
	
	local btnNoneHandler = {ButtonClick = function(self, btn) 
		local frame = btn:GetData()
		
		frame:UpdateOptions(template)
		reposition(frame)
		recolorNone(frame)
	end}
	
	local L = MRF:Localize({--English
		["ttPreview"] = [[Preview:
			This picture is supposed to help understand how the settings change the look of a frame.
			Blue is the outline of the whole frame.
			Red is the currently selected item.]],
	}, {--German
		["Redraw Preview"] = "Neu Laden",
		["ttPreview"] = [[Vorschau:
			Dieses Bild soll dabei helfen, vorgenommene Änderungen darzustellen.
			Blau ist dabei die Fläche eines einzelnen Frames.
			Rot markiert wird der momentan veränderbare Bereich.]]
	}, {--French
	})
	
	function MRF:applyPreview(parent, modKey, type)
		local tar = suppPrev[type]
		if not tar then return end
		
		local frame = self:newFrame(parent, template)
		tar[frame] = modKey
		
		local handler = type == "bar" and btnBarHandler or type == "icon" and btnIconHandler or btnNoneHandler
		local btn = MRF:LoadForm("SmallButton", parent, handler)
		btn:SetTooltip(L["Redraw Preview"])
		btn:SetData(frame)
		
		MRF:LoadForm("QuestionMark", parent):SetTooltip(L["ttPreview"])
		
		handler:ButtonClick(btn) --Redraw or initially draw the Preview
	end
end

do
	local tabs = {}
	local children = setmetatable({}, {__index = function(t, k) 
		t[k] = {}
		return t[k]; 
	end})
	
	local tabHandler = {}; --filled in :InitSettings()
	
	function MRF:AddMainTab(name, handler, func) --this does not need a handler/func if it doesnt want a tab to be displayed.
		tabs[name] = handler and {handler, func} or false
		tabs[#tabs+1] = name
	end
	
	function MRF:AddChildTab(name, parentName, handler, func) --child Tabs without an initFunc do not get Created
		if not handler then return end
		children[parentName][name] = {handler, func}
		children[parentName][#children[parentName]+1] = name
	end
	
	local function referencer(tar)
		return function(self, idx)
			local f = function(_, ...)
				return tar[idx](tar, ...)
			end
			rawset(self, idx, f)
			return f
		end
	end
	
	local delayedLoader = {
		Show = function(self, ...)
			local name, handler, func = self.name , self.handler, self.func	
			
			local pnl =  MRF:LoadForm("TabForm", tabHandler.panel)
			--we do this first, because we want this table to behave like pnl, before we call the handler.
			for i in pairs(self) do --wipe the table.
				self[i] = nil
			end
			setmetatable(self, {__index = referencer(pnl)}) --all function-calls will be referenced to pnl
			
			--actually load the frames:
			if type(handler) == "function" then
				handler(pnl, name)
			else
				handler[func](handler, pnl, name)
			end
			
			pnl:Show(...)
			return pnl 
		end
	}
	
	local function initPanel(tbl, name)
		if tbl == false then return end
		local handler, func = unpack(tbl)
		
		local pnl = setmetatable({name = name, handler = handler, func = func }, {__index = delayedLoader})
		
		return pnl
	end
	
	local function MRF_AddMainTab(self, name, handler, func) --this is the version, which will be used after having initialized the Settins already
		local form = self:LoadForm("ListParent", tabHandler.tabs, tabHandler)
		local btn = form:FindChild("Button")
		btn:SetText(name)
		btn:SetData(initPanel(handler and {handler, func} or false, name))
		tabs[name] = form
		
		tabHandler.tabs:ArrangeChildrenVert()
	end
	
	local function MRF_AddChildTab(self, name, parentName, handler, func) --this is the version, which will be used after having initialized the Settins already
		if not tabs[parentName] or not handler then return end
		local child = self:LoadForm("ListChild", tabs[parentName], tabHandler)
		child:SetText(name)
		child:SetData(initPanel({handler, func}, name))--the tabbed Panel
		children[parentName][name] = child
		
		tabs[parentName]:ArrangeChildrenVert()
	end
	
	function tabHandler:OnCancel()
		settingsForm:Show(false,false)
	end
		
	function tabHandler:AddPlayer(...)
		MRF:MakePlayerAUnit()
	end
	
	function tabHandler:ShowRaidAnchor()
		MRF:ShowRaidAnchor()
	end
	
	function MRF:InitSettings()
		if settingsForm then --already Initialized
			settingsForm:Show(true, false)
			return
		end
	
		tabHandler.frame = self:LoadForm("SettingsForm", nil, tabHandler)
		settingsForm = tabHandler.frame
		tabHandler.tabs = tabHandler.frame:FindChild("TabList")
		tabHandler.panel = tabHandler.frame:FindChild("TabPanel")
		
		for _, name in ipairs(tabs) do
			local tab = tabs[name]
			local form = self:LoadForm("ListParent", tabHandler.tabs, tabHandler)
			local btn = form:FindChild("Button")
			btn:SetText(name)
			btn:SetData(initPanel(tab, name))--the tabbed panel.
			tabs[name] = form
			for _, chName in ipairs(children[name]) do
				local chTab = children[name][chName]
				local child = self:LoadForm("ListChild", form, tabHandler)
				child:SetText(chName)
				child:SetData(initPanel(chTab, chName))--the tabbed Panel
				children[name][chName] = child
			end
			form:ArrangeChildrenVert()
		end
		tabHandler.tabs:ArrangeChildrenVert()
		
		self.AddMainTab = MRF_AddMainTabd
		self.AddChildTab = MRF_AddChildTab
	end
	
	function MRF:OnConfigure()
		self:InitSettings()
	end
	
	local tabAddHeight = 10; --32-22
	local childHeight = 22;
	
	function tabHandler:TabSelected(wndHandler)
		local cont = wndHandler:GetParent()
		--Expand
		local n = #(cont:GetChildren())
		local height = (n*childHeight)+tabAddHeight
		cont:SetAnchorOffsets(0,0,0,height)
		
		cont:GetParent():ArrangeChildrenVert()
		if self:ShowTab(wndHandler) then
			self:UnselectChild()
		end
	end
	
	function tabHandler:TabUnselected(wndHandler,...)
		local cont = wndHandler:GetParent()
		--Shrink
		cont:SetAnchorOffsets(0,0,0,childHeight+tabAddHeight)
		cont:GetParent():ArrangeChildrenVert()
	end
	
	local selectedChild = nil;
	
	function tabHandler:ChildTabSelected(wndHandler)
		selectedChild = wndHandler
		self:ShowTab(wndHandler)
	end
	
	function tabHandler:UnselectChild()
		if selectedChild then
			selectedChild:SetCheck()
			selectedChild = nil
			return true --did something
		end
		return false
	end
	
	local shownPnl = nil;
	
	local shownTab = MRF:GetOption("UI_TabShown")
	
	function tabHandler:ShowTab(button)
		local pnl = button:GetData()
		if pnl then		
			if shownPnl then
				shownPnl:Show(false, false)
			end
			
			local rep = pnl:Show(true, false)
			
			if rep then --if pnl isnt really a window, but the replacement, its :Show will return a window, being the pnl.
				button:SetData(rep)
				pnl = rep
			end
			
			shownPnl = pnl
			shownTab:Set(pnl)
			return true --shown something
		end
		return false
	end
	
	--[[
	MRF:AddMainTab("Main1", function(wnd) wnd:SetText("Main1") end)
	MRF:AddMainTab("Main2")
	MRF:AddMainTab("Main3")
	MRF:AddChildTab("Child1", "Main1", function(wnd) wnd:SetText("Child1") end)
	MRF:AddChildTab("Child2", "Main2", function(wnd) wnd:SetText("Child2") end)
	MRF:AddChildTab("Child3", "Main2", function(wnd) wnd:SetText("Child3") end)
	--]]
end







