---@class Bm2EventsModule
local bm2events = Bm2Module.DeclareModule("Events")
---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")

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
local function bm2event_UNIT_POWER_UPDATE(unitTarget, powerType)
  if powerType == "MANA" and UnitIsUnit(unitTarget, "player") and not InCombatLockdown() then
    local max_mana = BOM.PlayerManaMax or 0
    local actual_mana = UnitPower("player", 0) or 0

    if max_mana <= actual_mana then
      Bm2Addon:RequestForceUpdate("power change")
    end
  end
end

---Event_PLAYER_TARGET_CHANGED
---Handle player target change, spells possibly might have changed too.
local function bm2event_PLAYER_TARGET_CHANGED()
  if not InCombatLockdown() then
    if UnitInParty("target") or UnitInRaid("target") or UnitIsUnit("target", "player") then
      Bm2Addon.lastTarget = UnitFullName("target")
      Bm2Addon:UpdateSpellsTab("player target changed")

    elseif Bm2Addon.lastTarget then
      Bm2Addon.lastTarget = nil
      Bm2Addon:UpdateSpellsTab("player target cleared")
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
      Bm2Addon:RequestForceUpdate("unit died")

    elseif Bm2Addon.db.char.durationCache[spellName] then
      local bm2PlayerBuffs = Bm2Addon.playerBuffs

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

local function bm2event_UNIT_SPELLCAST_START(unit)
  if UnitIsUnit(unit, "player") and not Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = "cast"
    Bm2Addon:RequestForceUpdate("player is casting")
  end
end

local function bm2event_UNIT_SPELLCAST_STOP(unit)
  if UnitIsUnit(unit, "player") and Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = nil
    Bm2Addon:RequestForceUpdate("casting stop")
  end
end

local function bm2event_UNIT_SPELLCHANNEL_START(unit)
  if UnitIsUnit(unit, "player") and not Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = "channel"
    Bm2Addon:RequestForceUpdate("player is channeling")
  end
end

local function bm2event_UNIT_SPELLCHANNEL_STOP(unit)
  if UnitIsUnit(unit, "player") and Bm2Addon.playerIsCasting then
    Bm2Addon.playerIsCasting = nil
    Bm2Addon.RequestForceUpdate("channeling stop")
  end
end

local function bm2event_UNIT_SPELLCAST_errors(unit)
  if UnitIsUnit(unit, "player") then
    Bm2Addon:RequestForceUpdate("cast end")
    --Bm2Addon.playerIsCasting = nil
  end
end

function bm2events.RegisterEarlyEvents()
  --Bm2Addon:RegisterEvent("PLAYER_LOGIN", function()
  Bm2Addon:RegisterEvent("PLAYER_ENTERING_WORLD", function() Bm2Addon:OnInitializeStep2() end)
  Bm2Addon:RegisterEvent("LOADING_SCREEN_DISABLED", function() Bm2Addon:OnInitializeStep2() end)

  -- Events which might change active state of Buffomat
  Bm2Addon:RegisterEvent("ZONE_CHANGED", function()
    Bm2Addon:RequestForceUpdate("zone changed")
  end)
  Bm2Addon:RegisterEvent("PLAYER_UPDATE_RESTING", function()
    Bm2Addon:RequestForceUpdate("resting status changed")
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
end
