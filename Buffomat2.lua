---@class Bm2Addon
---@field playerIsMoving boolean Modified on start_move/stop_move events
---@field playerIsCasting string|nil String "cast" or "channel" when player is casting or channeling
---@field playerIsInCombat boolean
---@field lastTarget string|nil Modified when player target changes
Bm2Addon = LibStub("AceAddon-3.0"):NewAddon("Buffomat2", "AceConsole-3.0", "AceEvent-3.0")

local bm2 = Bm2Addon ---@type Bm2Addon

local optionsModule = Bm2Module.Import("Options") ---@type Bm2OptionsModule
local slashModule = Bm2Module.Import("Slash"); ---@type Bm2SlashModule
local uiModule = Bm2Module.Import("Ui"); ---@type Bm2UiModule
local _t = Bm2Module.Import("Translation") ---@type Bm2TranslationModule
local spellsDb = Bm2Module.Import("SpellsDb") ---@type Bm2SpellsDbModule
local mainWindowModule = Bm2Module.Import("Ui/MainWindow")---@type Bm2UiMainWindowModule

local function bm2MakeOptions()
  return {
    name        = "Buffomat 2 Settings",
    --handler = Questie,
    type        = "group",
    childGroups = "tab",
    args        = {
      general_tab = optionsModule:MakeGeneralTab(),
    }
  }
end

function bm2:OnInitialize()
  bm2.db = LibStub("AceDB-3.0"):New("Bm2Conf", optionsModule:GetDefaults(), true)

  Bm2Module.CallInEachModule("EarlyModuleInit")
end

local bm2Step2Done = false

function bm2:OnInitializeStep2()
  if (bm2Step2Done) then
    return
  end
  bm2Step2Done = true

  bm2:RegisterChatCommand("bm2", "HandleSlash")

  LibStub("AceConfig-3.0"):RegisterOptionsTable("Buffomat2", bm2MakeOptions())

  local configDialog = LibStub("AceConfigDialog-3.0")
  configDialog:AddToBlizOptions("Buffomat2", "Buffomat 2");

  spellsDb:InitSpellsDb()
  -- spellsDb:FilterAvailableSpells() -- no need to call here, it will be called on character enter world

  uiModule:SetupMainWindow()

  Bm2Module.CallInEachModule("LateModuleInit")
end

function bm2:HandleSlash(input)
  slashModule:HandleSlash(input)
end

function bm2:OnEnable()
  -- Do more initialization here, that really enables the use of your addon.
  -- Register Events, Hook functions, Create Frames, Get information from
  -- the game that wasn't available in OnInitialize
end

function bm2:OnDisable()
  -- Unhook, Unregister Events, Hide frames that you created.
  -- You would probably only use an OnDisable if you want to
  -- build a "standby" mode, or be able to toggle modules on/off.
end

---Close ❌ button was clicked in the main window. Hide it.
function bm2:OnCloseClick()
  mainWindowModule:HideWindow("user close")
end

---Settings ⚙ button was clicked
function bm2:OnSettingsClick()
end
