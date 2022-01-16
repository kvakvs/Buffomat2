---@class Bm2PartyModule
---@field invalidateFlag boolean Set to true to request party refresh
---@field playerMemberCache Bm2Member Copy of player
---@field partyCache table<number, Bm2Member> Copy of party members
---@field partyUpdateFlag boolean Signals invalidation of cached party
---@field memberCache table<string, Bm2Member> Cache of party members
---@field partyUpdateNeeded boolean Set to true on party change event to rescan the party
---@field someoneIsGhost boolean Set to true if someone has released the spirit
local partyModule = Bm2Module.DeclareModule("Party")

local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local uiModule = Bm2Module.Import("Ui"); ---@type Bm2UiModule
local memberModule = Bm2Module.Import("Member"); ---@type Bm2MemberModule
local memberBuffModule = Bm2Module.Import("MemberBuff"); ---@type Bm2MemberBuffModule
local engineModule = Bm2Module.Import("Engine"); ---@type Bm2EngineModule
local toolModule = Bm2Module.Import("Tool"); ---@type Bm2ToolModule
local spellsDb = Bm2Module.Import("SpellsDb"); ---@type Bm2SpellsDbModule

---@return number Party size including pets
local function bm2GetPartySize()
  local countTo
  local prefix
  local count

  if IsInRaid() then
    countTo = 40
    prefix = "raid"
    count = 0
  else
    countTo = 4
    prefix = "party"

    if UnitPlayerOrPetInParty("pet") then
      count = 2
    else
      count = 1
    end
  end

  for i = 1, countTo do
    if UnitPlayerOrPetInParty(prefix .. i) then
      count = count + 1

      if UnitPlayerOrPetInParty(prefix .. "pet" .. i) then
        count = count + 1
      end
    end
  end

  return count
end

---@return Bm2Member
---@param unitid string Player name or special name like "raidpet#"
---@param nameGroup number The raid party this character is currently a member of. Raid subgroups are numbered as on the standard raid window.
---@param nameRole string The player's role within the raid ("MAINTANK" or "MAINASSIST").
local function bm2GetMember(unitid, nameGroup, nameRole, specialName)
  local name, _unitRealm = UnitFullName(unitid)
  if name == nil then
    return nil
  end

  local group
  if type(nameGroup) == "number" then
    group = nameGroup
  else
    group = nameGroup or 1
  end

  local isTank = nameRole and (nameRole == "MAINTANK") or false

  local guid = UnitGUID(unitid)
  local _, class, link

  if guid then
    _, class = GetPlayerInfoByGUID(guid)
    if class then
      link = constModule.IconClass[class] .. "|Hunit:" .. guid .. ":" .. name
          .. "|h|c" .. RAID_CLASS_COLORS[class].colorStr .. name .. "|r|h"
    else
      class = ""
      link = uiModule:FormatTexture(constModule.IconPet) .. name
    end
  else
    class = ""
    link = uiModule:FormatTexture(constModule.IconPet) .. name
  end

  if specialName then
    -- do not cache just construct
    local member = memberModule:New()
    member:Construct(unitid, name, group, class, link, isTank)
    return member
  else
    -- store in cache
    partyModule.memberCache[unitid] = partyModule.memberCache[unitid] or memberModule:New()
    local member = partyModule.memberCache[unitid]
    member:Construct(unitid, name, group, class, link, isTank)
    return member
  end
end

---@return table, Bm2Member
---@param player_member Bm2Member
local function bm2Get5manPartyMembers(player_member)
  local name_group = {}
  local name_role = {}
  local party = {}
  local member ---@type Bm2Member

  for groupIndex = 1, 4 do
    member = bmGetMember("party" .. groupIndex)

    if member then
      tinsert(party, member)
    end

    member = bm2GetMember("partypet" .. groupIndex, nil, nil, true)

    if member then
      member.group = 9
      member.class = "pet"
      tinsert(party, member)
    end
  end

  player_member = bm2GetMember("player")
  tinsert(party, player_member)

  member = bm2GetMember("pet", nil, nil, true)

  if member then
    member.group = 9
    member.class = "pet"
    tinsert(party, member)
  end

  return party, player_member
end

---For when player is in raid, retrieve all 40 raid members
---@param player_member Bm2Member
---@return table, Bm2Member
local function bm2Get40manRaidMembers(player_member)
  local name_group = {}
  local name_role = {}
  local party = {}

  for raid_index = 1, 40 do
    local name, _rank, subgroup, _level, _class, _fileName, _zone, _online, _isDead
    , role, _isML, _combatRole = GetRaidRosterInfo(raid_index)

    if name then
      name = BOM.Tool.Split(name, "-")[1]
      name_group[name] = subgroup
      name_role[name] = role
    end
  end

  for raid_index = 1, 40 do
    local member = bm2GetMember("raid" .. raid_index, name_group, name_role)

    if member then
      if UnitIsUnit(member.unitId, "player") then
        player_member = member
      end
      tinsert(party, member)

      member = bm2GetMember("raidpet" .. raid_index, nil, nil, true)
      if member then
        member.group = 9
        member.class = "pet"
        tinsert(party, member)
      end
    end
  end
  return party, player_member
