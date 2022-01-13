---@class Bm2ConstModule
local bm2const = Bm2Module.DeclareModule("Const")

-- Unit power type for MANA https://wowwiki-archive.fandom.com/wiki/PowerType
-- https://wowwiki-archive.fandom.com/wiki/API_UnitPowerMax
bm2const.POWER_MANA = 0

bm2const.LegacyMacroName = "Buff'o'mat"
bm2const.AddonName = "Buffomat2"
bm2const.MacroName = "Buffomat2"
bm2const.MacroIcon = "Ability_Druid_ChallangingRoar"
bm2const.MacroIconDisabled = "Ability_Druid_DemoralizingRoar"
bm2const.MacroIconFullpath = "Interface\\ICONS\\Ability_Druid_ChallangingRoar"

bm2const.IconFormat = "|T%s:0:0:0:0:64:64:4:60:4:60|t"
bm2const.PictureFormat = "|T%s:0|t"

--- Error messages which will make player stand if sitting
bm2const.ErrorsWhenNotStanding = {
  ERR_CANTATTACK_NOTSTANDING, SPELL_FAILED_NOT_STANDING,
  ERR_LOOT_NOTSTANDING, ERR_TAXINOTSTANDING }

--- Error messages which will make player dismount if mounted.
bm2const.ErrorsWhenMounted = {
  ERR_NOT_WHILE_MOUNTED, ERR_ATTACK_MOUNTED,
  ERR_TAXIPLAYERALREADYMOUNTED, SPELL_FAILED_NOT_MOUNTED }

--- Addon is running on Classic TBC client
---@type boolean
bm2const.IsTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

--- Addon is running on Classic "Vanilla" client: Means Classic Era and its seasons like SoM
---@type boolean
bm2const.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

--- Error messages which will make player cancel shapeshift.
bm2const.ErrorsWhenShapeshifted = {
  ERR_EMBLEMERROR_NOTABARDGEOSET, ERR_CANT_INTERACT_SHAPESHIFTED,
  ERR_MOUNT_SHAPESHIFTED, ERR_NO_ITEMS_WHILE_SHAPESHIFTED,
  ERR_NOT_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED,
  SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED,
  SPELL_FAILED_NOT_SHAPESHIFT, SPELL_NOT_SHAPESHIFTED,
  SPELL_NOT_SHAPESHIFTED_NOSPACE }

-- Time to wait after loading screen to begin scanning the buffs
bm2const.LOADING_SCREEN_TIMEOUT = 2

bm2const.DURATION_1H = 3600
bm2const.DURATION_30M = 1800
bm2const.DURATION_20M = 1200
bm2const.DURATION_15M = 900
bm2const.DURATION_10M = 600
bm2const.DURATION_5M = 300

-----------------------
-- Class collections
-----------------------
bm2const.ALL_CLASSES = { "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "PRIEST", "WARLOCK",
                             "SHAMAN", "PALADIN" }
bm2const.RESURRECT_CLASSES = { "SHAMAN", "PRIEST", "PALADIN" }
bm2const.MANA_CLASSES = { "HUNTER", "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN" }
bm2const.MELEE_CLASSES = { "WARRIOR", "ROGUE", "DRUID", "SHAMAN", "PALADIN" }
bm2const.SHADOW_CLASSES = { "PRIEST", "WARLOCK" }
bm2const.FIRE_CLASSES = { "MAGE", "WARLOCK", "SHAMAN", "HUNTER" }
bm2const.FROST_CLASSES = { "MAGE", "SHAMAN" }
bm2const.PHYSICAL_CLASSES = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR", "DRUID", "PALADIN" }

-----------------------------------
-- Player info (does not change)
-----------------------------------
local _, playerClass_, _ = UnitClass("player")
bm2const.PlayerClass = playerClass_
bm2const.PlayerFaction = UnitFactionGroup("player")

local playerName_, playerRealm_ = UnitName("player")
bm2const.PlayerName = playerName_
bm2const.PlayerRealm = playerRealm_

-----------------------
-- Spell Ids database
-----------------------
bm2const.spellId = {
  PALADIN_CRUSADERAURA = 32223,
}
bm2const.shapeshiftForm = {
  PALADIN_CRUSADERAURA = 7,
}
--- Note: Canceling shapeshift forms is currently impossible in TBC
bm2const.ShapeShiftTravel = {
  2645, -- ghost wolf
  783, -- travelform
  768, -- catform
  5487, -- junior bear form
  9634, -- dire bear form
}
