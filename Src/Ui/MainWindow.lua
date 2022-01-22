---@class Bm2UiMainWindowModule
---@field windowHideBehaviour string Store user intent, "keepOpen", "keepClosed", "autoOpen", "autoClosed"
---@field spellTabsCreatedFlag boolean Set to true after spells have been scanned and added to the Spells tab
local mainWindowModule = Bm2Module.DeclareModule("Ui/MainWindow")

local _t = Bm2Module.Import("Translation") ---@type Bm2TranslationModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local taskListModule = Bm2Module.Import("TaskList") ---@type Bm2TaskListModule
local profileModule = Bm2Module.Import("Profile") ---@type Bm2ProfileModule
local spellsDb = Bm2Module.Import("SpellsDb") ---@type Bm2SpellsDbModule
local rowbuilderModule = Bm2Module.Import("Ui/RowBuilder") ---@type Bm2UiRowBuilderModule
local uiModule = Bm2Module.Import("Ui") ---@type Bm2UiModule

local BM2INTENT_AUTO_CLOSED = "autoClosed"
local BM2INTENT_AUTO_OPEN = "autoOpen"
local BM2INTENT_KEEP_CLOSED = "keepClosed"
local BM2INTENT_KEEP_OPEN = "keepOpen"
mainWindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED

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
function uiModule:SetupMainWindow()
  BM2_MAIN_WINDOW_TITLE:SetText(_t('Buffomat') .. " - " .. _t('Solo'))
  uiModule.EnableMoving(BM2_MAIN_WINDOW, bm2SaveWindowPosition)

  -- TODO: Class icon for class spells; Bottle icon for consumes; Weapons icon for weapons tab
  uiModule.AddTab(BM2_MAIN_WINDOW, _t('Task'), BM2_TASKS_TAB, true) -- task list
  uiModule.AddTab(BM2_MAIN_WINDOW, _t('S'), BM2_SPELL_TAB, true) -- spells
  uiModule.AddTab(BM2_MAIN_WINDOW, _t('C'), BM2_SPELL_TAB, true) -- consumes
  uiModule.AddTab(BM2_MAIN_WINDOW, _t('Set'), BM2_SPELL_TAB, true) -- settings
  uiModule.SelectTab(BM2_MAIN_WINDOW, 1)

  bm2LoadWindowPosition()

  BM2_MAIN_WINDOW:SetMinResize(180, 90)
  uiModule.EnableSizing(BM2_MAIN_WINDOW, 8, nil, bm2SaveWindowPosition)

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
  castButton:SetAttribute("macro", constModule.MacroName)
end

---Close window and set close reason to "user clicked close button"
function mainWindowModule:HideWindow(reason)
  if not InCombatLockdown() and BM2_MAIN_WINDOW:IsVisible() then
    BM2_MAIN_WINDOW:Hide()
    mainWindowModule.windowHideBehaviour = BM2INTENT_KEEP_CLOSED
    taskListModule:Scan(reason)
  else
    Bm2Addon:Print(_t("Can't hide window in combat"))
  end
end

--- Show the addon window; Save user intent to keep the window open
function mainWindowModule:ShowWindow(tab)
  if not InCombatLockdown() then
    if not BM2_MAIN_WINDOW:IsVisible() then
      BM2_MAIN_WINDOW:Show()
      mainWindowModule.windowHideBehaviour = BM2INTENT_KEEP_OPEN
    else
      Bm2Addon.OnCloseClick()
    end
    uiModule.SelectTab(BM2_MAIN_WINDOW, tab or 1)
  else
    Bm2Addon:Print(_t("Can't show window in combat"))
  end
end

function mainWindowModule.ToggleWindow()
  local reason = "toggle window"

  if BM2_MAIN_WINDOW:IsVisible() then
    mainWindowModule:HideWindow(reason)
  else
    taskListModule:Scan(reason)
    mainWindowModule:ShowWindow()
  end
end

