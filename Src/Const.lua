---@class Bm2ConstModule
local constModule = Bm2Module.DeclareModule("Const")

-- Unit power type for MANA https://wowwiki-archive.fandom.com/wiki/PowerType
-- https://wowwiki-archive.fandom.com/wiki/API_UnitPowerMax
constModule.POWER_MANA = 0

constModule.LegacyMacroName = "Buff'o'mat"
constModule.AddonName = "Buffomat2"
constModule.MacroName = "Buffomat2"
constModule.MacroIcon = "Ability_Druid_ChallangingRoar"
constModule.MacroIconDisabled = "Ability_Druid_DemoralizingRoar"
constModule.MacroIconFullpath = "Interface\\ICONS\\Ability_Druid_ChallangingRoar"

constModule.IconFormat = "|T%s:0:0:0:0:64:64:4:60:4:60|t"
constModule.PictureFormat = "|T%s:0|t"

--- Error messages which will make player stand if sitting
constModule.ErrorsWhenNotStanding = {
  ERR_CANTATTACK_NOTSTANDING, SPELL_FAILED_NOT_STANDING,
  ERR_LOOT_NOTSTANDING, ERR_TAXINOTSTANDING }

--- Error messages which will make player dismount if mounted.
constModule.ErrorsWhenMounted = {
  ERR_NOT_WHILE_MOUNTED, ERR_ATTACK_MOUNTED,
  ERR_TAXIPLAYERALREADYMOUNTED, SPELL_FAILED_NOT_MOUNTED }

--- Addon is running on Classic TBC client
---@type boolean
constModule.IsTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

--- Addon is running on Classic "Vanilla" client: Means Classic Era and its seasons like SoM
---@type boolean
constModule.IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

--- Error messages which will make player cancel shapeshift.
constModule.ErrorsWhenShapeshifted = {
  ERR_EMBLEMERROR_NOTABARDGEOSET, ERR_CANT_INTERACT_SHAPESHIFTED,
  ERR_MOUNT_SHAPESHIFTED, ERR_NO_ITEMS_WHILE_SHAPESHIFTED,
  ERR_NOT_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED,
  SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED,
  SPELL_FAILED_NOT_SHAPESHIFT, SPELL_NOT_SHAPESHIFTED,
  SPELL_NOT_SHAPESHIFTED_NOSPACE }

-- Time to wait after loading screen to begin scanning the buffs
constModule.LOADING_SCREEN_TIMEOUT = 2

constModule.DURATION_1H = 3600
constModule.DURATION_30M = 1800
constModule.DURATION_20M = 1200
constModule.DURATION_15M = 900
constModule.DURATION_10M = 600
constModule.DURATION_5M = 300

-----------------------
-- Class collections
-----------------------
constModule.ALL_CLASSES = { "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "PRIEST", "WARLOCK",
                            "SHAMAN", "PALADIN" }
constModule.RESURRECT_CLASSES = { "SHAMAN", "PRIEST", "PALADIN" }
constModule.MANA_CLASSES = { "HUNTER", "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN" }
constModule.MELEE_CLASSES = { "WARRIOR", "ROGUE", "DRUID", "SHAMAN", "PALADIN" }
constModule.SHADOW_CLASSES = { "PRIEST", "WARLOCK" }
constModule.FIRE_CLASSES = { "MAGE", "WARLOCK", "SHAMAN", "HUNTER" }
constModule.FROST_CLASSES = { "MAGE", "SHAMAN" }
constModule.PHYSICAL_CLASSES = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR", "DRUID", "PALADIN" }

-----------------------------------
-- Player info (does not change)
-----------------------------------
local _, playerClass_, _ = UnitClass("player")
constModule.PlayerClass = playerClass_
constModule.PlayerFaction = UnitFactionGroup("player")

local playerName_, playerRealm_ = UnitName("player")
constModule.PlayerName = playerName_
constModule.PlayerRealm = playerRealm_

-----------------------
-- Spell Ids database
-----------------------
constModule.spellId = {
  PALADIN_CRUSADERAURA = 32223,
}
constModule.shapeshiftForm = {
  PALADIN_CRUSADERAURA = 7,
}
--- Note: Canceling shapeshift forms is currently impossible in TBC
constModule.ShapeShiftTravel = {
  2645, -- ghost wolf
  783, -- travelform
  768, -- catform
  5487, -- junior bear form
  9634, -- dire bear form
}
