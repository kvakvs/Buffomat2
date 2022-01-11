---@class Bm2UiMainWindowModule
---@field windowHideBehaviour string Store user intent, "keepOpen", "keepClosed", "autoOpen", "autoClosed"
---@field spellTabsCreatedFlag boolean Set to true after spells have been scanned and added to the Spells tab
local uiMainWindow = Bm2Module.DeclareModule("UiMainWindow")
---@type Bm2EngineModule
local engine = Bm2Module.Import("Engine")
---@type Bm2TranslationModule
local _t = Bm2Module.Import("Translation")
---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")

local BM2INTENT_AUTO_CLOSED = "autoClosed"
local BM2INTENT_AUTO_OPEN = "autoOpen"
local BM2INTENT_KEEP_CLOSED = "keepClosed"
local BM2INTENT_KEEP_OPEN = "keepOpen"
uiMainWindow.windowHideBehaviour = BM2INTENT_AUTO_CLOSED

---@type Bm2UiModule
local bm2ui = Bm2Module.Import("Ui")

local function bm2SaveWindowPosition()
  Bm2Addon.db.char.mainWindowX = BM2_MAIN_WINDOW:GetLeft()
  Bm2Addon.db.char.mainWindowY = BM2_MAIN_WINDOW:GetTop()
  Bm2Addon.db.char.mainWindowWidth = BM2_MAIN_WINDOW:GetWidth()
  Bm2Addon.db.char.mainWindowHeight = BM2_MAIN_WINDOW:GetHeight()
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

---Set up the main window: dragging, sizing, load and save the position
function bm2ui.SetupMainWindow()
  BM2_MAIN_WINDOW_TITLE:SetText(_t('Buffomat') .. " - " .. _t('Solo'))
  bm2ui.EnableMoving(BM2_MAIN_WINDOW, bm2SaveWindowPosition)

  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Tasks'), BM2_TASKS_TAB, true)
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Spells'), BM2_SPELL_TAB, true)
  bm2ui.SelectTab(BM2_MAIN_WINDOW, 1)

  bm2LoadWindowPosition()

  BM2_MAIN_WINDOW:SetMinResize(180, 90)
  bm2ui.EnableSizing(BM2_MAIN_WINDOW, 8, nil, bm2SaveWindowPosition)

  -- Set up buttons in the tasks tab
  local messageFrame = BM2_TASKS_TAB_MESSAGE_FRAME
  messageFrame:SetFading(false);
  messageFrame:SetFontObject(GameFontNormalSmall);
  messageFrame:SetJustifyH("LEFT");
  messageFrame:SetHyperlinksEnabled(true);
  messageFrame:Clear()
  messageFrame:SetMaxLines(100)

  local castButton = BM2_TASKS_TAB_CAST_BUTTON
  castButton:SetAttribute("type", "macro")
  castButton:SetAttribute("macro", bm2const.MacroName)
end

---Close window and set close reason to "user clicked close button"
function uiMainWindow.HideWindow(reason)
  if BM2_MAIN_WINDOW:IsVisible() then
    BM2_MAIN_WINDOW:Hide()
    uiMainWindow.windowHideBehaviour = BM2INTENT_KEEP_CLOSED
    engine:ScanBuffs(reason)
  end
end

--- Show the addon window; Save user intent to keep the window open
function uiMainWindow.ShowWindow(tab)
  if not InCombatLockdown() then
    if not BM2_MAIN_WINDOW:IsVisible() then
      BM2_MAIN_WINDOW:Show()
      uiMainWindow.windowHideBehaviour = BM2INTENT_KEEP_OPEN
    else
      Bm2Addon.OnCloseClick()
    end
    bm2ui.SelectTab(BM2_MAIN_WINDOW, tab or 1)
  else
    Bm2Addon:Print(_t("Can\'t show window in combat"))
  end
end

function uiMainWindow.ToggleWindow()
  local reason = "toggle window"

  if BM2_MAIN_WINDOW:IsVisible() then
    uiMainWindow.HideWindow(reason)
  else
    engine:ScanBuffs(reason)
    uiMainWindow.ShowWindow()
  end
end

---Call this to suggest opening window, unless user closed it with a X button
function uiMainWindow.AutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if not BM2_MAIN_WINDOW:IsVisible() and uiMainWindow.windowHideBehaviour ~= "keepClosed" then
      uiMainWindow.windowHideBehaviour = BM2INTENT_AUTO_OPEN
      BM2_MAIN_WINDOW:Show()
      bm2ui.SelectTab(BM2_MAIN_WINDOW, 1)
    end
  end
end

---Call this to suggest closing the window, unless user opened it explicitly with a command or a key
function uiMainWindow.AutoClose()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if BM2_MAIN_WINDOW:IsVisible() then
      if uiMainWindow.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
        BM2_MAIN_WINDOW:Hide()
        uiMainWindow.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
      end
    elseif uiMainWindow.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
      uiMainWindow.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end

---If the window was force-closed, allow it to auto open again
---This is called from combat end
function uiMainWindow.AllowAutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if uiMainWindow.windowHideBehaviour == BM2INTENT_KEEP_CLOSED then
      uiMainWindow.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end
