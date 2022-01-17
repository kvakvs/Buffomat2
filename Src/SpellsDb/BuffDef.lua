---@class Bm2BuffDefModule
local buffDefModule = Bm2Module.DeclareModule("SpellsDb/BuffDef") ---@type Bm2BuffDefModule

local engine = Bm2Module.Import("Engine")---@type Bm2EngineModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule

---@class Bm2BuffDefinition
---@field buffId string
---@field hint string Short explanation text used as tooltip?
---@field defaultOn boolean Set to true to have it enabled by default for new users
---@field singleBuff table<number, Bm2SpellDefinition> Table of spelldefs for single buff, lowest rank first
---@field groupBuff table<number, Bm2SpellDefinition> Table of spelldefs for group buff, lowest rank first
---@field singleDuration number|nil Seconds for single buff or nil (for permanent auras)
---@field groupDuration number|nil Seconds for group buff or nil (if not applicable)
---@field hasCooldown boolean True to only attempt to buff once, as it might go on cooldown after the first cast
---@field cancelForm boolean True to leave shapeshift form/shadow form
---@field targetClasses table<number, string>|string|nil list of (classes|"tank") to only buff a class, or a tank role, nil to buff everyone, "player" for self only
---@field buffType string Special handling for certain types - Enum buffDefModule.BUFFTYPE_*
---@field shapeshiftFormId number|nil Allows to check whether user is already in that shapeshift
---@field requiresShapeshiftFormId number|nil Requires player to be in this form
---@field sort number|nil Suggests when the buff should be prioritized, 0=asap, 100=anytime, or as 1000=late as possible
---@field singleLink string Printable link to the single buff spell
---@field singleName string Text name of the single buff spell
---@field whisperExpired boolean Set to true to track who casted the buff and inform them when expired
---@field disableIfHaveItem nil|table<number, Bm2ItemDefinition> The buff is not casted, if the player has one of these items
---@field alwaysBuffTargets table<number, string>|nil Targets to always include into the buff checks
---@field neverBuffTargets table<number, string>|nil Targets to always exclude from the buff checks
---@field calculatedTargets table<number, Bm2Member> Runtime field: Calculated targets in the party who need this buff
---@field calculatedGroup table<number, number> Runtime field: Calculated groups for group buff
---@field calculatedDeathGroup table<number, number> Runtime field: Group numbers where a dead member has been found
---@field source string Unit who casted this buff, for info-type buffs
--TODO: copy SpellSetup.lua/SetupSpell
local buffDefClass = {} ---@type Bm2BuffDefinition
buffDefClass.__index = buffDefClass

buffDefModule.BUFFTYPE_SPELL = "spell" -- simple cast
buffDefModule.BUFFTYPE_BLESSING = "blessing" -- simple cast, but special target rules for paladin blessings (1 greater per class)
buffDefModule.BUFFTYPE_AURA = "aura" -- activate a buff zone around you
buffDefModule.BUFFTYPE_SEAL = "seal" -- short duration weapon augment, showing as a buff, e.g. paladin
buffDefModule.BUFFTYPE_WEAPON_ENCHANTMENT_SPELL = "weaponSpell" -- temporary weapon augment, from a spell, e.g. shaman
buffDefModule.BUFFTYPE_ITEM_TARGET_ITEM = "itemTargetItem" -- consumable augment to use on item, e.g. poison, oils, sharpening
buffDefModule.BUFFTYPE_RESURRECTION = "resurrection" -- someone is dead
buffDefModule.BUFFTYPE_ITEM_USE = "itemUse" -- right click an item
buffDefModule.BUFFTYPE_ITEM_TARGET_UNIT = "itemTargetUnit" -- target someone then right click
buffDefModule.BUFFTYPE_TRACKING = "tracking" -- enable via tracking API

buffDefModule.SEQ_EARLY = 0
buffDefModule.SEQ_NORMAL = 100
buffDefModule.SEQ_LATE = 1000

---Returns true if this buff is a class ability, spell or tracking buff
---@return boolean
function buffDefClass:IsCastedBuff()
  return self.buffType == buffDefModule.BUFFTYPE_AURA
      or self.buffType == buffDefModule.BUFFTYPE_SEAL
      or self.buffType == buffDefModule.BUFFTYPE_SPELL
      or self.buffType == buffDefModule.BUFFTYPE_BLESSING
      or self.buffType == buffDefModule.BUFFTYPE_TRACKING
      or self.buffType == buffDefModule.BUFFTYPE_RESURRECTION
      or self.buffType == buffDefModule.BUFFTYPE_WEAPON_ENCHANTMENT_SPELL
end

---Returns true if this buff is a consumable item, or elixir
---@return boolean
function buffDefClass:IsConsumableBuff()
  return self.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_UNIT
      or self.buffType == buffDefModule.BUFFTYPE_ITEM_USE
      or self.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_ITEM
end

---@return Bm2BuffDefinition
function buffDefModule:New(buffId)
  local fields = {} ---@type Bm2BuffDefinition
  setmetatable(fields, buffDefClass)

  fields.buffId = buffId
  fields.defaultOn = false
  fields.singleBuff = {}
  fields.groupBuff = {}
  fields.sort = buffDefModule.SEQ_NORMAL
  fields.buffType = buffDefModule.BUFFTYPE_SPELL
  fields.calculatedTargets = { }

  -- TODO: singleLink from GetSpellInfo
  -- TODO: singleName from GetSpellInfo
  fields.singleName = buffId

  return fields
