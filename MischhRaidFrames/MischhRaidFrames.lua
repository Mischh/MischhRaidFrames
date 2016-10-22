-----------------------------------------------------------------------------------------------
-- Client Lua Script for MischhRaidFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- MischhRaidFrames Module Definition
-----------------------------------------------------------------------------------------------
local MischhRaidFrames = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MischhRaidFrames:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function MischhRaidFrames:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "MischhRaidFrames"
	local tDependencies = {}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- MischhRaidFrames OnLoad
-----------------------------------------------------------------------------------------------
function MischhRaidFrames:OnLoad()
    -- load our form file
	MischhRaidFrames = self --DO NOT REMOVE! -> ERRORS! (We apply the Instance to the Template)
	self.xmlDoc = XmlDoc.CreateFromFile("MischhRaidFrames.xml")
	Apollo.LoadSprites("textures/ForgeUI_Textures.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function MischhRaidFrames:LoadForm(name, parent, handler)
	return Apollo.LoadForm(self.xmlDoc, name, parent, handler)
end

-----------------------------------------------------------------------------------------------
-- MischhRaidFrames OnDocLoaded
-----------------------------------------------------------------------------------------------
do
	local load = {}
	local loaded = false
	
	local function exec(f, t)
		if not t then
			f()
		elseif type(t[f]) == "function" then
			t[f](t)
		end
	end
	
	function MischhRaidFrames:OnDocLoaded()
		loaded = true
		Apollo.RegisterSlashCommand("mrf", "InitSettings", self)
		
		for f,t in pairs(load) do
			exec(f,t)
		end 
	end
	
	function MischhRaidFrames:OnceDocLoaded(func, tbl)
		if not func then return end
			
		if not loaded then
			if type(tbl) == "table" then
				load[func] = tbl --if tbl is actually a table, we assume func is a correct key for it.
			elseif type(func) == "function" then
				load[func] = false
			end --all other situations are useless.
		else
			if type(tbl) == "table" then
				if type(tbl[func]) == "function" then
					tbl[func](tbl)
				end
			elseif type(func) == "function" then
				func()
			end
		end
	end
end
-----------------------------------------------------------------------------------------------
-- MischhRaidFrames Functions
-----------------------------------------------------------------------------------------------

do
	local Bar = {} --Template
	Bar["__index"] = Bar
	
	function Bar:SetProgress(progress)
		progress = progress < 0 and 0 or progress > 1 and 1 or progress -- 0-100 -> 0-1
		
		self.leftBar:SetProgress(progress)
		self.rightBar:SetProgress(1-progress)
	end
	
	function Bar:SetText(...)
		self.leftBar:SetText(...)
	end
	
	function Bar:SetFont(...)
		self.leftBar:SetFont(...)
	end
	
	function Bar:SetTextColor(...)
		self.leftBar:SetTextColor(...)
	end
	
	function Bar:SetColor(leftCol, rightCol )
		if leftCol then
			self.leftBar:SetBarColor(leftCol)
		end
		if rightCol then
			self.rightBar:SetBarColor(rightCol)
		end
	end
	
	function Bar:SetTexture(leftTexture, rightTexture )
		if leftTexture then
			self.leftBar:SetFullSprite(leftTexture)
		end
		if rightTexture then
			self.rightBar:SetFullSprite(rightTexture)
		end
	end
	
	local hPosOpt = { --the first is to be activated, following to be deactivated.
		l = {nil, 'DT_CENTER', 'DT_RIGHT'},
		c = {'DT_CENTER', 'DT_RIGHT'},
		r = {'DT_RIGHT', 'DT_CENTER'},
	}
	local vPosOpt = {
		t = {nil, 'DT_VCENTER', 'DT_BOTTOM'},
		c = {'DT_VCENTER', 'DT_BOTTOM'},
		b = {'DT_BOTTOM', 'DT_VCENTER'},
	}
	
	-- eHPos = 'l', 'c', 'r' for Left, Center, Right
	-- eVPos = 't', 'c', 'b' for Top, Center, Bottom
	function Bar:SetTextPos(hPos, vPos )
		if hPosOpt[hPos or ""] then
			for i, flag in pairs(hPosOpt[hPos]) do
				self.leftBar:SetTextFlags(flag, i==1)
			end
		end
		if vPosOpt[vPos or ""] then
			for i, flag in pairs(vPosOpt[vPos]) do
				self.leftBar:SetTextFlags(flag, i==1)
			end
		end
	end
	
	-- 'L' 'T' 'R' 'B' for the direction to which its increasing towards
	local orientations = {
		L = {false, true},
		T = {true, true},
		R = {false, false},
		B = {true, false}}
	function Bar:SetOrientation(target)
		local arg = orientations[target]
		self.leftBar:SetStyleEx("VerticallyAligned", arg[1])
		self.rightBar:SetStyleEx("VerticallyAligned", arg[1])
		
		self.leftBar:SetStyleEx("BRtoLT", arg[2])
		self.rightBar:SetStyleEx("BRtoLT", not arg[2])
	end
	
	function Bar:SetUnused()
		self.rightBar = self.rightBar:Destroy() or nil
		self.leftBar = self.leftBar:Destroy() or nil
		self.frame = self.frame:Destroy() or nil
	end
	
	function MischhRaidFrames:newBar(parent, pos, lTexture, rTexture, hTextPos, vTextPos, orientation)
		local handler = setmetatable({}, Bar)
		handler.frame = Apollo.LoadForm(self.xmlDoc, "BarForm", parent, handler)
		handler.leftBar = handler.frame:FindChild("LeftBar")
		handler.rightBar = handler.frame:FindChild("RightBar")
		
		handler.frame:SetAnchorPoints(unpack(pos))
		
		handler:SetTexture(lTexture, rTexture)
		handler:SetTextPos(hTextPos, vTextPos)
		
		handler:SetOrientation(orientation or 'R')
		
		return handler
	end

end

do
	--[[###################
		Frame (parentFrame, initialOptions)
			:UpdateOptions( options )	Table which contains specifications for the Frame.
			:SetVar( mode, key, ... )	... are the values 
	--###################]]
	
	local bgColor = ApolloColor.new("FF000000")
	local function isBarPos(pos)
		return type(pos) ~= "string"
	end
	
	local modes = {
		textcolor = function(handler, frame, color)
			frame:SetTextColor(color)
		end,
		text = function(handler, frame, text)
			frame:SetText(text)
		end,
		barcolor = function(handler, barHandler, leftCol, rightCol)
			barHandler:SetColor(leftCol, rightCol)
		end,
		progress = function(handler, barHandler, barVal)
			barHandler:SetProgress(barVal)
		end,
		backcolor = function(handler, _, color)
			handler:SetBGColor(color or bgColor)
		end,
		bartexture = function(handler, barHandler, leftTexture, rightTexture)
			barHandler:SetTexture(leftTexture, rightTexture)
		end,
		textposition = function(handler, barHandler, hPos, vPos)
			barhandler:SetTextPos(hPos, vPos)
		end
	}
	
	local function wipeEntries(handler, newOptions)
		for pos, modKey in pairs( handler.oldTemp or {} ) do
			handler[modKey] = handler[modKey]:SetUnused()
		end
		handler.oldTemp = {}
		for pos, entry in pairs(newOptions) do
			if isBarPos(pos) then
				handler.oldTemp[pos] = entry.modKey
			end
		end
	end
	
	local function calcHeight( stack )
		local h = 0
		for i,v in ipairs(stack) do
			h = h + v.size
		end
		return h;
	end
	
	local function show(handler, ...)
		handler.frame:Show(...)
	end
	
	local black = ApolloColor.new("FF000000")
	local function updateOpt( handler, options )
		
		wipeEntries(handler, options)
		
		--background color
		local back = options.backcolor and ApolloColor.new(options.backcolor) or black
		handler.frame:SetBGColor(back)
		
		--size
		if options.size then
			handler.frame:SetAnchorOffsets(unpack(options.size))
		end
		
		--inset
		local inset = options.inset or 0
		handler.panel:SetAnchorOffsets(inset, inset, -inset, -inset)
		
		--build stack
		local total = calcHeight( options )
		
		local stacked = {}
		local offset = {}
		local fixed = {}
		for pos,tbl in pairs(options) do
			if type(pos) == "table" then
				if pos[0] then
					offset[#offset+1] = pos 
				else
					fixed[#fixed+1] = pos
				end
			elseif type(pos) == "number" then
				stacked[pos] = true
			end
		end
		
		local pos = {0, 0, 1, 0} --L T R B
		for i in ipairs( stacked ) do --the 'normally' placed bars
			local tbl = options[i]
			pos[4] = pos[2] + (tbl.size/total)
			handler[tbl.modKey] = MischhRaidFrames:newBar(handler.layers[tbl.layer or 1], pos, tbl.lTexture, tbl.rTexture, tbl.hTextPos, tbl.vTextPos, tbl.barOrientation)
			pos[2] = pos[4]
		end
		
		for _, pos in ipairs( offset ) do --the relative 'placed ontop' bars
			local i = pos[0]
			local tbl = options[pos]
			pos = {0, i/total, 1, (tbl.size+i)/total}
			handler[tbl.modKey] = MischhRaidFrames:newBar(handler.layers[tbl.layer or 2], pos, tbl.lTexture, tbl.rTexture, tbl.hTextPos, tbl.vTextPos, tbl.barOrientation)
		end
		
		for _, pos in ipairs( fixed ) do --the fixed 'placed ontop' bars
			local tbl = options[pos]
			handler[tbl.modKey] = MischhRaidFrames:newBar(handler.layers[tbl.layer or 3], pos, tbl.lTexture, tbl.rTexture, tbl.hTextPos, tbl.vTextPos, tbl.barOrientation)
		end
	
		handler.options = options
	end
	
	local function setVar( handler, mode, key, ... )
		modes[mode](handler, handler[key or ""], ...)
	end
	
	local function empty()
	end
	
	local function setOp(handler, opacity,...)
		handler.tarOp = opacity
		handler.frame:SetOpacity(opacity,...)
	end
	
	local function getOp(handler, ...)
		return handler.frame:GetOpacity(...)
	end
	
	local function getTarOp(handler)
		return handler.tarOp
	end
	
	local function setBGCol(handler, color)
		handler.frame:SetBGColor(color)
	end
	
	local function _layerMeta(self, idx)
		if type(idx) ~= "number" then return self[1] end
		local layer = self[idx-1] --ensure the lower layer(s) had been drawn before this one. (variable never used)
		layer = MischhRaidFrames:LoadForm("FrameLayer", self.parent)
		rawset(self, idx, layer)
		return layer
	end
	
	function MischhRaidFrames:newFrame(parent, options)
		local handler = {
			SetVar = setVar,
			UpdateOptions = updateOpt,
			Show = show,
			MouseButtonUp = empty,
			MouseEnter = empty,
			MouseExit = empty,
			options = {},
			SetOpacity = setOp,
			GetOpacity = getOp,
			GetTargetedOpacity = getTarOp,
			SetBGColor = setBGCol,
		}
		handler.frame = Apollo.LoadForm(self.xmlDoc, "FrameBackground", parent, handler)
		handler.panel = handler.frame:FindChild("InsetFrame")
		handler.layers = setmetatable({
			[1] = self:LoadForm("FrameLayer", handler.panel),
			parent = handler.panel,
		}, {__index = _layerMeta})
		
		handler.frame:SetData(handler)
		
		handler:UpdateOptions(options)		
		return handler
	end

	--[[ FRAME OPTIONS:
		frame = {
			inset = 2,
			[1] = {size = 4, modKey = "Health", lColor = {Gray}, rColor = {GradientHealth}, 
					textSource = "Name", textColor = {ClassColor}},
			
			-- negative indexes(and 0) are not stacked, but offset from the top by the negative value.
			[{[0]=1}] = {size = 1, modKey = "Shield", lColor = {LightBlue}, rColor = {Black}, 
					textSource = nil, textColor = nil}
			
			-- tables as position give the AnchorPoints in the Frame as fixed position.
			[{0,0.8,1,0.2}] = {...}
		}
	--]]
	
end

-----------------------------------------------------------------------------------------------
-- MischhRaidFrames Instance
-----------------------------------------------------------------------------------------------
local MischhRaidFramesInst = MischhRaidFrames:new()
MischhRaidFramesInst:Init()
