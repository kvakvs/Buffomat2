---Buff engine
---Stores the current buffs, skip lists, spell knowledge, etc.
---Contains code for buff applying, canceling and tracking
---@class Bm2EngineModule
---@field activeBuffs table<string, table<string, number>> Remaining durations on buffs. ActiveBuffs[targetName][buffId] => GetTime()
---@field forceUpdate string|nil Modified when something happens that we must recalculate the task list. Value is reason for recalculation
---@field loadingScreen boolean Set to true between loadingscreen start and stop
---@field loadingScreenTimeout number|nil
---@field declineHasResurrection boolean Set to true on combat start, stop, holding Alt, cleared on party update
local engineModule = Bm2Module.DeclareModule("Engine")
engineModule.activeBuffs = {}

local spellsDb = Bm2Module.Import("SpellsDb") ---@type Bm2SpellsDbModule
local profileModule = Bm2Module.Import("Profile") ---@type Bm2ProfileModule
local partyModule = Bm2Module.Import("Party") ---@type Bm2PartyModule
local _t = Bm2Module.Import("Translation")---@type Bm2TranslationModule

---@class Bm2Spell
---@field failedTargetsList table<string> Targets we failed buffing

function engineModule:UpdateSpellsTab(reason)
end

---Set forceUpdate flag, so that the UpdateScan would be called asap
---@param reason string|nil
function engineModule:SetForceUpdate(reason)
  engineModule.forceUpdate = reason
end

---Go through cancel buff preferences and cancel the buffs found on the player
function engineModule:CancelBuffs()
  for _index, buffId in ipairs(profileModule.active.cancelBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]

    if buff then
      buff:Cancel()
    end
  end
end

---@param playerMember Bm2Member
function engineModule:CancelBuffsOn(playerMember)
  for i, buffId in ipairs(profileModule.active.cancelBuffs) do
    local memberBuff = playerMember.buffs[buffId]

    if memberBuff then
      local buff = spellsDb.allPossibleBuffs[buffId]

      Bm2Addon:Print(string.format(_t("Cancel buff %s by %s"),
          buff.singleLink or buff.singleName,
          UnitName(memberBuff.source or "") or ""))

      buff:Cancel()
    end
  end
end

---Reset the list of failed target for each spell we have configured
function engineModule:ClearSkipList()
  for _spellIndex, spell in ipairs(profileModule.active.selectedBuffs) do
    if spell.failedTargetsList then
      wipe(spell.failedTargetsList)
    end
  end
end

--- Note: Canceling shapeshift forms is currently impossible in TBC
function engineModule:CancelBuff(cancelSpellids)
  local ret = false

  if not InCombatLockdown() and cancelSpellids then
    for i = 1, 40 do
      --name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId,
      local _, _, _, _, _, _, source, _, _, spellId = UnitBuff("player", i, "CANCELABLE")

      if spellId and tContains(cancelSpellids, spellId) then
        ret = true
        CancelUnitBuff("player", i)
        break
      end
    end
  end

  return ret
end

---If player just left the raid or party, reset the settings which groups to buff
function engineModule:MaybeResetWatchGroups()
  if UnitPlayerOrPetInParty("player") == false then
    -- We have left the party - can clear monitored groups
    local need_to_report = next(profileModule.active.doNotScanGroup) ~= nil

    -- TODO: Update checkboxes on watch groups
    -- TODO: Update buff tab text (buff G1-8)
    wipe(profileModule.active.doNotScanGroup)

    --BOM.UpdateBuffTabText()

    if need_to_report then
      Bm2Addon:Print(_t("Resetting watched raid groups to 1..8"))
    end
  end
end

---Clean up the buffs for players not in the current party
---@param party table<number, Bm2Member>
function engineModule:CleanBuffsForParty(party)
  function localCleanBuffsFor(name)
    -- search the party for name in it
    for i, member in ipairs(party) do
      if member.name == name then
        return -- all good, name is in this party
      end
    end

    engineModule.activeBuffs[name] = nil -- not in the party, forget it
  end

  for name, _buffsCollection in pairs(engineModule.activeBuffs) do
    localCleanBuffsFor(name)
  end
end

---@class Bm2UnitAura
---@field name string
---@field icon string
---@field count number
---@field debuffType string
---@field duration number
---@field expirationTime number
---@field source string
---@field isStealable boolean
---@field nameplateShowPersonal string
---@field spellId number
---@field canApplyAura boolean
---@field isBossDebuff boolean
---@field castByPlayer boolean
---@field nameplateShowAll boolean
---@field timeMod number

---Handles UnitAura WOW API call.
---For spells that are tracked by Buffomat the data is also stored in engine.activeBuffs
---@param unitId string
---@param buffIndex number Index of buff/debuff slot starts 1 max 40?
---@param filter string Filter string like "HELPFUL", "PLAYER", "RAID"... etc
---@return Bm2UnitAura
function engineModule:UnitAura(unitId, buffIndex, filter)
  local name, icon, count, debuffType, duration, expirationTime, source, isStealable
  , nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer
  , nameplateShowAll, timeMod = UnitAura(unitId, buffIndex, filter)
  local buff = spellsDb.buffReverseLookup[spellId]

  if buff then
    if source ~= nil and source ~= "" and UnitIsUnit(source, "player") then
      if UnitIsUnit(unitId, "player") and duration ~= nil and duration > 0 then
        Bm2Addon.db.char.durationCache[buff.buffId] = duration
      end

      if duration == nil or duration == 0 then
        duration = Bm2Addon.db.char.durationCache[buff.buffId] or 0
      end

      if duration > 0 and (expirationTime == nil or expirationTime == 0) then
        local destName = UnitFullName(unitId)
        local destBuffs = engineModule.activeBuffs[destName]

        if destBuffs and destBuffs[buff.buffId] then
          expirationTime = engineModule.activeBuffs[destName][buff.buffId] + duration

          if expirationTime <= GetTime() then
            engineModule.activeBuffs[destName][buff.buffId] = GetTime()
            expirationTime = GetTime() + duration
          end
        end
      end

      if expirationTime == 0 then
        duration = 0
      end
    end

  end

  return { name                  = name,
           icon                  = icon,
           count                 = count,
           debuffType            = debuffType,
           duration              = duration,
           expirationTime        = expirationTime,
           source                = source,
           isStealable           = isStealable,
           nameplateShowPersonal = nameplateShowPersonal,
           spellId               = spellId,
           canApplyAura          = canApplyAura,
           isBossDebuff          = isBossDebuff,
           castByPlayer          = castByPlayer,
           nameplateShowAll      = nameplateShowAll,
           timeMod               = timeMod }
end
