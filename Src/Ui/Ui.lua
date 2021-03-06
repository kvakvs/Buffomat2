---@class Bm2UiModule
---@field popupDynamic table Popup menu on minimap icon and on the addon window
---@field managedUiFrames table<number, Bm2Control> All frames and buttons to be group managed/hidden/reused
local uiModule = Bm2Module.DeclareModule("Ui")

function uiModule:EarlyModuleInit()
  uiModule.managedUiFrames = {}
  uiModule.aceGui = LibStub("AceGUI-3.0")
end

local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local popupModule = Bm2Module.Import("UiPopup") ---@type Bm2PopupModule
local _t = Bm2Module.Import("Translation") ---@type Bm2TranslationModule

---@class Bm2Control

local function bm2FrameDragStart(self)
  self:StartMoving()
end

local function bm2FrameDragStop(self)
  self:StopMovingOrSizing()
  if self.Bm2DragStopCallback then
    self.Bm2DragStopCallback(self)
  end
end

function uiModule.EnableMoving(frame, callback)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", bm2FrameDragStart)
  frame:SetScript("OnDragStop", bm2FrameDragStop)
  frame.Bm2DragStopCallback = callback
end

local function bm2SelectTab(self)
  if not self.Bm2CombatLockdown or not InCombatLockdown() then
    local parent = self:GetParent()
    PanelTemplates_SetTab(parent, self:GetID())

    for i = 1, parent.numTabs do
      parent.Tabs[i].content:Hide()
    end

    self.content:Show()

    if parent.Tabs[self:GetID()].OnSelect then
      parent.Tabs[self:GetID()].OnSelect(self)
    end
  end
end

function uiModule.SelectTab(frame, id)
  if id and frame.Tabs and frame.Tabs[id] then
    bm2SelectTab(frame.Tabs[id])
  end
end

---Adds a Tab to a frame (main window for example)
---@param frame Bm2Control | string - where to add a tab
---@param name string - tab text
---@param tabFrame Bm2Control | string - tab text
---@param combatlockdown boolean - accessible in combat or not
function uiModule.AddTab(frame, name, tabFrame, combatlockdown)
  local frameName

  if type(frame) == "string" then
    frameName = frame
    frame = _G[frameName]
  else
    frameName = frame:GetName()
  end
  if type(tabFrame) == "string" then
    tabFrame = _G[tabFrame]
  end

  frame.numTabs = frame.numTabs and frame.numTabs + 1 or 1
  if frame.Tabs == nil then
    frame.Tabs = {}
  end

  frame.Tabs[frame.numTabs] = CreateFrame(
      "Button", frameName .. "Tab" .. frame.numTabs, frame,
      "CharacterFrameTabButtonTemplate")
  frame.Tabs[frame.numTabs]:SetID(frame.numTabs)
  frame.Tabs[frame.numTabs]:SetText(name)
  frame.Tabs[frame.numTabs]:SetScript("OnClick", bm2SelectTab)
  frame.Tabs[frame.numTabs].Bm2CombatLockdown = combatlockdown
  frame.Tabs[frame.numTabs].content = tabFrame
  tabFrame:Hide()

  if frame.numTabs == 1 then
    frame.Tabs[frame.numTabs]:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 4)
  else
    frame.Tabs[frame.numTabs]:SetPoint("TOPLEFT", frame.Tabs[frame.numTabs - 1], "TOPRIGHT", -14, 0)
  end

  bm2SelectTab(frame.Tabs[frame.numTabs])
  bm2SelectTab(frame.Tabs[1])
  return frame.numTabs
end

local bm2ResizeCursor ---@type Bm2Control

---@param self Bm2Control
---@param button Bm2Control
local function bm2SizingStop(self, button)
  self:GetParent():StopMovingOrSizing()

  if self.Bm2OnSizingStop then
    self.Bm2OnSizingStop(self:GetParent())
  end
end

---@param self Bm2Control
---@param button Bm2Control
local function bm2SizingStart(self, button)
  self:GetParent():StartSizing(self.Bm2SizeType)
  if self.Bm2OnSizingStart then
    self.Bm2OnSizingStart(self:GetParent())
  end
end

---@param self Bm2Control
local function bm2SizingEnter(self)
  if not (GetCursorInfo()) then
    bm2ResizeCursor:Show()
    bm2ResizeCursor.Texture:SetTexture(self.Bm2Cursor)
    bm2ResizeCursor.Texture:SetRotation(math.rad(self.Bm2Rotation), 0.5, 0.5)
  end
end

---@param self Bm2Control
---@param button Bm2Control
local function bm2SizingLeave(self, button)
  bm2ResizeCursor:Hide()
