local Apollo = require "Apollo"

local MRF = Apollo.GetAddon("MischhRaidFrames")

local tFrames; -- = MRF:GetFrameTable() -- requires FrameHandler.lua to be executed first!

--all of these are self-creating tables.
local tWndTexts = {}--[modKey] = {[unitFrame] = wndText}

local tTextSettings = {}--[modKey] = {bAct, nX, nY, strAnchor, strFont, tColor}
local tTextOptions = {} --[modKey] = {oAct, oX, oY, oAnchor, oFont, oColor}
local tTextHandlers = {} --[modKey] = updateHandler

local function updateThis(tSettings, wndText)
  wndText:SetAnchorOffsets(tSettings.nX, tSettings.nY, tSettings.nX, tSettings.nY)

  wndText:SetTextFlags("DT_CENTER", not tSettings.strAnchor:find("[LR]"))
  wndText:SetTextFlags("DT_RIGHT", tSettings.strAnchor:find("R") and true or false)
  wndText:SetTextFlags("DT_VCENTER", not tSettings.strAnchor:find("[TB]"))
  wndText:SetTextFlags("DT_BOTTOM", tSettings.strAnchor:find("B") and true or false)

	wndText:SetFont(tSettings.strFont or "Nameplates")
end

local function updateAllOf(modKey)
  if not tFrames and MRF.GetFrameTable then tFrames = MRF:GetFrameTable() end
  local tSettings = tTextSettings[modKey]
  if tSettings.bAct then
    local tTexts = tWndTexts[modKey]
    for _, tFrame in pairs(tFrames or {}) do
      local wndText = tTexts[tFrame.frame]
      updateThis(tSettings, wndText)
    end
  else
    for idx, wndText in pairs(tWndTexts[modKey]) do
      wndText:Destroy()
      tWndTexts[modKey][idx] = nil
    end
  end
end

local handler = {}--need to pass a Handler into :LoadForm - we dont use it.

tWndTexts = setmetatable(tWndTexts,{__index = function(t, modKey)
  tTextOptions[modKey] = tTextOptions[modKey] --make sure the options are initialized.

  local tTexts = setmetatable({}, {__index = function(tbl, parent)
		local wndText = MRF:LoadForm("TextTemplate", parent, handler)

    updateThis(tTextSettings[modKey], wndText)

    rawset(tbl, parent, wndText)
		return tbl[parent]
	end})

	rawset(t, modKey, tTexts)
	return tTexts
end})

tTextSettings = setmetatable(tTextSettings, {__index = function(t, modKey)
  rawset(t, modKey, {
    bAct = false,
    nX = 0,
    nY = 0,
    strAnchor = "TL",
    strFont = "Nameplates",
    -- tColor = nil,
  })
  tTextOptions[modKey] = tTextOptions[modKey] --this is the magic initializing the above.

  return t[modKey]
end})

tTextOptions = setmetatable(tTextOptions, {__index = function(t, modKey)
  local tOptions = {
    oAct = MRF:GetOption(nil, "modules", modKey, "bTextActive"),
    oX = MRF:GetOption(nil, "modules", modKey, "nTextX"),
    oY = MRF:GetOption(nil, "modules", modKey, "nTextY"),
    oAnchor = MRF:GetOption(nil, "modules", modKey, "strTextAnchor"),
    oFont = MRF:GetOption(nil, "modules", modKey, "strTextFont"),
  }
  rawset(t, modKey, tOptions) --just for safety... do this before all the magic

  local tHandler = tTextHandlers[modKey]

  tOptions.oAct:OnUpdate(tHandler, "OnActUpdate")
  tOptions.oX:OnUpdate(tHandler, "OnXUpdate")
  tOptions.oY:OnUpdate(tHandler, "OnYUpdate")
  tOptions.oAnchor:OnUpdate(tHandler, "OnAnchorUpdate")
  tOptions.oFont:OnUpdate(tHandler, "OnFontUpdate")

  tOptions.oAct:ForceUpdate()
  tOptions.oX:ForceUpdate()
  tOptions.oY:ForceUpdate()
  tOptions.oAnchor:ForceUpdate()
  tOptions.oFont:ForceUpdate()

  return tOptions
end})

local HandlerClassMeta;
tTextHandlers = setmetatable(tTextHandlers, {__index = function(t, modKey)
  local tHandler = setmetatable({modKey = modKey}, HandlerClassMeta)
  rawset(t, modKey, tHandler)

  return tHandler
end})
do
  local HandlerClass = {
    modKey = nil
  }
  HandlerClassMeta = {__index = HandlerClass}

  function HandlerClass:OnActUpdate(newAct)
    if newAct == nil then
      tTextOptions[self.modKey].oAct:Set(false)
    else
      tTextSettings[self.modKey].bAct = newAct
      updateAllOf(self.modKey)
    end
  end

  function HandlerClass:OnXUpdate(newX)
    if type(newX) ~= "number" then
      tTextOptions[self.modKey].oX:Set(0)
    else
      tTextSettings[self.modKey].nX = newX
      updateAllOf(self.modKey)
    end
  end

  function HandlerClass:OnYUpdate(newY)
    if type(newY) ~= "number" then
      tTextOptions[self.modKey].oY:Set(0)
    else
      tTextSettings[self.modKey].nY = newY
      updateAllOf(self.modKey)
    end
  end

  function HandlerClass:OnAnchorUpdate(newAnchor)
    if type(newAnchor) ~= "string" then
      tTextOptions[self.modKey].oAnchor:Set("C")
    else
      tTextSettings[self.modKey].strAnchor = newAnchor
      updateAllOf(self.modKey)
    end
  end

  function HandlerClass:OnFontUpdate(newFont)
    if type(newFont) ~= "string" then
      tTextOptions[self.modKey].oFont:Set("Nameplates")
    else
      tTextSettings[self.modKey].strFont = newFont
      updateAllOf(self.modKey)
    end
  end
end

function MRF.GetModTextForFrame(_, modKey, frame)
  return tWndTexts[modKey][frame]
end

function MRF.GetModTexts(_, modKey)
	return tWndTexts[modKey]
end

function MRF.GetAllTexts(_)
  return tWndTexts
end
