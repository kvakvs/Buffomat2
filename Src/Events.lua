---@class Bm2EventsModule
local bm2events = Bm2Module.DeclareModule("Events")
---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")
---@type Bm2UiMainWindowModule
local uiMainWindow = Bm2Module.Import("UiMainWindow")
---@type Bm2EngineModule
local engine = Bm2Module.Import("Engine")
---@type Bm2BagModule
local bm2bag = Bm2Module.Import("Bag")

local EVT_COMBAT_STOP = { "PLAYER_REGEN_ENABLED" }
local EVT_COMBAT_START = { "PLAYER_REGEN_DISABLED" }
local EVT_LOADING_SCREEN_START = { "LOADING_SCREEN_ENABLED", "PLAYER_LEAVING_WORLD" }
local EVT_LOADING_SCREEN_END = { "PLAYER_ENTERING_WORLD", "LOADING_SCREEN_DISABLED" }
local EVT_UPDATE = {
  "UPDATE_SHAPESHIFT_FORM", "UNIT_AURA", "READY_CHECK",
  "PLAYER_ALIVE", "PLAYER_UNGHOST", "INCOMING_RESURRECT_CHANGED",
  "UNIT_INVENTORY_CHANGED" }

local EVT_BAG_CHANGED = { "BAG_UPDATE_DELAYED", "TRADE_CLOSED" }

local EVT_PARTY_CHANGED = { "GROUP_JOINED", "GROUP_ROSTER_UPDATE",
                            "RAID_ROSTER_UPDATE", "GROUP_LEFT" }

local EVT_SPELLBOOK_CHANGED = { "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB" }

---Event_TAXIMAP_OPENED
---Ignores options: autoLeaveShapeshift, autoDismountGround, autoDismountFlying
---Will dismount player if mounted when opening taxi tab. Will stand and cancel
---shapeshift to be able to talk to the taxi NPC.
local function bm2event_TAXIMAP_OPENED()
  if IsMounted() then
    Dismount()
  else
    DoEmote("STAND")
    BOM.CancelShapeShift()
  end
end

---Unit power changed (only for mana events)
---UNIT_POWER_UPDATE: "unitTarget", "powerType"
local function bm2event_UNIT_POWER_UPDATE(_eventName, unitTarget, powerType)
  if powerType == "MANA" and UnitIsUnit(unitTarget, "player") and not InCombatLockdown() then
    local max_mana = UnitPowerMax("player", bm2const.POWER_MANA) or 0
    local actual_mana = UnitPower("player", bm2const.POWER_MANA) or 0

    if max_mana <= actual_mana then
      engine:SetForceUpdate("power change")
    end
  end
end

---Event_PLAYER_TARGET_CHANGED
---Handle player target change, spells possibly might have changed too.
local function bm2event_PLAYER_TARGET_CHANGED()
  if not InCombatLockdown() then
    if UnitInParty("target") or UnitInRaid("target") or UnitIsUnit("target", "player") then
      Bm2Addon.lastTarget = UnitFullName("target")
      engine:UpdateSpellsTab("player target changed")

    elseif Bm2Addon.lastTarget then
      Bm2Addon.lastTarget = nil
      engine:UpdateSpellsTab("player target cleared")
    end
  else
    Bm2Addon.lastTarget = nil
  end

  if not Bm2Addon.db.char.buffCurrentTarget then
    return
  end
end

local bm2PartyCheckMask = COMBATLOG_OBJECT_AFFILIATION_RAID + COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_MINE

local function bm2event_COMBAT_LOG_EVENT_UNFILTERED()
  local _timestamp, event, _hideCaster, _sourceGUID, _sourceName, sourceFlags, _sourceRaidFlags
  , _destGUID, destName, destFlags, _destRaidFlags, _spellId, spellName, _spellSchool, _auraType
  , _amount = CombatLogGetCurrentEventInfo()

  if bit.band(destFlags, bm2PartyCheckMask) > 0 and destName ~= nil and destName ~= "" then
    if event == "UNIT_DIED" then
      engine:SetForceUpdate("unit died")

    elseif Bm2Addon.db.char.durationCache[spellName] then
      local bm2PlayerBuffs = engine.playerBuffs

      if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
        if event == "SPELL_CAST_SUCCESS" then

        elseif event == "SPELL_AURA_REFRESH" then
          bm2PlayerBuffs[destName] = bm2PlayerBuffs[destName] or {}
          bm2PlayerBuffs[destName][spellName] = GetTime()

        elseif event == "SPELL_AURA_APPLIED" then
          bm2PlayerBuffs[destName] = bm2PlayerBuffs[destName] or {}
          if bm2PlayerBuffs[destName][spellName] == nil then
            bm2PlayerBuffs[destName][spellName] = GetTime()
          end

        elseif event == "SPELL_AURA_REMOVED" then
          if bm2PlayerBuffs[destName] and bm2PlayerBuffs[destName][spellName] then
            bm2PlayerBuffs[destName][spellName] = nil
          end
        end

      elseif event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED" and event == "SPELL_AURA_REMOVED" then
        if bm2PlayerBuffs[destName] and bm2PlayerBuffs[destName][spellName] then
          bm2PlayerBuffs[destName][spellName] = nil
        end
      end
    end

  end
