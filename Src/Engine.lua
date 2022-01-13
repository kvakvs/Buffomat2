---Buff engine
---Stores the current buffs, skip lists, spell knowledge, etc.
---Contains code for buff applying, canceling and tracking
---@class Bm2EngineModule
---@field activeBuffs table<string, table<number, number>> Remaining durations on buffs on target, indexed by buffId, then by targetname, value is time
---@field selectedSpells table<string, Bm2BuffDefinition> Buff names selected by the user
---@field forceUpdate string|nil Modified when something happens that we must recalculate the task list. Value is reason for recalculation
---@field loadingScreen boolean Set to true between loadingscreen start and stop
---@field loadingScreenTimeout number|nil
---@field partyUpdateNeeded boolean Set to true on party change event to rescan the party
local engine = Bm2Module.DeclareModule("Engine")
engine.activeBuffs = {}
engine.selectedSpells = {}

---@type Bm2SpellsDbModule
local spellsDb = Bm2Module.Import("SpellsDb")
---@type Bm2ProfileModule
local profile = Bm2Module.Import("Profile")
---@type Bm2TranslationModule
local _t = Bm2Module.Import("Translation")

---@class Bm2Spell
---@field failedTargetsList table<string> Targets we failed buffing

function engine:UpdateSpellsTab(reason)
end

---Set forceUpdate flag, so that the UpdateScan would be called asap
---@param reason string|nil
function engine:SetForceUpdate(reason)
  engine.forceUpdate = reason
end

---Go through cancel buff preferences and cancel the buffs found on the player
function engine:CancelBuffs()
  for _index, buffId in ipairs(profile.active.cancelBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]

    if buff then
      buff:Cancel()
    end
  end
end

---Reset the list of failed target for each spell we have configured
function engine:ClearSkipList()
  for _spellIndex, spell in ipairs(engine.selectedSpells) do
    if spell.failedTargetsList then
      wipe(spell.failedTargetsList)
    end
  end
end

--- Note: Canceling shapeshift forms is currently impossible in TBC
function engine:CancelBuff(cancelSpellids)
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
function engine:MaybeResetWatchGroups()
  if UnitPlayerOrPetInParty("player") == false then
    -- We have left the party - can clear monitored groups
    local need_to_report = next(Bm2Addon.db.char.doNotScanGroup) ~= nil

    -- TODO: Update checkboxes on watch groups
    -- TODO: Update buff tab text (buff G1-8)
    wipe(Bm2Addon.db.char.doNotScanGroup)

    --BOM.UpdateBuffTabText()

    if need_to_report then
      Bm2Addon:Print(_t("Resetting watched raid groups to 1..8"))
    end
  end
end