end

---@param self Bm2Control
local function bm2ResizeCursorUpdate(self)
  local X, Y = GetCursorPosition()
  local scale = self:GetEffectiveScale()
  self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", X / scale, Y / scale)
end

local bm2SizeCount = 0

---@param frame Bm2Control
local function bm2CreateSizeBorder(frame, name, a1, x1, y1, a2, x2, y2, cursor, rot, onSizingStartFn, onSizingStopFn)
  bm2SizeCount = bm2SizeCount + 1

  local frameSizeBorder ---@type Bm2Control

  frameSizeBorder = CreateFrame("Frame",
      (frame:GetName() or constModule.AddonName .. bm2SizeCount) .. "_size_" .. name,
      frame)
  frameSizeBorder:SetPoint("TOPLEFT", frame, a1, x1, y1)
  frameSizeBorder:SetPoint("BOTTOMRIGHT", frame, a2, x2, y2)
  frameSizeBorder.Bm2SizeType = name
  frameSizeBorder.Bm2Cursor = cursor
  frameSizeBorder.Bm2Rotation = rot
  frameSizeBorder.Bm2OnSizingStart = onSizingStartFn
  frameSizeBorder.Bm2OnSizingStop = onSizingStopFn
  frameSizeBorder:SetScript("OnMouseDown", bm2SizingStart)
  frameSizeBorder:SetScript("OnMouseUp", bm2SizingStop)
  frameSizeBorder:SetScript("OnEnter", bm2SizingEnter)
  frameSizeBorder:SetScript("OnLeave", bm2SizingLeave)

  return frameSizeBorder
end

function uiModule.EnableSizing(frame, border, OnStart, OnStop)
  if not bm2ResizeCursor then
    bm2ResizeCursor = CreateFrame("Frame", nil, UIParent)
    bm2ResizeCursor:Hide()
    bm2ResizeCursor:SetWidth(24)
    bm2ResizeCursor:SetHeight(24)
    bm2ResizeCursor:SetFrameStrata("TOOLTIP")
    bm2ResizeCursor.Texture = bm2ResizeCursor:CreateTexture()
    bm2ResizeCursor.Texture:SetAllPoints()
    bm2ResizeCursor:SetScript("OnUpdate", bm2ResizeCursorUpdate)
  end
  border = border or 8

  frame:EnableMouse(true)
  frame:SetResizable(true)

  bm2CreateSizeBorder(frame, "BOTTOM", "BOTTOMLEFT", border, border,
      "BOTTOMRIGHT", -border, 0, "Interface\\CURSOR\\UI-Cursor-SizeLeft",
      45, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "TOP", "TOPLEFT", border, 0,
      "TOPRIGHT", -border, -border, "Interface\\CURSOR\\UI-Cursor-SizeLeft",
      45, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "LEFT", "TOPLEFT", 0, -border,
      "BOTTOMLEFT", border, border, "Interface\\CURSOR\\UI-Cursor-SizeRight",
      45, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "RIGHT", "TOPRIGHT", -border, -border,
      "BOTTOMRIGHT", 0, border, "Interface\\CURSOR\\UI-Cursor-SizeRight",
      45, OnStart, OnStop)

  bm2CreateSizeBorder(frame, "TOPLEFT", "TOPLEFT", 0, 0,
      "TOPLEFT", border, -border, "Interface\\CURSOR\\UI-Cursor-SizeRight",
      0, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0,
      "BOTTOMLEFT", border, border, "Interface\\CURSOR\\UI-Cursor-SizeLeft",
      0, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "TOPRIGHT", "TOPRIGHT", 0, 0,
      "TOPRIGHT", -border, -border, "Interface\\CURSOR\\UI-Cursor-SizeLeft",
      0, OnStart, OnStop)
  bm2CreateSizeBorder(frame, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0,
      "BOTTOMRIGHT", -border, border, "Interface\\CURSOR\\UI-Cursor-SizeRight",
      0, OnStart, OnStop)
end

---Creates a string which will display a picture in a FontString
---@param texture string - path to UI texture file (for example can come from
---  GetContainerItemInfo(bag, slot) or spell info etc
function uiModule:FormatTexture(texture)
  return string.format(constModule.IconFormat, texture)
end

function uiModule:LateModuleInit()
  uiModule.popupDynamic = popupModule:CreatePopup(function() end) -- BOM.OptionsUpdate
end

-- Hides all icons and clickable buttons in the spells tab
function uiModule:HideAllManagedFrames()
  for i, frame in ipairs(uiModule.managedUiFrames) do
    frame:Hide()
  end
end
