---@class Bm2UiModule
local bm2ui = Bm2Module.DeclareModule("Ui")

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

function bm2ui.SaveWindowPosition()
  Bm2Addon.db.char.mainWindowX = BM2_MAIN_WINDOW:GetLeft()
  Bm2Addon.db.char.mainWindowY = BM2_MAIN_WINDOW:GetTop()
  Bm2Addon.db.char.mainWindowWidth = BM2_MAIN_WINDOW:GetWidth()
  Bm2Addon.db.char.mainWindowHeight = BM2_MAIN_WINDOW:GetHeight()
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
