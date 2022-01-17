---@class Bm2SpellsDbPriestModule
local priest = Bm2Module.DeclareModule("SpellsDb/Priest")

local spellsDb = Bm2Module.DeclareModule("SpellsDb") ---@type Bm2SpellsDbModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local spellDef = Bm2Module.Import("SpellDef") ---@type Bm2SpellDefModule
local itemDef = Bm2Module.Import("ItemDef") ---@type Bm2ItemDefModule
local buffDef = Bm2Module.Import("SpellsDb/BuffDef")---@type Bm2BuffDefModule

---@param holyCandle Bm2ItemDefinition
---@param sacredCandle Bm2ItemDefinition
local function fortitude(holyCandle, sacredCandle)
  local singleRanks = {
    spellDef:New("fort1", 1243),
    spellDef:New("fort2", 1244),
    spellDef:New("fort3", 1245),
    spellDef:New("fort4", 2791),
    spellDef:New("fort5", 10937),
    spellDef:New("fort6", 10938),
    spellDef:New("fort7_tbc", 25389, true)
  }
  local prayerRanks = {
    spellDef:New("p_fort1", 21562):Reagent(holyCandle),
    spellDef:New("p_fort2", 21564):Reagent(sacredCandle),
    spellDef:New("p_fort3_tbc", 25392, true):Reagent(sacredCandle)
  }
  spellsDb:AddBuff("buff_fortitude"):DefaultEnabled()
          :SingleBuff(singleRanks):GroupBuff(prayerRanks)
          :Duration(constModule.DURATION_30M, constModule.DURATION_1H)
end

---@param sacredCandle Bm2ItemDefinition
local function spirit(sacredCandle)
  local singleRanks = {
    spellDef:New("spirit1", 14752),
    spellDef:New("spirit2", 14818),
    spellDef:New("spirit3", 14819),
    spellDef:New("spirit4", 27841),
    spellDef:New("spirit5_tbc", 25312, true)
  }
  local prayerRanks = {
    spellDef:New("p_spirit1", 27681):Reagent(sacredCandle),
    spellDef:New("p_spirit2_tbc", 32999, true):Reagent(sacredCandle)
  }
  spellsDb:AddBuff("buff_spirit"):DefaultEnabled()
          :SingleBuff(singleRanks):GroupBuff(prayerRanks)
          :Duration(constModule.DURATION_30M, constModule.DURATION_1H)
          :TargetClasses(constModule.MANA_CLASSES)
end

---@param holyCandle Bm2ItemDefinition
---@param sacredCandle Bm2ItemDefinition
local function shadowProtection(holyCandle, sacredCandle)
  local singleRanks = {
    spellDef:New("shadow_prot1", 976),
    spellDef:New("shadow_prot2", 10957),
    spellDef:New("shadow_prot3", 10958),
    spellDef:New("shadow_prot4_tbc", 25433, true),
  }
  local prayerRanks = {
    spellDef:New("p_shadow1", 27683):Reagent(holyCandle),
    spellDef:New("p_shadow2_tbc", 39374, true):Reagent(sacredCandle),
  }
  spellsDb:AddBuff("buff_shadow_prot")
          :SingleBuff(singleRanks):GroupBuff(prayerRanks)
          :Duration(constModule.DURATION_10M, constModule.DURATION_20M)
end

local function shield()
  local singleRanks = {
    spellDef:New("pw_shield1", 17),
    spellDef:New("pw_shield2", 592),
    spellDef:New("pw_shield3", 600),
    spellDef:New("pw_shield4", 3747),
    spellDef:New("pw_shield5", 6065),
    spellDef:New("pw_shield6", 6066),
    spellDef:New("pw_shield7", 10898),
    spellDef:New("pw_shield8", 10899),
    spellDef:New("pw_shield9", 10900),
    spellDef:New("pw_shield10", 10901),
    spellDef:New("pw_shield11_tbc", 25217, true),
    spellDef:New("pw_shield12_tbc", 25218, true),
  }
  spellsDb:AddBuff("buff_shield")
          :SingleBuff(singleRanks):Duration(30):HasCooldown()
