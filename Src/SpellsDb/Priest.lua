---@class Bm2SpellsDbPriestModule
local priest = Bm2Module.DeclareModule("SpellsDb/Priest")
---@type Bm2SpellsDbModule
local spellsDb = Bm2Module.DeclareModule("SpellsDb")
---@type Bm2ConstModule
local bm2const = Bm2Module.Import("Const")

local function fortitude()
  local singleRanks = {
    spellDef:New("fort1", 1243),
    spellDef:New("fort2", 1244),
    spellDef:New("fort3", 1245),
    spellDef:New("fort4", 2791),
    spellDef:New("fort5", 10937),
    spellDef:New("fort6", 10938),
    spellDef:New("fort7_tbc", 25389, true)
  }
  local holyCandle = itemDef:New("holy_candle", 17028)
  local sacredCandle = itemDef:New("sacred_candle", 17029)
  local prayerRanks = {
    spellDef:New("p_fort1", 21562):Reagent(holyCandle),
    spellDef:New("p_fort2", 21564):Reagent(sacredCandle),
    spellDef:New("p_fort3_tbc", 25392, true):Reagent(sacredCandle)
  }
  spellsDb:AddBuff("Fortitude"):DefaultEnabled()
          :SingleBuff(singleRanks):GroupBuff(prayerRanks)
          :Duration(bm2const.DURATION_30M, bm2const.DURATION_1H)
end

function priest:Spells()
  fortitude()
end
