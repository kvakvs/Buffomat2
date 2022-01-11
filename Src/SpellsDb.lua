---Code to set up all known spells

---@class Bm2SpellsDbModule
---@field allPossibleBuffs table<string, Bm2BuffDefinition> All buff definitions, with string keys
---@field enchantIds table<number, string> Weapon enchantment id to buff id reverse lookup
local spellsDb = Bm2Module.DeclareModule("SpellsDb")
---@type Bm2BuffDefModule
local buffDef = Bm2Module.DeclareModule("BuffDef")
---@type Bm2SpellDefModule
local spellDef = Bm2Module.Import("SpellDef")
---@type Bm2ItemDefModule
local itemDef = Bm2Module.Import("ItemDef")
---@type Bm2SpellsDbPriestModule
local priest = Bm2Module.Import("SpellsDb/Priest")

spellsDb.allPossibleBuffs = {}
spellsDb.enchantIds = {} ---@type table<number, table<number>>

---@param buffId string Unique string key to the buff
---@return Bm2BuffDefinition
function spellsDb:AddBuff(buffId)
  local newBuff = buffDef:New(buffId) ---@type Bm2BuffDefinition
  spellsDb.allPossibleBuffs[buffId] = newBuff
  return newBuff
end

local function bm2DruidSpells()
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

---From spells known to Buffomat and spells known to the player, build a list of
---spells which we actually have available.
function spellsDb:SetupAvailableSpells()
  wipe(spellsDb.allPossibleBuffs)
  wipe(spellsDb.enchantIds)

  priest:Spells()
  bm2DruidSpells()
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
end
