---@type Bm2Addon
Bm2Addon = LibStub("AceAddon-3.0"):NewAddon("Buffomat2", "AceConsole-3.0", "AceEvent-3.0")

local bm2 = Bm2Addon ---@type Bm2Addon

---@type Bm2OptionsModule
local options = Bm2Module.Import("Options")
---@type Bm2EventsModule
local events = Bm2Module.Import("Events");
---@type Bm2SlashModule
local slash = Bm2Module.Import("Slash");
---@type Bm2UiModule
local bm2ui = Bm2Module.Import("Ui");
---@type Bm2TranslationModule
local translation = Bm2Module.Import("Translation")
local function _t(key)
  return translation(key)
end

local function bm2MakeOptions()
  return  {
    name = "Buffomat 2 Settings",
    --handler = Questie,
    type = "group",
    childGroups = "tab",
    args = {
      general_tab = options:MakeGeneralTab(),
    }
  }
end

function bm2:OnInitialize()
  bm2.db = LibStub("AceDB-3.0"):New("Bm2Conf", options:GetDefaults(), true)
  events:RegisterEarlyEvents()
end

local bm2Step2Done = false

function bm2:OnInitializeStep2()
  if (bm2Step2Done) then return end
  bm2Step2Done = true

  bm2:RegisterChatCommand("bm2", "HandleSlash")

  LibStub("AceConfig-3.0"):RegisterOptionsTable("Buffomat2", bm2MakeOptions())

  local configDialog = LibStub("AceConfigDialog-3.0")
  configDialog:AddToBlizOptions("Buffomat2", "Buffomat 2");

  bm2ui.SetupMainWindow()
end

function bm2:HandleSlash(input)
  slash:HandleSlash(input)
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
