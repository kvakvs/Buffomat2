---@class Bm2SpellsDbDruidModule
local druid = Bm2Module.DeclareModule("SpellsDb/Druid")

local spellsDb = Bm2Module.DeclareModule("SpellsDb") ---@type Bm2SpellsDbModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local spellDef = Bm2Module.Import("SpellDef") ---@type Bm2SpellDefModule
local itemDef = Bm2Module.Import("ItemDef") ---@type Bm2ItemDefModule
local buffDef = Bm2Module.Import("SpellsDb/BuffDef") ---@type Bm2BuffDefModule
local _t = Bm2Module.Import("Translation")---@type Bm2TranslationModule

local function ofTheWild(wildBerries, wildThornroot)
  local singleRanks = {
    spellDef:New("motw1", 1126),
    spellDef:New("motw2", 5232),
    spellDef:New("motw3", 6756),
    spellDef:New("motw4", 5234),
    spellDef:New("motw5", 8907),
    spellDef:New("motw6", 9884),
    spellDef:New("motw7", 9885),
    spellDef:New("motw8_tbc", 26990, true),
  }
  local groupRanks = {
    spellDef:New("gotw1", 21849):Reagent(wildBerries),
    spellDef:New("gotw2", 21850):Reagent(wildThornroot),
    spellDef:New("gotw3_tbc", 26991, true):Reagent(wildThornroot)
  }
  spellsDb:AddBuff("buff_pinkpaw"):DefaultEnabled()
          :SingleBuff(singleRanks):GroupBuff(groupRanks)
          :Duration(constModule.DURATION_30M, constModule.DURATION_1H)
end

local function thorns()
  local singleRanks = {
    spellDef:New("thorns1", 467),
    spellDef:New("thorns2", 782),
    spellDef:New("thorns3", 1075),
    spellDef:New("thorns4", 8914),
    spellDef:New("thorns5", 9756),
    spellDef:New("thorns6", 9910),
    spellDef:New("thorns7_tbc", 26992, true),
  }
  spellsDb:AddBuff("buff_thorns")
          :SingleBuff(singleRanks):Duration(constModule.DURATION_10M)
          :TargetClasses(constModule.MELEE_CLASSES)
end

local function naturesGrasp()
  local singleRanks = {
    spellDef:New("natures_grasp1", 16689),
    spellDef:New("natures_grasp2", 16810),
    spellDef:New("natures_grasp3", 16811),
    spellDef:New("natures_grasp4", 16812),
    spellDef:New("natures_grasp5", 16813),
    spellDef:New("natures_grasp6", 17329),
    spellDef:New("natures_grasp7_tbc", 27009, true),
  }
  spellsDb:AddBuff("buff_naturesgrasp"):SelfOnly()
          :SingleBuff(singleRanks):Duration(45)
end

function druid:Spells()
  local wildBerries = itemDef:New("wild_berries", 17021)
  local wildThornroot = itemDef:New("wild_thornroot", 17026)

  ofTheWild(wildBerries, wildThornroot)
  thorns()

  spellsDb:AddBuff("buff_omenofclarity")
          :SelfOnly():CancelForm():DefaultEnabled()
          :SingleBuff(spellDef:New("omen_of_clarity", 25431))
          :Duration(constModule.DURATION_30M) -- TBC 30min, classic 10?

  naturesGrasp()

  spellsDb:AddBuff("buff_treeoflife"):SelfOnly():ShapeshiftFormId(2)
          :SingleBuff(spellDef:New("tree_of_life", 33891, true))
          :Sort(buffDef.SEQ_LATE)

  -- Special code: This will disable herbalism and mining tracking in Cat Form
  spellsDb:AddBuff("buff_trackhumanoids"):SelfOnly():DefaultEnabled()
          :Type(buffDef.BUFFTYPE_TRACKING)
          :SingleBuff(spellDef:New("track_humanoids", 5225))
          :Hint(_t('Cat only - Overrides track herbs and ore'))
          :RequiresShapeshiftFormId(CAT_FORM)
end