end

---Event_UI_ERROR_MESSAGE
---Will stand if sitting, will dismount if mounted, will cancel shapeshift, if
---shapeshifted while trying to cast a spell and that produces an error message.
---@param errorType table
---@param message table
local function bm2event_UI_ERROR_MESSAGE(_errorType, message)
  if tContains(bm2const.ErrorsWhenNotStanding, message) and Bm2Addon.db.char.autoStand then
    UIErrorsFrame:Clear()
    DoEmote("STAND")

  elseif tContains(bm2const.ErrorsWhenMounted, message) then
    local flying = false -- prevent dismount in flight, OUCH!
    if bm2const.IsTBC then
      flying = IsFlying() and not Bm2Addon.db.char.autoDismountFlying
    end
    if not flying then
      if BOM.db.char.autoDismount then
        UIErrorsFrame:Clear()
        Dismount()
      end
    end

  elseif Bm2Addon.db.char.autoLeaveShapeshift
      and tContains(bm2const.ErrorsWhenShapeshifted, message)
      and bm2CancelBuff(bm2const.ShapeShiftTravel) then
    UIErrorsFrame:Clear()

  --elseif not InCombatLockdown() then
  --  if Bm2Addon.checkForError then
  --    if message == SPELL_FAILED_LOWLEVEL then
  --      bomDownGrade()
  --    else
  --      BOM.AddMemberToSkipList()
  --    end
  --  end
  end

  --BOM.CheckForError = false
end

local function bm2event_UNIT_SPELLCAST_START(_eventName, unit)
  if UnitIsUnit(unit, "player") and not Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = "cast"
    engine:SetForceUpdate("player is casting")
  end
end

local function bm2event_UNIT_SPELLCAST_STOP(_eventName, unit)
  if UnitIsUnit(unit, "player") and Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = nil
    engine:SetForceUpdate("casting stop")
  end
end

local function bm2event_UNIT_SPELLCHANNEL_START(_eventName, unit)
  if UnitIsUnit(unit, "player") and not Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = "channel"
    engine:SetForceUpdate("player is channeling")
  end
end

local function bm2event_UNIT_SPELLCHANNEL_STOP(_eventName, unit)
  if UnitIsUnit(unit, "player") and Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = nil
    engine:SetForceUpdate("channeling stop")
  end
end

local function bm2event_UNIT_SPELLCAST_errors(_eventName, unit)
  if UnitIsUnit(unit, "player") then
    engine:SetForceUpdate("cast end")
    --Bm2Addon.playerIsCasting = nil
  end
end

---On combat start will close the UI window and disable the UI. Will cancel the cancelable buffs.
local function bm2event_CombatStart()
  engine:SetForceUpdate("combat start")
  uiMainWindow.AutoClose()

  if not InCombatLockdown() then
    BM2_MAIN_WINDOW_CAST_BUTTON:Disable()
  end

  engine:CancelBuffs()
end

local function bm2event_CombatStop()
  engine:ClearSkipList()
  engine:SetForceUpdate("combat stop")
  uiMainWindow.AllowAutoOpen()
end

local function bm2event_LoadingStart()
  engine.loadingScreen = true
  engine.loadingScreenTimeout = nil
  bm2event_CombatStart()
end

local function bm2event_LoadingStop()
  engine.loadingScreenTimeOut = GetTime() + bm2const.LOADING_SCREEN_TIMEOUT
  engine:SetForceUpdate("loading screen end")
end

local function bm2event_SpellsChanged()
  engine:SetupAvailableSpells()
  engine:SetForceUpdate("spells changed")
  uiMainWindow.spellTabsCreatedFlag = false
  -- engine:OptionsInsertSpells() -- update options page with all known spells?
end

