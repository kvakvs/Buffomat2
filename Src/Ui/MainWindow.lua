---@class Bm2UiMainWindowModule
---@field windowHideBehaviour string Store user intent, "keepOpen", "keepClosed", "autoOpen", "autoClosed"
---@field spellTabsCreatedFlag boolean Set to true after spells have been scanned and added to the Spells tab
local mainwindowModule = Bm2Module.DeclareModule("UiMainWindow")
---@type Bm2EngineModule
local engine = Bm2Module.Import("Engine")
---@type Bm2TranslationModule
local _t = Bm2Module.Import("Translation")
---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")
---@type Bm2TaskListModule
local taskList = Bm2Module.Import("TaskList")
---@type Bm2ProfileModule
local profile = Bm2Module.Import("Profile")
---@type Bm2SpellsDbModule
local spellsDb = Bm2Module.Import("SpellsDb")

local BM2INTENT_AUTO_CLOSED = "autoClosed"
local BM2INTENT_AUTO_OPEN = "autoOpen"
local BM2INTENT_KEEP_CLOSED = "keepClosed"
local BM2INTENT_KEEP_OPEN = "keepOpen"
mainwindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED

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
function bm2ui:SetupMainWindow()
  BM2_MAIN_WINDOW_TITLE:SetText(_t('Buffomat') .. " - " .. _t('Solo'))
  bm2ui.EnableMoving(BM2_MAIN_WINDOW, bm2SaveWindowPosition)

  -- TODO: Class icon for class spells; Bottle icon for consumes; Weapons icon for weapons tab
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Task'), BM2_TASKS_TAB, true) -- task list
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('S'), BM2_SPELL_TAB, true) -- spells
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('C'), BM2_SPELL_TAB, true) -- consumes
  bm2ui.AddTab(BM2_MAIN_WINDOW, _t('Set'), BM2_SPELL_TAB, true) -- settings
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
function mainwindowModule:HideWindow(reason)
  if BM2_MAIN_WINDOW:IsVisible() then
    BM2_MAIN_WINDOW:Hide()
    mainwindowModule.windowHideBehaviour = BM2INTENT_KEEP_CLOSED
    taskList:Scan(reason)
  end
end

--- Show the addon window; Save user intent to keep the window open
function mainwindowModule:ShowWindow(tab)
  if not InCombatLockdown() then
    if not BM2_MAIN_WINDOW:IsVisible() then
      BM2_MAIN_WINDOW:Show()
      mainwindowModule.windowHideBehaviour = BM2INTENT_KEEP_OPEN
    else
      Bm2Addon.OnCloseClick()
    end
    bm2ui.SelectTab(BM2_MAIN_WINDOW, tab or 1)
  else
    Bm2Addon:Print(_t("Can't show window in combat"))
  end
end

function mainwindowModule.ToggleWindow()
  local reason = "toggle window"

  if BM2_MAIN_WINDOW:IsVisible() then
    mainwindowModule:HideWindow(reason)
  else
    taskList:Scan(reason)
    mainwindowModule:ShowWindow()
  end
end

---Call this to suggest opening window, unless user closed it with a X button
function mainwindowModule.AutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if not BM2_MAIN_WINDOW:IsVisible() and mainwindowModule.windowHideBehaviour ~= "keepClosed" then
      mainwindowModule.windowHideBehaviour = BM2INTENT_AUTO_OPEN
      BM2_MAIN_WINDOW:Show()
      bm2ui.SelectTab(BM2_MAIN_WINDOW, 1)
    end
  end
end

---Call this to suggest closing the window, unless user opened it explicitly with a command or a key
function mainwindowModule.AutoClose()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if BM2_MAIN_WINDOW:IsVisible() then
      if mainwindowModule.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
        BM2_MAIN_WINDOW:Hide()
        mainwindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
      end
    elseif mainwindowModule.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
      mainwindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end

---If the window was force-closed, allow it to auto open again
---This is called from combat end
function mainwindowModule.AllowAutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if mainwindowModule.windowHideBehaviour == BM2INTENT_KEEP_CLOSED then
      mainwindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end

---@param t string Display text on cast button
---@param enable boolean Enable or disable the button
function mainwindowModule:CastButton(t, enable)
  -- not really a necessary check but for safety
  if InCombatLockdown()
      or BM2_TASKS_TAB_CAST_BUTTON == nil
      or BM2_TASKS_TAB_CAST_BUTTON.SetText == nil then
    return
  end

  BM2_TASKS_TAB_CAST_BUTTON:SetText(t)

  if enable then
    BM2_TASKS_TAB_CAST_BUTTON:Enable()
  else
    BM2_TASKS_TAB_CAST_BUTTON:Disable()
  end
end

---@param buff Bm2BuffDefinition
local function bm2CreateTabRow(buff)
  Bm2Addon:Print("create tab row for " .. buff.buffId)
end

---Filter all known spells through current player spellbook
local function bm2CreateSpellsTab()
  for buffIndex, buffId in ipairs(profile.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    if buff and buff:IsClassBuff() then
      bm2CreateTabRow(buff)
    end
  end
end

local function bm2CreateConsumesTab()
  for buffIndex, buffId in ipairs(profile.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    if buff and buff:IsConsumableBuff() then
      bm2CreateTabRow(buff)
    end
  end
end

---Add spell cancel buttons for all spells in CancelBuffs
---(and CustomCancelBuffs which user can add manually in the config file)
local function bm2CreateSettingsTab()
  for i, spell in ipairs(BOM.CancelBuffs) do
    row_builder.dx = 2

    bomAddSpellCancelRow(spell, row_builder)

    row_builder.dy = 2
  end

  if row_builder.prev_control then
    bomFillBottomSection(row_builder)
  end
end

---UpdateSpellTabs - update spells in the spell tabs
function mainwindowModule:UpdateSpellTabs()
  if InCombatLockdown() then
    return
  end

  if not mainwindowModule.spellTabsCreatedFlag then
    bm2ui:HideAllManagedFrames()

    bm2CreateSpellsTab()
    bm2CreateConsumesTab()
    bm2CreateSettingsTab()

    mainwindowModule.spellTabsCreatedFlag = true
  end

  local _className, self_class_name, _classId = UnitClass("player")

  for i, spell in ipairs(BOM.SelectedSpells) do
    if type(spell.onlyUsableFor) == "table"
        and not tContains(spell.onlyUsableFor, self_class_name) then
      -- skip
    else
      bomUpdateSelectedSpell(spell)
    end
  end

  for _i, spell in ipairs(BOM.CancelBuffs) do
    spell.frames.Enable:SetVariable(BOM.CurrentProfile.CancelBuff[spell.ConfigID], "Enable")
  end

  --Create small toggle button to the right of [Cast <spell>] button
  BOM.CreateSingleBuffButton(BomC_ListTab) --maybe not created yet?
end
