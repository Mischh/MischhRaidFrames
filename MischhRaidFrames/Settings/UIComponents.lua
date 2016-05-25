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
	handler.text:SetText(tostring(val)) --we actually only update this way.
	if handler.block then return end
	handler.slider:SetValue(val or handler.minimum)
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

function MRF:applySlider(parent, selector, min, max, steps)
	min = min or 0
	max = max or min+1
	steps = steps or 0.1
	translator = translator or tostring
	
	local handler = {opt = selector, block = false, minimum = min, maximum = max, ticklen = steps}
	handler.SliderChanged = sliderChanged
	handler.OnUpdate = onUpdate
	handler.SetMinMax = setMinMax
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

do
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
end

function MRF:InitColorPicker()
	local colorHandler = {color = ApolloColor.new(1,1,1,1), alpha = 1, copied = ApolloColor.new(1,1,1,1)}
	local colorPicker = nil
	function colorHandler:OnColorChanged( wndHandler, wndControl, color )
		local r = ("%x"):format(color.r*255):gsub("^(%x)$", "0%1")
		local g = ("%x"):format(color.g*255):gsub("^(%x)$", "0%1")
		local b = ("%x"):format(color.b*255):gsub("^(%x)$", "0%1")
		local a = ("%x"):format(self.alpha*255):gsub("^(%x)$", "0%1")
		
		color = ApolloColor.new(color.r, color.g, color.b, self.alpha)
		
		self.color = color
		
		self:SetRText(r)
		self:SetGText(g)
		self:SetBText(b)
		self:SetAText(a)
		self:SetAlphaSlider(color.a)
		
		colorHandler.newColor:SetBGColor(color)
		if self.callback then
			self.callback:Set({a=color.a, r=color.r, g=color.g, b=color.b}, a..r..g..b)
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
		self.picker:SetColor(color)
		self.alpha = color.a
		self:OnColorChanged(self.picker, self.picker, color)
	end
	
	function colorHandler:ClickCopy(...)
		self.copied = self.color
	end
	
	function colorHandler:ClickPaste(...)
		local color = self.copied
		self.picker:SetColor(color)
		self.alpha = color.a
		self:OnColorChanged(self.picker, self.picker, color)
	end
	
	function colorHandler:Pick(callback, initial)
		if not initial then return end
		local color = ApolloColor.new(initial)
		
		self.callback = callback
		self.color = color
		self.alpha = color.a
		
		self.oldColor:SetBGColor(color)
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
	colorHandler.boxR = colorPicker:FindChild("EditBoxR")
	colorHandler.boxG = colorPicker:FindChild("EditBoxG")
	colorHandler.boxB = colorPicker:FindChild("EditBoxB")
	colorHandler.boxA =	colorPicker:FindChild("EditBoxA")
	colorHandler.oldColor = colorPicker:FindChild("Color_old")
	colorHandler.newColor = colorPicker:FindChild("Color_new")

	function MRF:InitColorPicker() --replace the function, we do not want this to be done multiple times.
		return colorHandler
	end
	return colorHandler
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
	
	local function initPanel(tbl, name)
		if tbl == false then return end
		local handler, func = unpack(tbl)
		local pnl = MRF:LoadForm("TabForm", tabHandler.panel) --needs no handler - nothing to handle
		if type(handler) == "function" then
			handler(pnl, name)
		else
			handler[func](handler, pnl, name)
		end
		return pnl
	end
	
	local function MRF_AddMainTab(self, name, handler, func) --this is the version, which will be used after having initialized the Settins already
		local form = self:LoadForm("ListParent", tabHandler.tabs, tabHandler)
		local btn = form:FindChild("Button")
		btn:SetText(name)
		btn:SetData(initPanel(handler and {handler, func} or false))
		tabs[name] = form
		
		tabHandler.tabs:ArrangeChildrenVert()
	end
	
	local function MRF_AddChildTab(self, name, parentName, handler, func) --this is the version, which will be used after having initialized the Settins already
		if not tabs[parentName] or not handler then return end
		local child = self:LoadForm("ListChild", tabs[parentName], tabHandler)
		child:SetText(name)
		child:SetData(initPanel({handler, func}))--the tabbed Panel
		children[parentName][name] = child
		
		tabs[parentName]:ArrangeChildrenVert()
	end
	
	function tabHandler:OnCancel()
		settingsForm:Show(false,false)
	end
	
	function tabHandler:ToggleProfileFrame()
		self.profiles:Show(not self.profiles:IsShown(), false)
	end
	
	function tabHandler:InitProfiles(parent)
		local invProf = {
			[GameLib.CodeEnumAddonSaveLevel.Character] = "Character", 
			[GameLib.CodeEnumAddonSaveLevel.Account] = "Account", 
			[GameLib.CodeEnumAddonSaveLevel.General] = "General",
			[GameLib.CodeEnumAddonSaveLevel.Realm] = "Realm",
		}
		local listed = {
			GameLib.CodeEnumAddonSaveLevel.Character,
			GameLib.CodeEnumAddonSaveLevel.Realm,
			GameLib.CodeEnumAddonSaveLevel.Account,
			GameLib.CodeEnumAddonSaveLevel.General,
		}
		local function trans(eLvl)
			if eLvl then
				return invProf[eLvl]
			else
				return ""
			end
		end
		
		local optCopy = MRF:GetOption("Settings_ProfileCopy")
		local optProf = MRF:GetOption("profile")
	
		MRF:applyDropdown(parent:FindChild("Dropdown_Profile"), listed, optProf, trans)
		MRF:applyDropdown(parent:FindChild("Dropdown_Copy"), listed, optCopy, trans)
		
		optCopy:OnUpdate(function(eLevel)
			if eLevel then 
				local cur = optProf:Get()
				MRF:CopyProfile(eLevel, cur)
				optCopy:Set(nil)
			end
		end)
		
		optProf:ForceUpdate()
	end
	
	function tabHandler:AddPlayer(...)
		MRF:MakePlayerAUnit()
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
		tabHandler.profiles = tabHandler.frame:FindChild("ProfilesFrame")
		
		tabHandler:InitProfiles(tabHandler.profiles)
		
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
		if self:ShowTab(wndHandler:GetData()) then
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
		self:ShowTab(wndHandler:GetData())
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
	
	function tabHandler:ShowTab(pnl)
		if pnl then
			if shownPnl then
				shownPnl:Show(false, false)
			end
			shownPnl = pnl
			pnl:Show(true, false)
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







