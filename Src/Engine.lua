---Buff engine
---Stores the current buffs, skip lists, spell knowledge, etc.

---@class Bm2EngineModule
---@field playerBuffs table<string, table> Remaining durations on buffs on the player
---@field selectedSpells table<string> Buff names selected by the user
---@field forceUpdate string|nil Modified when something happens that we must recalculate the task list. Value is reason for recalculation
---@field loadingScreen boolean Set to true between loadingscreen start and stop
---@field loadingScreenTimeout number|nil
---@field partyUpdateNeeded boolean Set to true on party change event to rescan the party
local engine = Bm2Module.DeclareModule("Engine")
engine.playerBuffs = {}
engine.selectedSpells = {}

---@class Bm2Spell
---@field failedTargetsList table<string> Targets we failed buffing

function engine:UpdateSpellsTab(reason)
end

---Set forceUpdate flag, so that the UpdateScan would be called asap
---@param reason string|nil
function engine:SetForceUpdate(reason)
  engine.forceUpdate = reason
end

---Request buffs scan and refresh the task list
---@param reason string|nil
function engine:ScanBuffs(reason)
  engine.forceUpdate = nil
end

---Go through cancel buff preferences and cancel the buffs found on the player
function engine:CancelBuffs()
  Bm2Addon:Print("Cancel buffs")
end

---Reset the list of failed target for each spell we have configured
function engine:ClearSkipList()
  for _spellIndex, spell in ipairs(engine.selectedSpells) do
    if spell.failedTargetsList then
      wipe(spell.failedTargetsList)
    end
  end
end

---From spells known to Buffomat and spells known to the player, build a list of
---spells which we actually have available.
function engine:SetupAvailableSpells()
  Bm2Addon:Print("Setup avail spells")
end