end

---Retrieve a table with party members and buffs
---@return table<number, Bm2Member>, Bm2Member {Party, Player}
function partyModule:GetPartyMembers()
  local party ---@type table<number, Bm2Member>
  local playerMember --- @type Bm2Member

  -- check if stored party is correct!
  if not partyModule.invalidateFlag
      and partyModule.partyCache ~= nil
      and partyModule.playerMemberCache ~= nil then

    if #(partyModule.partyCache) == bm2GetPartySize() then
      local ok = true
      for i, member in ipairs(partyModule.partyCache) do
        if member:UnitFullName() ~= member.name then
          ok = false
          break
        end
      end

      if ok then
        party = partyModule.partyCache
        playerMember = partyModule.playerMemberCache
      end
    end
  end

  --------------------
  -- read party data
  --------------------
  if party == nil or playerMember == nil then
    if IsInRaid() then
      party, playerMember = bm2Get40manRaidMembers(playerMember)
    else
      party, playerMember = bm2Get5manPartyMembers(playerMember)
    end

    partyModule.partyCache = party
    partyModule.playerMemberCache = playerMember
    engineModule:CleanBuffsForParty()

    engineModule:SetForceUpdate("joined party") -- always read all buffs on new party!
  end

  partyModule.partyUpdateFlag = false
  partyModule.someoneIsGhost = false

  local playerZone = C_Map.GetBestMapForUnit("player")

  if IsAltKeyDown() then
    engineModule.declineHasResurrection = true
    engineModule:ClearSkipList()
  end

  ------------------------------------------
  -- For every party member which is in same
  -- zone, not a ghost or is a target
  ------------------------------------------
  for _i, member in ipairs(party) do
    member.isSameZone = (member:GetZone() == playerZone)
        or member.isGhost
        or member.unitId == "target"

    if not member.isDead
        or engineModule.declineHasResurrection
    then
      member.hasResurrection = false
      member.distance = toolModule.UnitDistanceSquared(member.unitId)
    else
      member.hasResurrection = UnitHasIncomingResurrection(member.unitId)
          or member.hasResurrection
    end

    if engineModule.forceUpdate then
      local ghost = member:ForceUpdateBuffs(playerMember)
      partyModule.someoneIsGhost = partyModule.someoneIsGhost or ghost
    end -- if force update
  end -- for all in party

  --------------------
  -- weapon-buffs
  --------------------
  -- Clear old
  local oldMainHandEnchantment = playerMember.mainHandEnchantment
  local oldOffHandEnchantment = playerMember.offHandEnchantment

  local hasMainHandEnchant, mainHandExpirationMsec, _mainHandCharges, mainHandEnchantID
  , hasOffHandEnchant, offHandExpirationMsec, _offHandCharges, offHandEnchantId = GetWeaponEnchantInfo()

  local mainhandBuffId = spellsDb.enchantmentIdBuffReverseLookup[mainHandEnchantID]

  -- Mainhand enchantment
  if hasMainHandEnchant and mainHandEnchantID and mainhandBuffId then
    local duration
    local mainhandBuff = spellsDb.allPossibleBuffs[mainhandBuffId]

    if mainhandBuff and mainhandBuff.singleDuration then
      duration = mainhandBuff.singleDuration
    else
      duration = constModule.DURATION_5M
    end

    playerMember.mainHandEnchantment = memberBuffModule:New(
        mainhandBuffId,
        nil,
        mainHandEnchantID,
        duration,
        GetTime() + mainHandExpirationMsec / 1000)
    playerMember.mainHandEnchantment = mainhandBuffId
  else
    playerMember.mainHandEnchantment = nil
  end

  local offhandBuffId = spellsDb.enchantmentIdBuffReverseLookup[offHandEnchantId]

  -- Mainhand enchantment
  if hasOffHandEnchant and offHandEnchantId and offhandBuffId then
    local duration
    local offhandBuff = spellsDb.allPossibleBuffs[offhandBuffId]

    if offhandBuff and offhandBuff.singleDuration then
      duration = offhandBuff.singleDuration
    else
      duration = constModule.DURATION_5M
    end

    playerMember.offHandEnchantment = memberBuffModule:New(
        offhandBuffId,
        nil,
        offHandEnchantId,
        duration,
        GetTime() + offHandExpirationMsec / 1000)
  else
    playerMember.offHandEnchantment = nil
  end

  if oldMainHandEnchantment ~= playerMember.mainHandEnchantment then
    engine:SetForceUpdate("mainhand enchantment changed")
  end

  if oldOffHandEnchantment ~= playerMember.offHandEnchantment then
    engine:SetForceUpdate("offhand enchantment changed")
  end

  engineModule.declineHasResurrection = false
  return party, playerMember
end