---Call this to suggest opening window, unless user closed it with a X button
function mainWindowModule.AutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if not BM2_MAIN_WINDOW:IsVisible() and mainWindowModule.windowHideBehaviour ~= "keepClosed" then
      mainWindowModule.windowHideBehaviour = BM2INTENT_AUTO_OPEN
      BM2_MAIN_WINDOW:Show()
      uiModule.SelectTab(BM2_MAIN_WINDOW, 1)
    end
  end
end

---Call this to suggest closing the window, unless user opened it explicitly with a command or a key
function mainWindowModule.AutoClose()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if BM2_MAIN_WINDOW:IsVisible() then
      if mainWindowModule.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
        BM2_MAIN_WINDOW:Hide()
        mainWindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
      end
    elseif mainWindowModule.windowHideBehaviour ~= BM2INTENT_KEEP_OPEN then
      mainWindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end

---If the window was force-closed, allow it to auto open again
---This is called from combat end
function mainWindowModule.AllowAutoOpen()
  if not InCombatLockdown() and Bm2Addon.db.char.autoOpen then
    if mainWindowModule.windowHideBehaviour == BM2INTENT_KEEP_CLOSED then
      mainWindowModule.windowHideBehaviour = BM2INTENT_AUTO_CLOSED
    end
  end
end

---@param t string Display text on cast button
---@param enable boolean Enable or disable the button
function mainWindowModule:CastButton(t, enable)
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

---Filter all known spells through current player spellbook
local function bm2CreateSpellsTab()
  local rowBuilder = rowbuilderModule:New(BM2_SPELL_TAB)
  for buffIndex, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    if buff and buff:IsCastedBuff() then
      rowBuilder:CreateTabRow(buff)
    end
  end
end

local function bm2CreateConsumesTab()
  local rowBuilder = rowbuilderModule:New(BM2_CONSUMES_TAB)
  for buffIndex, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    if buff and buff:IsConsumableBuff() then
      rowBuilder:CreateConsumableTabRow(buff)
    end
  end
end

---Add spell cancel buttons for all spells in CancelBuffs
---(and CustomCancelBuffs which user can add manually in the config file)
local function bm2CreateSettingsTab()
  local rowBuilder = rowbuilderModule:New(BM2_SETTINGS_TAB)
  for i, buff in ipairs(spellsDb.allCancelBuffs) do
    rowBuilder:CreateCancelTabRow(buff)
  end

  -- TODO: Group watch checkbox row
  --if row_builder.prev_control then
  --  bomFillBottomSection(row_builder)
  --end
end

