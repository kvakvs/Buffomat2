---@class Bm2ProfileModule
---@field activeProfileName string|nil One of solo, party, raid, pvp...
---@field active Bm2Profile
local profileModule = Bm2Module.DeclareModule("Profile") ---@type Bm2ProfileModule

local spellsDb = Bm2Module.Import("SpellsDb") ---@type Bm2SpellsDbModule

function profileModule:LateModuleInit()
  profileModule.active = { }
  profileModule:Activate(profileModule:ChooseProfile())
end

---@class Bm2Profile
---@field selectedBuffs table<number, string> buffIds to watch and rebuff
---@field buffTargets table<string, table<number, string>> [buffId]=>table<Unit>; For targeted buffs from an item (like soulstone) stores preferred targets
---@field selectedMainhandBuff string buffId for mainhand enchantment
---@field selectedOffhandBuff string buffId for offhand enchantment
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
---@field warnNoEnchantment boolean Warn about missing enchantment
---@field openLootableInBag boolean Prompt looting quest bags, clams, opened lockboxes etc
---@field reminderConsumables boolean Instead of queuing an item use, queue a comment for consumables
---@field noBuffWithDeadMembers boolean Instead of queuing an item use, queue a comment for consumables
---@field replaceSingleWithGroup boolean Allow overwriting single buffs with group buffs
---@field singleBuffOnly boolean Never cast group buffs
---@field groupBuffMinCount number How many missing buffs in a group should trigger group buff
local profileClass = {} ---@type Bm2Profile
profileClass.__index = profileClass

---@return Bm2Profile
function profileModule:NewProfile()
  local p = {} ---@type Bm2Profile
  setmetatable(p, profileClass)

  p.selectedBuffs = profileModule:GetDefaultEnabledBuffs()
  p.buffTargets = {}
  p.selectedMainhandBuff = nil -- buffid
  p.selectedOffhandBuff = nil -- buffid
  p.cancelBuffs = {} -- list(buffId)
  p.doNotScanGroup = {} -- [number] => true
  p.scanInRestAreas = true
  p.scanInOpenWorld = true
  p.scanInDungeons = true
  p.scanInPvp = true
  p.scanInStealth = false
  p.scanWhileMounted = false
  p.preventPvpTag = true
  p.autoDismountGround = true
  p.autoDismountFlying = false
  p.autoStand = true
  p.autoLeaveShapeshift = true
  p.autoCrusaderAura = true
  p.warnReputationTrinket = true
  p.warnRidingTrinket = true
  p.warnNoWeapon = true
  p.warnNoEnchantment = true
  p.openLootableInBag = true
  p.reminderConsumables = false
  p.noBuffWithDeadMembers = true
  p.replaceSingleWithGroup = true

  p.singleBuffOnly = false
  p.groupBuffMinCount = 3

  return p
end

function profileClass:IsScanGroupEnabled(n)
  return self.doNotScanGroup[n] == nil
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
