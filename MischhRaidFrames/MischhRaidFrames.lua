-----------------------------------------------------------------------------------------------
-- Client Lua Script for MischhRaidFrames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- MischhRaidFrames Module Definition
-----------------------------------------------------------------------------------------------
local MischhRaidFrames = {}
MRF = nil
 
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
	MRF = self
	self.xmlDoc = XmlDoc.CreateFromFile("MischhRaidFrames.xml")
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
	--[[###################
		Bar (parentFrame, relPosition , fullColor , emptyColor )
			:SetProgress( 0 - 1 )
			:SetText( ... ) 	pass throught to Window
			:SetFont( ... ) 	pass throught to Window
			:SetTextColor( ... )pass throught to Window
			:SetColor( leftColor, rightColor)		
	--###################]]
	local function setProgress(handler, progress)
		progress = progress < 0 and 0 or progress > 1 and 1 or progress -- 0-100 -> 0-1
		
		handler.leftBar:SetProgress(progress)
		handler.rightBar:SetProgress(1-progress)
	end
	
	local function setText(handler, ...)
		handler.leftBar:SetText(...)
	end
	
	local function setFont(handler, ...)
		handler.leftBar:SetFont(...)
	end
	
	local function setTextColor(handler, ...)
		handler.leftBar:SetTextColor(...)
	end
	
	local function setColor( handler, leftCol, rightCol )
		if leftCol then
			handler.leftBar:SetBarColor(leftCol)
		end
		if rightCol then
			handler.rightBar:SetBarColor(rightCol)
		end
	end
	
	local function unuse( handler )
		handler.rightBar = handler.rightBar:Destroy() and nil
		handler.leftBar = handler.leftBar:Destroy() and nil
		handler.frame = handler.frame:Destroy() and nil
	end
	
	function MischhRaidFrames:newBar(parent, pos, fullColor, emptyColor)
		local handler = {
			SetProgress = setProgress,
			SetText = setText,
			SetFont = setFont,
			SetColor = setColor,
			SetTextColor = setTextColor,
			SetUnused = unuse,
		}
		handler.frame = Apollo.LoadForm(self.xmlDoc, "BarForm", parent, handler)
		handler.leftBar = handler.frame:FindChild("LeftBar")
		handler.rightBar = handler.frame:FindChild("RightBar")
		
		handler.frame:SetAnchorPoints(unpack(pos))
		
		handler:SetColor( 	fullColor or CColor.new(39/255,39/255,39/255,1),
							emptyColor or CColor.new(0.8,0,0,1) )
		
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
		backcolor = function(handler, frame, color)
			frame:SetBGColor(color or bgColor)
		end,
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
	
	local function updateOpt( handler, options )
		
		wipeEntries(handler, options)
		
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
			handler[tbl.modKey] = MRF:newBar(handler.panel, pos)
			pos[2] = pos[4]
		end
		
		for _, pos in ipairs( offset ) do --the relative 'placed ontop' bars
			local i = pos[0]
			local tbl = options[pos]
			pos = {0, i/total, 1, (tbl.size+i)/total}
			handler[tbl.modKey] = MRF:newBar(handler.panel, pos)
		end
		
		for _, pos in ipairs( fixed ) do --the fixed 'placed ontop' bars
			local tbl = options[pos]
			handler[tbl.modKey] = MRF:newBar(handler.panel, pos)
		end
	
		handler.options = options
	end
	
	local function setVar( handler, mode, key, ... )
		modes[mode](handler, handler[key], ...)
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
		}
		handler.frame = Apollo.LoadForm(self.xmlDoc, "FrameBackground", parent, handler)
		handler.panel = handler.frame:FindChild("InsetFrame")
		
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