end

---For new Buffomat users this will be enabled by default
---@return Bm2BuffDefinition
function buffDefClass:DefaultEnabled()
  self.defaultEnabled = true
  return self
end

---Special buff types for special handling
---@param buffType string Enum buffDefModule.BUFFTYPE_*
---@return Bm2BuffDefinition
function buffDefClass:Type(buffType)
  self.buffType = buffType
  return self
end

---Buff requires player to leave shapeshift/shadowform to cast
---@return Bm2BuffDefinition
function buffDefClass:CancelForm()
  self.cancelForm = true
  return self
end

---Buff only targets player themself
---@return Bm2BuffDefinition
function buffDefClass:SelfOnly()
  self.targetClasses = "player"
  return self
end

---Check whether buff is self-cast
---@return boolean
function buffDefClass:IsSelfCast()
  return self.targetClasses == "player"
end

---Buff only targets player themself
---@return Bm2BuffDefinition
function buffDefClass:ShapeshiftFormId(id)
  self.shapeshiftFormId = id
  return self
end

---Ranks for single target buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function buffDefClass:SingleBuff(ranks)
  if type(ranks) == "Bm2SpellDefinition" then
    ranks = { ranks }
  end
  self.singleBuff = ranks
  return self
end

---Ranks for group buff, add reagent cost in each spelldef
---@param ranks table<Bm2SpellDefinition>|Bm2SpellDefinition
---@return Bm2BuffDefinition
function buffDefClass:GroupBuff(ranks)
  if type(ranks) == "Bm2SpellDefinition" then
    ranks = { ranks }
  end
  self.groupBuff = ranks
  return self
end

---Attempt to buff once, then it goes on cd
---@return Bm2BuffDefinition
function buffDefClass:HasCooldown()
  self.hasCooldown = true
  return self
end

---@param single number
---@param group number|nil
---@return Bm2BuffDefinition
function buffDefClass:Duration(single, group)
  self.singleDuration = single
  self.groupDuration = group
  return self
end

---Filter classes who can receive the buff
---@param classes table<string>
---@return Bm2BuffDefinition
function buffDefClass:TargetClasses(classes)
  self.targetClasses = classes
  return self
end

---Add a short help text
---@param hint string
---@return Bm2BuffDefinition
function buffDefClass:Hint(hint)
  self.hint = hint
  return self
end

---Requires player to be in this shapeshift form
---@param formId number
---@return Bm2BuffDefinition
function buffDefClass:RequiresShapeshiftFormId(formId)
  self.requiresShapeshiftFormId = formId
  return self
end

---Sorting key, small numbers first, big numbers late
---@param p number
---@return Bm2BuffDefinition
function buffDefClass:Sort(p)
  self.sort = p
  return self
end

---Check whether the spell/buff is available to the player
---@return boolean
function buffDefClass:IsAvailable()
  -- Item buffs are always available, who knows when the user will have the item
  if self.buffType == buffDefModule.BUFFTYPE_ITEM_USE
      or self.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_UNIT then
    return true
  end

  -- if any of single buff spells are available...
  for _index, spell in ipairs(self.singleBuff) do
    if spell:IsAvailable() then
      return true
    end
  end
  -- if any of group buff spells are available...
  for _index, spell in ipairs(self.groupBuff) do
    if spell:IsAvailable() then
      return true
    end
  end

  return false
end

---Cancels all possible auras of this buff on player
function buffDefClass:Cancel()
  local spellIds = {}

  for _index, spell in ipairs(self.singleBuff) do
    tinsert(spellIds, spell.spellId)
  end
  for _index, spell in ipairs(self.groupBuff) do
    tinsert(spellIds, spell.spellId)
  end

  engine:CancelBuff(spellIds)
end

-- ---From end of self.singleBuff select highest available rank of single buff spell
-- ---@return Bm2SpellDefinition
--function buffDefClass:GetHighestSingleBuffSpell()
--  for i = 1, #self.singleBuff do
--    local index = #self.singleBuff + 1 - i -- reverse iter
--    local spell = self.singleBuff[index]
--
--    if spell:IsAvailable() then
--      return spell
--    end
--  end
--
--  return nil
--end

---Checks whether a tracking spell is now active
---@param buff Bm2BuffDefinition The tracking spell which might have tracking enabled
function buffDefClass:IsTrackingActive()
  if self.buffType ~= buffDefModule.BUFFTYPE_TRACKING then
    return false
  end

  if constModule.IsTBC then
    for i = 1, GetNumTrackingTypes() do
      local _name, _texture, active, _category, _nesting, spellId = GetTrackingInfo(i)
      -- assume: singleId has only one spelldef
      local _i, spellSingle = next(self.singleBuff) ---@type Bm2SpellDefinition

      if spellId == spellSingle.spellId and active then
        return true
      end
    end
  else
    -- assume: singleId has only one spelldef
    local _i, spellSingle = next(self.singleBuff) ---@type Bm2SpellDefinition
    return GetTrackingTexture() == spellSingle.spellTexture
  end

  return false -- not found
end

---@return boolean Whether class `cls` can be targeted by this buff. Also takes
---a role, for example "tank".
function buffDefClass:CanTarget(cls)
  if self.targetClasses == nil then
    return true
  end
  if type(self.targetClasses) == "table" then
    return tContains(self.targetClasses, cls)
  end
  return false
end