-- ---@param buff Bm2BuffDefinition
--local function bm2UpdateSelectedBuff(buff)
--  -- the pointer to spell in current BOM profile
--  local profile_spell = BOM.CurrentProfile.Spell[spell.ConfigID]
--
--  spell.frames.Enable:SetVariable(profile_spell, "Enable")
--
--  if spell:HasClasses() then
--    spell.frames.SelfCast:SetVariable(profile_spell, "SelfCast")
--
--    for ci, class in ipairs(BOM.Tool.Classes) do
--      spell.frames[class]:SetVariable(profile_spell.Class, class)
--
--      if profile_spell.SelfCast then
--        spell.frames[class]:Disable()
--      else
--        spell.frames[class]:Enable()
--      end
--    end -- for all class names
--
--    spell.frames["tank"]:SetVariable(profile_spell.Class, "tank")
--    spell.frames["pet"]:SetVariable(profile_spell.Class, "pet")
--
--    if profile_spell.SelfCast then
--      spell.frames["tank"]:Disable()
--      spell.frames["pet"]:Disable()
--    else
--      spell.frames["tank"]:Enable()
--      spell.frames["pet"]:Enable()
--    end
--
--    --========================================
--    local force_cast_button = spell.frames.ForceCastButton ---@type Control
--    local exclude_button = spell.frames.ExcludeButton ---@type Control
--
--    if BOM.lastTarget ~= nil then
--      -------------------------
--      force_cast_button:Enable()
--      bomUpdateForcecastTooltip(force_cast_button, profile_spell)
--
--      local spell_force = profile_spell.ForcedTarget
--      local last_target = BOM.lastTarget
--
--      force_cast_button:SetScript("OnClick", function(self)
--        if spell_force[last_target] == nil then
--          BOM.Print(BOM.FormatTexture(BOM.ICON_TARGET_ON) .. " "
--              .. L.MessageAddedForced .. ": " .. last_target)
--          spell_force[last_target] = last_target
--        else
--          BOM.Print(BOM.FormatTexture(BOM.ICON_TARGET_ON) .. " "
--              .. L.MessageClearedForced .. ": " .. last_target)
--          spell_force[last_target] = nil
--        end
--        bomUpdateForcecastTooltip(self, profile_spell)
--      end)
--      -------------------------
--      exclude_button:Enable()
--      bomUpdateExcludeTargetsTooltip(exclude_button, profile_spell)
--
--      local spell_exclude = profile_spell.ExcludedTarget
--      last_target = BOM.lastTarget
--
--      exclude_button:SetScript("OnClick", function(self)
--        if spell_exclude[last_target] == nil then
--          BOM.Print(BOM.FormatTexture(BOM.ICON_TARGET_EXCLUDE) .. " "
--              .. L.MessageAddedExcluded .. ": " .. last_target)
--          spell_exclude[last_target] = last_target
--        else
--          BOM.Print(BOM.FormatTexture(BOM.ICON_TARGET_EXCLUDE) .. " "
--              .. L.MessageClearedExcluded .. ": " .. last_target)
--          spell_exclude[last_target] = nil
--        end
--        bomUpdateExcludeTargetsTooltip(self, profile_spell)
--      end)
--
--    else
--      --======================================
--      force_cast_button:Disable()
--      BOM.Tool.TooltipText(
--          force_cast_button,
--          L.TooltipForceCastOnTarget .. "|n" .. L.TooltipSelectTarget
--              .. bomForceTargetsTooltipText(profile_spell))
--      --force_cast_button:SetVariable()
--      ---------------------------------
--      exclude_button:Disable()
--      BOM.Tool.TooltipText(
--          exclude_button,
--          L.TooltipExcludeTarget .. "|n" .. L.TooltipSelectTarget
--              .. bomExcludeTargetsTooltip(profile_spell))
--      --exclude_button:SetVariable()
--    end
--  end -- end if has classes
--
--  if spell.isInfo and spell.allowWhisper then
--    spell.frames.Whisper:SetVariable(profile_spell, "Whisper")
--  end
--
--  if spell.type == "weapon" then
--    spell.frames.MainHand:SetVariable(profile_spell, "MainHandEnable")
--    spell.frames.OffHand:SetVariable(profile_spell, "OffHandEnable")
--  end
--
--  if (spell.type == "tracking"
--      or spell.type == "aura"
--      or spell.type == "seal") and spell.needForm == nil
--  then
--    if (spell.type == "tracking" and BOM.CharacterState.LastTracking == spell.trackingIconId) or
--        (spell.type == "aura" and spell.ConfigID == BOM.CurrentProfile.LastAura) or
--        (spell.type == "seal" and spell.ConfigID == BOM.CurrentProfile.LastSeal) then
--      spell.frames.Set:SetState(true)
--    else
--      spell.frames.Set:SetState(false)
--    end
--  end
--end

---UpdateSpellTabs - create rows in the spell tabs (if were not created), update
---checkboxes on the spell rows matching the current selected profile.
function mainWindowModule:UpdateSpellTabs()
  if InCombatLockdown() then
    return
  end

  uiModule:HideAllManagedFrames()

  bm2CreateSpellsTab()
  bm2CreateConsumesTab()
  bm2CreateSettingsTab()

  -- TODO: Create small toggle button to the right of [Cast <spell>] button
  -- BOM.CreateSingleBuffButton(BomC_ListTab) --maybe not created yet?
end
