---@class Bm2ConstModule
local constModule = Bm2Module.DeclareModule("Const")

-- Unit power type for MANA https://wowwiki-archive.fandom.com/wiki/PowerType
-- https://wowwiki-archive.fandom.com/wiki/API_UnitPowerMax
constModule.PowertypeMana = 0

constModule.LegacyMacroName = "Buff'o'mat"
constModule.AddonName = "Buffomat2"
constModule.MacroName = "Buffomat2"
constModule.MacroIcon = "Ability_Druid_ChallangingRoar"
constModule.MacroIconDisabled = "Ability_Druid_DemoralizingRoar"
constModule.MacroIconFullpath = "Interface\\ICONS\\Ability_Druid_ChallangingRoar"

constModule.IconFormat = "|T%s:0:0:0:0:64:64:4:60:4:60|t"
constModule.PictureFormat = "|T%s:0|t"

constModule.IconClass = {
  ["WARRIOR"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:0:64|t",
  ["MAGE"]    = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:0:64|t",
  ["ROGUE"]   = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:0:64|t",
  ["DRUID"]   = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:0:64|t",
  ["HUNTER"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:64:128|t",
  ["SHAMAN"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:64:128|t",
  ["PRIEST"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:64:128|t",
  ["WARLOCK"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:64:128|t",
  ["PALADIN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:128:192|t",
}
constModule.IconClassBig = {
  ["WARRIOR"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:0:64|t",
  ["MAGE"]    = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:0:64|t",
  ["ROGUE"]   = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:0:64|t",
  ["DRUID"]   = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:0:64|t",
  ["HUNTER"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:64:128|t",
  ["SHAMAN"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:64:128|t",
  ["PRIEST"]  = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:64:128|t",
  ["WARLOCK"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:64:128|t",
  ["PALADIN"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:128:192|t",
}

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

constModule.EquipTrinket1 = 13
constModule.EquipTrinket2 = 14

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
constModule.PlayerNameRealm = playerName_ .. "-" .. playerRealm_

-----------------------
-- Spell Ids database
-----------------------
constModule.spellId = {
  PALADIN_CRUSADERAURA = 32223,
  FIND_HERBS = 2383,
  FIND_MINERALS = 2580,
}
constModule.shapeshiftForm = {
  PALADIN_CRUSADERAURA = 7,
  -- CAT_FORM is a global constant
}
--- Note: Canceling shapeshift forms is currently impossible in TBC
constModule.ShapeShiftTravel = {
  2645, -- ghost wolf
  783, -- travelform
  768, -- catform
  5487, -- junior bear form
  9634, -- dire bear form
}
constModule.ReputationTrinket = {
  itemIds = {
    12846, -- Simple AD trinket
    13209, -- Seal of the Dawn +81 AP
    19812, -- Rune of the Dawn +48 SPELL
    23206, -- Mark of the Chamption +150 AP
    23207, -- Mark of the Chamption +85 SPELL
  },
  --spells = {
  --  17670, -- Simple AD trinket
  --  23930, -- Seal of the Dawn +81 AP
  --  24198, -- Rune of the Dawn +48 SPELL
  --  29112, -- Mark of the Chamption +150 AP
  --  29113, -- Mark of the Chamption +85 SPELL
  --},
  allowInZone = {
    329, 289, 533, 535, --Stratholme/scholomance; Naxxramas LK 10/25
    558, -- TBC: Auchenai
    532, -- TBC: Karazhan
  },
}
constModule.RidingTrinket = {
  itemIds     = {
    11122, -- Classic: Item [Carrot on a Stick]
    25653, -- TBC: Item [Riding Crop]
    32481, -- TBC: Item [Charm of Swift Flight]
  },
  --spells  = {
  --  13587, -- Classic: Carrot on a Stick
  --  48776, -- TBC: Riding Crop +10%
  --  48403, -- TBC: Druid "Charm of Swift Flight" +10%
  --},
  --Allow Riding Speed trinkets in:
  allowInZone = {
    0, 1, 530, -- Eastern Kingdoms, Kalimdor, Outland
    30, -- Alterac Valley
    529, -- Arathi Basin,
    489, -- Warsong Gulch
    566, 968, -- TBC: Eye of the Storm
    1672, 1505, 572 }, -- TBC: Blade's Edge Arena, Nagrand Arena, Ruins of Lordaeron
}

---------------------
-- UI icons
---------------------
constModule.IconPet = "Interface\\ICONS\\Ability_Mount_JungleTiger"
constModule.IconPetCoord = { 0.1, 0.9, 0.1, 0.9 }
