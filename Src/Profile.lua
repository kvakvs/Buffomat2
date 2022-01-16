---@class Bm2ProfileModule
---@field activeProfileName string|nil One of solo, party, raid, pvp...
---@field active Bm2Profile
local profileModule = Bm2Module.DeclareModule("Profile")

local spellsDb = Bm2Module.Import("SpellsDb") ---@type Bm2SpellsDbModule

function profileModule:LateModuleInit()
  profileModule.active = { }
  profileModule:Activate(profileModule:ChooseProfile())
end

---@class Bm2Profile
---@field selectedBuffs table<number, string> buffIds to watch and rebuff
---@field cancelBuffs table<number, string> buffIds to cancel on combat start
---@field doNotScanGroup table<number, boolean> raidgroups which user clicked to not scan.
---@field scanInRestAreas boolean
---@field scanInOpenWorld boolean
---@field scanInDungeons boolean
---@field scanInPvp boolean
---@field scanInStealth boolean
---@field scanWhileMounted boolean
---@field preventPvpTag boolean
---@field autoDismountGround boolean
---@field autoDismountFlying boolean
---@field autoStand boolean
---@field autoLeaveShapeshift boolean
---@field autoCrusaderAura boolean
---@field warnReputationTrinket boolean Queue gear change task, if user forgot their rep trinket on where it does not work
---@field warnRidingTrinket boolean Queue gear change task, if user uses riding trinket
---@field warnNoWeapon boolean Queue gear change task, if user has no weapon (disappeared after Kael'thas fight or unequipped) or fishing pole

---@return Bm2Profile
function profileModule:NewProfile()
  return {
    selectedBuffs         = profileModule:GetDefaultEnabledBuffs(),
    cancelBuffs           = {}, -- list(buffId)
    doNotScanGroup        = {}, -- [number] => true
    scanInRestAreas       = true,
    scanInOpenWorld       = true,
    scanInDungeons        = true,
    scanInPvp             = true,
    scanInStealth         = false,
    scanWhileMounted      = false,
    preventPvpTag         = true,
    autoDismountGround    = true,
    autoDismountFlying    = false,
    autoStand             = true,
    autoLeaveShapeshift   = true,
    autoCrusaderAura      = true,
    warnReputationTrinket = true,
    warnRidingTrinket     = true,
    warnNoWeapon          = true,
  }
end

---User clicked profile selection menu
---@param profile string
function profileModule:UserSelectedProfile(profile)
  if profile == nil or profile == "" or profile == "auto" then
    Bm2Addon.db.char.forceProfile = nil
    Bm2Addon:Print("Set profile to auto")

  elseif Bm2Addon.db.char.profile[profile] then
    Bm2Addon.db.char.forceProfile = profile
    profileModule:Activate(profile)
    Bm2Addon:Print("Set profile to " .. profile)

  else
    Bm2Addon:Print("Unknown profile: " .. profile)
  end

  -- TODO: Move this out to the caller
  local engine = Bm2Module.Import("Engine") ---@type Bm2EngineModule
  local popup = Bm2Module.Import("UiPopup") ---@type Bm2PopupModule
  local bm2ui = Bm2Module.Import("Ui") ---@type Bm2UiModule
  engine:ClearSkipList()
  bm2ui.popupDynamic:Wipe()
  engine:SetForceUpdate("user selected profile")
  engine:UpdateScan("user selected profile")
end

---Based on profile settings and current PVE or PVP instance choose the profile
---@return string
function profileModule:ChooseProfile()
  local _inInstance, instanceType = IsInInstance()
  local autoProfile = "solo"

  if IsInRaid() then
    autoProfile = "raid"
  elseif IsInGroup() then
    autoProfile = "party"
  end

  if Bm2Addon.db.char.forceProfile ~= "" then
    autoProfile = Bm2Addon.db.char.forceProfile
  elseif not Bm2Addon.db.char.useProfiles then
    autoProfile = "solo"
  elseif instanceType == "pvp" or instanceType == "arena" then
    autoProfile = "pvp"
  end

  -- Group profiles by playername/realm/playerclass/profile
  return autoProfile
end

---@return boolean True if the active profile name has changed
function profileModule:Activate(profileName)
  if not Bm2Addon.db.char.profile[profileName] then
    Bm2Addon:Print("Error: Bad profile name " .. profileName)
    return
  end

  if profileName ~= profileModule.activeProfileName then
    profileModule.activeProfileName = profileName
    profileModule.active = Bm2Addon.db.char.profile[profileName]
    return true
  end

  return false
end

---Go through all buffs known to the player, and if they are on by default, add
---their name to the result
function profileModule:GetDefaultEnabledBuffs()
  local result = {}
  for buffId, buff in pairs(spellsDb.availableBuffs) do
    if buff.defaultEnabled then
      tinsert(result, buffId)
    end
  end
  return result
end
