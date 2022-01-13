---Code to set up all known spells
---@class Bm2SpellsDbModule
---@field allPossibleBuffs table<string, Bm2BuffDefinition> All buff definitions, with string keys
---@field availableBuffs table<string, Bm2BuffDefinition> Buff definitions which the player knows
---@field cancelBuffs table<number, Bm2BuffDefinition> Buff definitions to show in cancel buff list
---@field enchantIds table<number, string> Weapon enchantment id to buff id reverse lookup
---@field availableSpellIds table<number, number> Ids of spells available to the player, for combat log filtering
---@field buffReverseLookup table<number, Bm2BuffDefinition> Reverse lookup of buff by spellid
local spellsDbModule = Bm2Module.DeclareModule("SpellsDb")

local buffDef = Bm2Module.DeclareModule("BuffDef") ---@type Bm2BuffDefModule
local priestModule = Bm2Module.Import("SpellsDb/Priest") ---@type Bm2SpellsDbPriestModule
local druidModule = Bm2Module.Import("SpellsDb/Druid") ---@type Bm2SpellsDbDruidModule
local constModule = Bm2Module.Import("Const")---@type Bm2ConstModule

spellsDbModule.allPossibleBuffs = {}
spellsDbModule.availableBuffs = {}
spellsDbModule.enchantIds = {}
spellsDbModule.cancelBuffs = {}
spellsDbModule.availableSpellIds = {} -- for combat log filtering
spellsDbModule.buffReverseLookup = {} -- for finding buff defs by spellid

---@param buffId string Unique string key to the buff
---@return Bm2BuffDefinition
function spellsDbModule:AddBuff(buffId)
  local newBuff = buffDef:New(buffId) ---@type Bm2BuffDefinition
  if spellsDbModule.allPossibleBuffs[buffId] then
    Bm2Addon:Print("Duplicate buffid=" .. buffId .. " please fix")
  end
  spellsDbModule.allPossibleBuffs[buffId] = newBuff
  return newBuff
end

local function bm2MageSpells()
end

local function bm2ShamanSpells()
end

local function bm2WarlockSpells()
end

local function bm2HunterSpells()
end

local function bm2PaladinSpells()
end

local function bm2WarriorSpells()
end

local function bm2RogueSpells()
end

local function bm2TrackingSpells()
end

local function bm2Flasks()
end

local function bm2BattleElixirs()
end

local function bm2GuardianElixirs()
end

local function bm2Consumables()
end

local function bm2ItemSpells()
end

local function bm2Food()
end

local function bm2InitCancelBuffs()
  local priestSpirit = spellsDbModule.allPossibleBuffs["buff_spirit"]
  local priestShield = spellsDbModule.allPossibleBuffs["buff_shield"]
  local mageIntellect = spellsDbModule.allPossibleBuffs["buff_arcane_intel"]

  spellsDbModule.cancelBuffs = {
    priestShield,
    priestSpirit,
    mageIntellect,
  }

  if constModule.PlayerClass == "HUNTER" then
    local singleRanks = {
      spellDef:New("aspect_of_the_cheetah", 5118),
      spellDef:New("aspect_of_the_pack", 13159),
    }
    local buffHunterRunSpeed = buffDef:New("cancelbuff_hunter_run")
                                      :SelfOnly():SingleBuff(singleRanks)
    tinsert(spellsDbModule.cancelBuffs, buffHunterRunSpeed)
  end

  if constModule.PlayerFaction ~= "Horde" or constModule.IsTBC then
    tinsert(spellsDbModule.cancelBuffs, spellsDbModule.allPossibleBuffs["buff_salvation"])
  end
end

---Build a table of spells known to Buffomat, for all classes
function spellsDbModule:InitSpellsDb()
  wipe(spellsDbModule.allPossibleBuffs)
  wipe(spellsDbModule.enchantIds)

  -- TODO: Call class spell init functions only if player class matches
  priestModule:Spells()
  druidModule:Spells()
  bm2MageSpells()
  bm2ShamanSpells()
  bm2WarlockSpells()
  bm2HunterSpells()
  bm2PaladinSpells()
  bm2WarriorSpells()
  bm2RogueSpells()
  bm2TrackingSpells()
  bm2Flasks()
  bm2BattleElixirs()
  bm2GuardianElixirs()
  bm2Consumables()
  bm2ItemSpells()
  bm2Food()

  ----Preload items!
  --for x, spell in ipairs(spells) do
  --  if spell.isConsumable then
  --    BOM.GetItemInfo(spell.item)
  --  end
  --end
  --
  --BOM.EnchantToSpell = {}
  --for dest, list in pairs(enchants) do
  --  for i, id in ipairs(list) do
  --    BOM.EnchantToSpell[id] = dest
  --  end
  --end
  --
  --BOM.AllBuffomatSpells = spells
  --BOM.EnchantList = enchants

  bm2InitCancelBuffs()
end

---From spells known to Buffomat and spells known to the player, build a list of
---spells which we actually have available to the player. This list might change
---for example due to level up, visiting a trainer, etc.
function spellsDbModule:FilterAvailableSpells()
  wipe(spellsDbModule.availableBuffs)
  wipe(spellsDbModule.availableSpellIds)
  wipe(spellsDbModule.buffReverseLookup)

  for _index, buff in pairs(spellsDbModule.allPossibleBuffs) do
    if buff:IsAvailable() then
      spellsDbModule.availableBuffs[buff.buffId] = buff

      for _, spell in ipairs(buff.singleBuff) do
        if spell:IsAvailable() then
          spellsDbModule.availableSpellIds[spell.id] = true
          spellsDbModule.buffReverseLookup[spell.id] = buff
        end
      end -- for single buffs

      for _, spell in ipairs(buff.groupBuff) do
        if spell:IsAvailable() then
          spellsDbModule.availableSpellIds[spell.id] = true
          spellsDbModule.buffReverseLookup[spell.id] = buff
        end
      end -- for group buffs
    end -- if available
  end
end