end

local function touchOfWeakness()
  local singleRanks = {
    spellDef:New("touch_of_weakness1", 2652),
    spellDef:New("touch_of_weakness2", 19261),
    spellDef:New("touch_of_weakness3", 19262),
    spellDef:New("touch_of_weakness4", 19264),
    spellDef:New("touch_of_weakness5", 19265),
    spellDef:New("touch_of_weakness6", 19266),
    spellDef:New("touch_of_weakness7_tbc", 25461, true),
  }
  spellsDb:AddBuff("buff_touch_of_weakness"):DefaultEnabled():SelfOnly()
          :SingleBuff(singleRanks)
end

local function innerFire()
  local singleRanks = {
    spellDef:New("inner_fire1", 588),
    spellDef:New("inner_fire2", 7128),
    spellDef:New("inner_fire3", 602),
    spellDef:New("inner_fire4", 1006),
    spellDef:New("inner_fire5", 10951),
    spellDef:New("inner_fire6", 10952),
    spellDef:New("inner_fire7_tbc", 25431, true),
  }
  spellsDb:AddBuff("buff_inner_fire"):DefaultEnabled():SelfOnly()
          :SingleBuff(singleRanks)
end

local function shadowguard()
  local singleRanks = {
    spellDef:New("shadowguard1", 18137),
    spellDef:New("shadowguard2", 19308),
    spellDef:New("shadowguard3", 19309),
    spellDef:New("shadowguard4", 19310),
    spellDef:New("shadowguard5", 19311),
    spellDef:New("shadowguard6", 19312),
    spellDef:New("shadowguard7_tbc", 25477, true),
  }
  spellsDb:AddBuff("buff_shadowguard"):DefaultEnabled():SelfOnly()
          :SingleBuff(singleRanks)
end

local function resurrection()
  local singleRanks = {
    spellDef:New("resurrection1", 2006),
    spellDef:New("resurrection2", 2010),
    spellDef:New("resurrection3", 10880),
    spellDef:New("resurrection4", 10881),
    spellDef:New("resurrection5", 20770),
    spellDef:New("resurrection6_tbc", 25435, true),
  }
  spellsDb:AddBuff("buff_resurrection"):DefaultEnabled()
    :Type(buffDef.BUFFTYPE_RESURRECTION):SingleBuff(singleRanks):CancelForm()
end

local function elunesGrace()
  local singleRanks = {}
  if (constModule.IsTBC) then
    singleRanks = { -- TBC: The only rank
      spellDef:New("elunes_grace_tbc", 2651, true),
    }
  else
    singleRanks = {
      spellDef:New("elunes_grace1", 2651),
      spellDef:New("elunes_grace2", 19289),
      spellDef:New("elunes_grace3", 19291),
      spellDef:New("elunes_grace4", 19292),
      spellDef:New("elunes_grace5", 19293),
    }
  end
  spellsDb:AddBuff("buff_elunesgrace"):DefaultEnabled():SelfOnly()
          :SingleBuff(singleRanks)
end

function priest:Spells()
  local holyCandle = itemDef:New("holy_candle", 17028)
  local sacredCandle = itemDef:New("sacred_candle", 17029)

  fortitude(holyCandle, sacredCandle)
  spirit(sacredCandle)
  shadowProtection(holyCandle, sacredCandle)

  spellsDb:AddBuff("buff_fear_ward")
          :SingleBuff(spellDef:New("fear_ward", 6346))
          :Duration(constModule.DURATION_10M):HasCooldown()

  shield()
  touchOfWeakness()
  innerFire()
  shadowguard()
  elunesGrace()

  spellsDb:AddBuff("buff_shadowform"):SelfOnly()
          :SingleBuff(spellDef:New("shadowform", 15473))

  resurrection()
end
