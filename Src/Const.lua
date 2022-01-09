---@class Bm2ConstModule
local bm2const = Bm2Module.DeclareModule("Const")

-- Unit power type for MANA https://wowwiki-archive.fandom.com/wiki/PowerType
-- https://wowwiki-archive.fandom.com/wiki/API_UnitPowerMax
bm2const.POWER_MANA = 0

bm2const.LegacyMacroName = "Buff'o'mat"
bm2const.MacroName = "Buffomat2"

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

bm2const.ShapeShiftTravel = {
  2645,
  783
} --Ghost wolf and travel druid
