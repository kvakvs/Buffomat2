---@type Bm2Addon
Bm2Addon = LibStub("AceAddon-3.0"):NewAddon("Buffomat2", "AceConsole-3.0")
-- "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0"
local bm2 = Bm2Addon ---@type Bm2Addon

---@type Bm2OptionsModule
local options = Bm2Module.Import("Options")

local function bm2MakeOptions()
  return  {
    name = "Buffomat2",
    --handler = Questie,
    type = "group",
    childGroups = "tab",
    args = {
      general_tab = options:MakeGeneralTab(),
    }
  }
end

function bm2:OnInitialize()
  LibStub("AceConfig-3.0"):RegisterOptionsTable("Buffomat2", bm2MakeOptions, { "/bm", })
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
