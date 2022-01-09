local TOCNAME, _ = ...

---@class Bm2UiModule
local bm2ui = Bm2Module.DeclareModule("Ui")
---@type Bm2TranslationModule
local translation = Bm2Module.Import("Translation")
local function _t(key)
  return translation(key)
end

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

function bm2ui.EnableMoving(frame, callback)
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

function bm2ui.SelectTab(frame, id)
  if id and frame.Tabs and frame.Tabs[id] then
    bm2SelectTab(frame.Tabs[id])
  end
end

---Adds a Tab to a frame (main window for example)
---@param frame Bm2Control | string - where to add a tab
---@param name string - tab text
---@param tabFrame Bm2Control | string - tab text
---@param combatlockdown boolean - accessible in combat or not
function bm2ui.AddTab(frame, name, tabFrame, combatlockdown)
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

local function bm2LoadWindowPosition()
  -- Buffomat window position from the config
  local x, y = Bm2Addon.db.char.mainWindowX, Bm2Addon.db.char.mainWindowY
  local w, h = Bm2Addon.db.char.mainWindowWidth, Bm2Addon.db.char.mainWindowHeight

  BM2_MAIN_WINDOW:ClearAllPoints()
  BM2_MAIN_WINDOW:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
  BM2_MAIN_WINDOW:SetWidth(w)
  BM2_MAIN_WINDOW:SetHeight(h)
end

function bm2ui.SaveWindowPosition()
  Bm2Addon.db.char.mainWindowX = BM2_MAIN_WINDOW:GetLeft()
  Bm2Addon.db.char.mainWindowY = BM2_MAIN_WINDOW:GetTop()
  Bm2Addon.db.char.mainWindowWidth = BM2_MAIN_WINDOW:GetWidth()
  Bm2Addon.db.char.mainWindowHeight = BM2_MAIN_WINDOW:GetHeight()
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

  frameSizeBorder = CreateFrame("Frame", (frame:GetName() or TOCNAME .. bm2SizeCount) .. "_size_" .. name, frame)
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

function bm2ui.EnableSizing(frame, border, OnStart, OnStop)
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

---Set up the main window: dragging, sizing, load and save the position
function bm2ui.SetupMainWindow()
  BM2_MAIN_WINDOW_TITLE:SetText(_t('Buffomat') .. " - " .. _t('Solo'))
  bm2ui.EnableMoving(BM2_MAIN_WINDOW, bm2ui.SaveWindowPosition)

  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Tasks'), BM2_LIST_TAB, true)
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Spells'), BM2_SPELL_TAB, true)
  bm2ui.SelectTab(BM2_MAIN_WINDOW, 1)

  bm2LoadWindowPosition()

  BM2_MAIN_WINDOW:SetMinResize(180, 90)
  bm2ui.EnableSizing(BM2_MAIN_WINDOW, 8, nil, bm2ui.SaveWindowPosition)
end