local bm2SavedInParty = IsInRaid() or IsInGroup()

local function bm2event_PartyChanged()
  engine.partyUpdateNeeded = true
  engine:SetForceUpdate("party changed")

  -- if in_party changed from true to false, clear the watch groups
  local in_party = IsInRaid() or IsInGroup()
  if bm2SavedInParty ~= in_party then
    if not in_party then
      BOM.MaybeResetWatchGroups()
    end
    bm2SavedInParty = in_party
  end
end

local function bm2event_GenericUpdate(eventType)
  engine:SetForceUpdate(eventType)
end

local function bm2event_Bag()
  engine:SetForceUpdate()
  bm2bag:Invalidate()
end

function bm2events.RegisterEarlyEvents()
  --Bm2Addon:RegisterEvent("PLAYER_LOGIN", function()
  Bm2Addon:RegisterEvent("PLAYER_ENTERING_WORLD", function() Bm2Addon:OnInitializeStep2() end)
  Bm2Addon:RegisterEvent("LOADING_SCREEN_DISABLED", function() Bm2Addon:OnInitializeStep2() end)
end

function bm2events.RegisterLateEvents()
  -- Events which might change active state of Buffomat
  Bm2Addon:RegisterEvent("ZONE_CHANGED", function()
    engine:SetForceUpdate("zone changed")
  end)
  Bm2Addon:RegisterEvent("PLAYER_UPDATE_RESTING", function()
    engine:SetForceUpdate("resting status changed")
  end)

  --- Events possibly leading to a Buffomat action (dismount, target change, mana
  --- change, cannot cast while shapeshifted, cannot use taxi while mounted etc)
  Bm2Addon:RegisterEvent("TAXIMAP_OPENED", bm2event_TAXIMAP_OPENED)
  --Bm2Addon:RegisterEvent("ADDON_LOADED", Event_ADDON_LOADED) -- doing initialization via Ace3 handlers
  Bm2Addon:RegisterEvent("UNIT_POWER_UPDATE", bm2event_UNIT_POWER_UPDATE)
  Bm2Addon:RegisterEvent("PLAYER_STARTED_MOVING", function()
    Bm2Addon.playerIsMoving = true
  end)
  Bm2Addon:RegisterEvent("PLAYER_STOPPED_MOVING", function()
    Bm2Addon.playerIsMoving = false
  end)
  Bm2Addon:RegisterEvent("PLAYER_TARGET_CHANGED", bm2event_PLAYER_TARGET_CHANGED)
  Bm2Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", bm2event_COMBAT_LOG_EVENT_UNFILTERED)
  Bm2Addon:RegisterEvent("UI_ERROR_MESSAGE", bm2event_UI_ERROR_MESSAGE)

  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_START", bm2event_UNIT_SPELLCAST_START)
  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_STOP", bm2event_UNIT_SPELLCAST_STOP)
  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", bm2event_UNIT_SPELLCHANNEL_START)
  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", bm2event_UNIT_SPELLCHANNEL_STOP)

  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", bm2event_UNIT_SPELLCAST_errors)
  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", bm2event_UNIT_SPELLCAST_errors)
  Bm2Addon:RegisterEvent("UNIT_SPELLCAST_FAILED", bm2event_UNIT_SPELLCAST_errors)

  for i, event in ipairs(EVT_COMBAT_START) do
    Bm2Addon:RegisterEvent(event, bm2event_CombatStart)
  end
  for i, event in ipairs(EVT_COMBAT_STOP) do
    Bm2Addon:RegisterEvent(event, bm2event_CombatStop)
  end
  for i, event in ipairs(EVT_LOADING_SCREEN_START) do
    Bm2Addon:RegisterEvent(event, bm2event_LoadingStart)
  end
  for i, event in ipairs(EVT_LOADING_SCREEN_END) do
    Bm2Addon:RegisterEvent(event, bm2event_LoadingStop)
  end

  for i, event in ipairs(EVT_SPELLBOOK_CHANGED) do
    Bm2Addon:RegisterEvent(event, bm2event_SpellsChanged)
  end
  for i, event in ipairs(EVT_PARTY_CHANGED) do
    Bm2Addon:RegisterEvent(event, bm2event_PartyChanged)
  end
  for i, event in ipairs(EVT_UPDATE) do
    Bm2Addon:RegisterEvent(event, bm2event_GenericUpdate)
  end
  for i, event in ipairs(EVT_BAG_CHANGED) do
    Bm2Addon:RegisterEvent(event, bm2event_Bag)
  end
end
