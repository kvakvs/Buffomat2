---@class Bm2TaskListModule
---@field currentPlayerMana number Used for task list building
---@field maxPlayerMana number Used for task list building
---@field tasks table<number, Bm2Task> Spells and buffs to cast, sorted

---@field activeAura string BuffId of active aura (Updated by bm2GetActiveAuraAndSeal) around player
---@field activeSeal string BuffId of active seal (Updated by bm2GetActiveAuraAndSeal) a buff providing weapon augment
---@field lastAura string Updated by bm2GetActiveAuraAndSeal

local taskListModule = Bm2Module.DeclareModule("TaskList") ---@type Bm2TaskListModule
taskListModule.tasks = {} ---@type table<number, Bm2Task>
taskListModule.currentPlayerMana = 0
taskListModule.maxPlayerMana = 0

local _t = Bm2Module.Import("Translation") ---@type Bm2TranslationModule
local bagModule = Bm2Module.Import("Bag")---@type Bm2BagModule
local buffDefModule = Bm2Module.Import("SpellsDb/BuffDef")---@type Bm2BuffDefModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local engineModule = Bm2Module.Import("Engine") ---@type Bm2EngineModule
local eventsModule = Bm2Module.Import("Events")---@type Bm2EventsModule
local macroModule = Bm2Module.Import("Macro") ---@type Bm2MacroModule
local mainWindow = Bm2Module.Import("Ui/MainWindow") ---@type Bm2UiMainWindowModule
local partyModule = Bm2Module.Import("Party")---@type Bm2PartyModule
local profileModule = Bm2Module.Import("Profile")---@type Bm2ProfileModule
local spellsDb = Bm2Module.Import("SpellsDb")---@type Bm2SpellsDbModule
local taskModule = Bm2Module.Import("Task")---@type Bm2TaskModule
local uiModule = Bm2Module.Import("Ui") ---@type Bm2UiModule
local spellDefModule = Bm2Module.Import("SpellDef") ---@type Bm2SpellDefModule

-- -@class Bm2CastSpell
-- -@field target string
-- -@field buff Bm2BuffDefinition
-- -@field text string Text comment to display, when target and buff are nil

---Returns flying, if no autodismount. Otherwise we're "not flying", feel free
---to fall to your death.
local function bm2IsFlying()
  if constModule.IsTBC then
    return IsFlying() and not profileModule.active.autoDismountFlying
  end
  return false
end

local function bm2IsMountedAndCrusaderAuraRequired()
  return profileModule.active.autoCrusaderAura -- if setting enabled
      and IsSpellKnown(constModule.spellId.PALADIN_CRUSADERAURA) -- and has the spell
      and (IsMounted() or bm2IsFlying()) -- and flying or mounted otherwise
      and GetShapeshiftForm() ~= constModule.shapeshiftForm.PALADIN_CRUSADERAURA -- and not crusader aura
end

---Run checks to see if Buffomat should not be scanning buffs
---@return boolean, string {IsActive, WhyNotActive: string}
local function bm2IsActive()
  -- Cancel buff tasks if in combat (ALWAYS FIRST CHECK)
  if InCombatLockdown() then
    return false, _t("Disabled: In combat")
  end

  if UnitIsDeadOrGhost("player") then
    return false, _t("Disabled: Player is dead")
  end

  local _inInstance, instanceType = IsInInstance()

  if instanceType == "pvp" or instanceType == "arena" then
    if not profileModule.active.scanInPvp then
      return false, _t("Disabled: In a PvP zone")
    end

  elseif instanceType == "party"
      or instanceType == "raid"
      or instanceType == "scenario"
  then
    if not profileModule.active.scanInDungeons then
      return false, _t("Disabled: In a dungeon")
    end
  else
    if not profileModule.active.scanInOpenWorld then
      return false, _t("Disabled: In open world")
    end
  end

  -- Cancel buff tasks if is in a resting area, and option to scan is not set
  if not profileModule.active.scanInRestAreas and IsResting() then
    return false, _t("Disabled: In a rest area")
  end

  -- Cancel buff task scan while mounted
  if not profileModule.active.scanWhileMounted and IsMounted() then
    return false, _t("Disabled: On a mount")
  end

  -- Cancel buff tasks if is in stealth, and option to scan is not set
  if not profileModule.active.scanInStealth and IsStealthed() then
    return false, _t("Disabled: In stealth")
  end

  -- Having auto crusader aura enabled and Paladin class, and aura other than
  -- Crusader will block this check temporarily
  if bm2IsFlying() and not bm2IsMountedAndCrusaderAuraRequired() then
    -- prevent dismount in flight, OUCH!
    return false, _t("Disabled: Flying")

  elseif UnitOnTaxi("player") then
    return false, _t("Disabled: On a taxi")
  end

  return true, nil
end

local function bm2HunterPetNeedsBuff(buffId)
  if not constModule.IsTBC then
    return false -- pre-TBC this did not exist
  end

  local pet = partyModule:GetMember("pet")
  if not pet then
    return false -- no pet - no problem
  end

  if pet:HasBuff(buffId) then
    return false -- have pet, have buff
  end

  return true
end

---@param expirationTime number Buff expiration time
---@param maxDuration number Max buff duration
local function bm2TimeCheck(expirationTime, maxDuration)
  if expirationTime == nil
      or maxDuration == nil
      or expirationTime == 0
      or maxDuration == 0 then
    return true
  end

  local dif

  if maxDuration <= 60 then
    dif = Bm2Addon.db.char.rebuffForDuration60
  elseif maxDuration <= 300 then
    dif = Bm2Addon.db.char.rebuffForDuration300
  elseif maxDuration <= 600 then
    dif = Bm2Addon.db.char.rebuffForDuration600
  elseif maxDuration <= 1800 then
    dif = Bm2Addon.db.char.rebuffForDuration1800
  else
    dif = Bm2Addon.db.char.rebuffForDuration3600
  end

  if dif + GetTime() < expirationTime then
    expirationTime = expirationTime - dif
    return true
  end

  return false
end

---@param state Bm2ScanState
---@param buff Bm2BuffDefinition - the spell to update
local function bm2UpdateBuffTargets_Blessing(state, buff)
  Bm2Addon:Print("updateBuffTargets: Blessing") -- TODO: blessing targets
  --for _index, member in ipairs(state.party) do
  --  local ok = false
  --  local notGroup = false
  --  local blessingName = BOM.GetProfileSpell(BOM.BLESSING_ID)
  --  local blessingSpell = BOM.GetProfileSpell(buff.ConfigID)
  --
  --  if blessingName[member.name] == buff.buffId
  --      or (member.isTank
  --      and blessingSpell.Class["tank"]
  --      and not blessingSpell.SelfCast)
  --  then
  --    ok = true
  --    notGroup = true
  --
  --  elseif blessingName[member.name] == nil then
  --    if blessingSpell.Class[member.class]
  --        and (not IsInRaid() or BomCharacterState.WatchGroup[member.group])
  --        and not blessingSpell.SelfCast then
  --      ok = true
  --    end
  --    if blessingSpell.SelfCast
  --        and UnitIsUnit(member.unitId, "player") then
  --      ok = true
  --    end
  --  end
  --
  --  if blessingSpell.ForcedTarget[member.name] then
  --    ok = true
  --  end
  --  if blessingSpell.ExcludedTarget[member.name] then
  --    ok = false
  --  end
  --
  --  if member.NeedBuff
  --      and ok
  --      and member.isConnected
  --      and (not BOM.SharedState.SameZone or member.isSameZone) then
  --    local found = false
  --    local member_buff = member.buffs[buff.ConfigID]
  --
  --    if member.isDead then
  --      if member.group ~= 9 and member.class ~= "pet" then
  --        someoneIsDead = true
  --        buff.DeathGroup[member.class] = true
  --      end
  --
  --    elseif member_buff then
  --      found = bomTimeCheck(member_buff.expirationTime, member_buff.duration)
  --    end
  --
  --    if not found then
  --      tinsert(buff.NeedMember, member)
  --      if not notGroup then
  --        buff:IncrementNeedGroupBuff(member.class)
  --      end
  --    elseif not notGroup
  --        and BOM.SharedState.ReplaceSingle
  --        and member_buff
  --        and member_buff.isSingle then
  --      buff:IncrementNeedGroupBuff(member.class)
  --    end
  --
  --  end
  --end
end

---@param state Bm2ScanState
---@param buff Bm2BuffDefinition - the spell to update
local function bm2UpdateBuffTargets_Other(state, buff)
  --spells
  for _index, member in ipairs(state.party) do
    local pickThisTarget = false
    local buffSelfCast = buff:IsSelfCast()

    if buff:CanTarget(member.class)
        and (not IsInRaid() or profileModule.active:IsScanGroupEnabled(member.group))
        and not buffSelfCast then
      pickThisTarget = true
    end

    if buffSelfCast
        and UnitIsUnit(member.unitId, "player") then
      pickThisTarget = true
    end

    if member.isTank
        and buff:CanTarget("tank")
        and not buffSelfCast then
      pickThisTarget = true
    end

    if buff.alwaysBuffTargets and buff.alwaysBuffTargets[member.name] then
      pickThisTarget = true
    end

    if buff.neverBuffTargets and buff.neverBuffTargets[member.name] then
      pickThisTarget = false
    end

    if pickThisTarget
        and member.isConnected
        and member.isSameZone
    then
      local found = false
      local buffOnMember = member.buffs[buff.buffId]

      if member.isDead then
        state.someoneIsDead = true
        buff.calculatedDeathGroup[member.group] = true -- a dead member has been found

      elseif buffOnMember then
        found = bm2TimeCheck(buffOnMember.expirationTime, buffOnMember.duration)
      end

      if not found then
        tinsert(buff.calculatedTargets, member)
        buff.calculatedGroup[member.group] = (buff.calculatedGroup[member.group] or 0) + 1
      elseif profileModule.active.replaceSingleWithGroup
          and buffOnMember and buffOnMember:IsSingle()
      then
        buff.calculatedGroup[member.group] = (buff.calculatedGroup[member.group] or 0) + 1
      end
    end -- if needbuff and connected and samezone
  end -- for all in party
end

---Check for party, spell and player, which targets that spell goes onto
---Update spell.NeedMember, spell.NeedGroup and spell.DeathGroup
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition - the spell to update
local function bm2UpdateBuffTargets(state, buff)
  buff.calculatedTargets = buff.calculatedTargets or {}
  buff.calculatedGroup = buff.calculatedGroup or {}
  buff.calculatedDeathGroup = buff.calculatedDeathGroup or {}

  wipe(buff.calculatedGroup)
  wipe(buff.calculatedTargets)
  wipe(buff.calculatedDeathGroup)

  if buff.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_ITEM then
    if (profileModule.active.selectedMainhandBuff
        and state.player.mainHandEnchantment == nil)
        or (profileModule.active.selectedOffhandBuff
        and state.player.offHandEnchantment == nil)
    then
      tinsert(buff.calculatedTargets, state.player)
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_ITEM_USE
      and bm2HunterPetNeedsBuff(buff.buffId) then
    -- For TBC hunter pet buffs we check if the pet is missing the buff
    -- but then the hunter must consume it
    tinsert(buff.calculatedTargets, state.player)

  elseif buff:IsConsumableBuff() then
    if not state.player:HasBuff(buff.buffId) then
      tinsert(buff.NeedMember, state.player)
    end

  elseif buff.whisperExpired then
    for _index, member in ipairs(state.party) do
      local buffOnMember = member.buffs[buff.buffId]

      if buffOnMember then
        tinsert(buff.calculatedTargets, member)

        -- if buff is on us, the player, store who casted this buff in buff.source
        if member.isPlayer then
          buff.source = buffOnMember.source
          --If the buff is casted on the player, store who did it
          partyModule.buffSourceCache[buff.buffId] = buff.source
        end
      end
    end

  elseif buff.targetClasses == "player" then
    local buffOnPlayer = state.player.buffs[buff.buffId]

    if not state.player.isDead then
      if buff.lockIfHaveItem then
        if bagModule:AnyInventoryItem(buff.lockIfHaveItem, false) == nil then
          tinsert(buff.calculatedTargets, state.player)
        end

      elseif not (buffOnPlayer
          and bm2TimeCheck(buffOnPlayer.expirationTime, buffOnPlayer.duration)
      ) then
        tinsert(buff.calculatedTargets, state.player)
      end
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_RESURRECTION then
    for _index, member in ipairs(state.party) do
      if member.isDead
          and not member.hasResurrection
          and member.isConnected
          and member.group ~= 9 -- postponed failed resurrection
          and member.isSameZone
      then
        tinsert(buff.calculatedTargets, member)
      end
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_TRACKING then
    -- Special handling: Having find herbs and find ore will be ignored if
    -- in cat form and track humanoids is enabled
    if (buff.buffId == "buff_findherbs" or buff.buffId == "buff_findminerals")
        and GetShapeshiftFormID() == CAT_FORM
        and tContains(profileModule.active.selectedBuffs, "buff_trackhumanoids") then
      -- Do nothing - ignore herbs and minerals in catform if enabled track humanoids
    elseif not buff:IsTrackingActive() then
      tinsert(buff.calculatedTargets, state.player)
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_AURA then
    if taskListModule.activeAura ~= buff.buffId then
      tinsert(buff.calculatedTargets, state.player)
    end

  elseif buff.type == buffDefModule.BUFFTYPE_SEAL then
    if taskListModule.activeSeal ~= buff.buffId then
      tinsert(buff.calculatedTargets, state.player)
    end

  elseif buff.type == buffDefModule.BUFFTYPE_BLESSING then
    bm2UpdateBuffTargets_Blessing(state, buff)

  else
    bm2UpdateBuffTargets_Other(state, buff)
  end

  -- Check Spell CD
  local _index, firstCalcTarget = next(buff.calculatedTargets) ---@type Bm2Member
  if buff.hasCooldown and firstCalcTarget ~= nil then
    local highestSingle = buff:SelectSingleSpell(firstCalcTarget.name)
    local startTime, duration = GetSpellCooldown(highestSingle.spellId)

    if duration > 0 then
      wipe(buff.calculatedGroup)
      wipe(buff.calculatedTargets)
      wipe(buff.calculatedDeathGroup)

      startTime = startTime + duration
      state.someoneIsDead = false
    end
  end
end

---@param state Bm2ScanState
local function bm2ForceUpdate(state)
  -- who needs a buff!
  -- for each spell update spell potential targets
  local someoneIsDead = false -- the flag that buffing cannot continue while someone is dead

  -- For each selected spell check the targets
  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    bm2UpdateBuffTargets(state, buff)
  end

  return someoneIsDead
end

local function bm2IsMountedAndCrusaderAuraWanted()
  return Bm2Addon.db.char.autoCrusaderAura -- if setting enabled
      and IsSpellKnown(constModule.spellId.PALADIN_CRUSADERAURA) -- and has the spell
      and (IsMounted() or bm2IsFlying()) -- and flying
      and GetShapeshiftForm() ~= constModule.shapeshiftForm.PALADIN_CRUSADERAURA -- and not crusader aura
end

---@param state Bm2ScanState
---@param target string
---@param buffId string
function taskListModule:QueueBuff(state, target, buffId)
  tinsert(state.tasks, taskModule:NewBuffTask(target, buffId))
end

---@param state Bm2ScanState
---@param buff Bm2BuffDefinition
function taskListModule:QueueSummon(state, buff)
  tinsert(state.tasks, taskModule:NewSummonTask(buff))
end

---@param state Bm2ScanState
---@param target string Unit or nil
---@param item Bm2GetContainerItemInfoResult
function taskListModule:QueueUseItem(state, item, target)
  tinsert(state.tasks, taskModule:NewUseItemTask(item, target))
end

---@param state Bm2ScanState
---@param target string Unit or nil
---@param item Bm2GetContainerItemInfoResult
function taskListModule:QueueOpenItem(state, item)
  tinsert(state.tasks, taskModule:NewOpenItemTask(item))
end

---Add a text comment to the task list
---@param state Bm2ScanState
function taskListModule:QueueComment(state, text)
  tinsert(state.tasks, taskModule:NewComment(text))
end

---Add a text comment to the task list
---@param state Bm2ScanState
function taskListModule:QueueError(state, text)
  tinsert(state.tasks, taskModule:NewError(text))
end

---@class Bm2ScanState
---@field player Bm2Member
---@field party table<number, Bm2Member>
---@field inRange boolean
---@field castButtonTitle string
---@field macroCommand string
---@field tasks table<number, Bm2Task> Tasklist to be stored as taskListModule.tasks in the end
---@field someoneIsDead boolean Prevent buffing if the group contains dead people (also a profile option)

---Adds a summon spell to the tasks
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition the spell to cast
local function bm2AddSummonSpell(state, buff)
  -- Prevent resummoning a sacrificed warlock pet
  if buff.sacrificeAuraIds then
    for i, id in ipairs(buff.sacrificeAuraIds) do
      if state.player.buffExists[id] then
        return -- do not add this summon, as a sacrifice aura has been found on player
      end
    end -- for each sacrifice aura id
  end

  local pickThisBuff = false

  if not UnitExists("pet") then
    pickThisBuff = true -- No pet? Need summon

  else
    -- Have pet? Check whether existing pet is different from the one we're about to summon
    local ucType = UnitCreatureType("pet")
    local ucFamily = UnitCreatureFamily("pet")

    if ucType ~= buff.creatureType or ucFamily ~= buff.creatureFamily then
      pickThisBuff = true
    end
  end

  if pickThisBuff then
    taskListModule:QueueSummon(state, buff)
  end
end

---Adds a display text for a weapon buff created by a consumable item
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition the spell to cast
local function bm2AddConsumableWeaponBuff(state, buff)
  -- TODO: Fix this
  Bm2Addon:Print("TODO: add consum weap buff")
  -- count - reagent count remaining for the spell
  local have_item, bag, slot, count = bomHasItem(buff.items, true)
  count = count or 0

  if have_item then
    -- Have item, display the cast message and setup the cast button
    local texture, _, _, _, _, _, item_link, _, _, _ = GetContainerItemInfo(bag, slot)
    local profile_spell = BOM.GetProfileSpell(buff.ConfigID)

    if profile_spell.OffHandEnable
        and playerMember.OffHandBuff == nil then
      local function offhand_message()
        return BOM.FormatTexture(texture) .. item_link .. "x" .. count
      end

      if BOM.SharedState.DontUseConsumables
          and not IsModifierKeyDown() then
        -- Text: [Icon] [Consumable Name] x Count (Off-hand)
        tasklist:Add(
            offhand_message(),
            nil,
            "(" .. L.TooltipOffHand .. ") " .. L.BUFF_CONSUMABLE_REMINDER,
            BOM.Class.MemberBuffTarget:fromSelf(playerMember),
            true)
      else
        -- Text: [Icon] [Consumable Name] x Count (Off-hand)
        castButtonTitle = offhand_message()
        macroCommand = "/use " .. bag .. " " .. slot
            .. "\n/use 17" -- offhand
        tasklist:Add(
            castButtonTitle,
            nil,
            "(" .. L.TooltipOffHand .. ") ",
            BOM.Class.MemberBuffTarget:fromSelf(playerMember),
            false)
      end
    end

    if profile_spell.MainHandEnable
        and playerMember.MainHandBuff == nil then
      local function mainhand_message()
        return BOM.FormatTexture(texture) .. item_link .. "x" .. count
      end

      if BOM.SharedState.DontUseConsumables
          and not IsModifierKeyDown() then
        -- Text: [Icon] [Consumable Name] x Count (Main hand)
        tasklist:Add(
            mainhand_message(),
            nil,
            "(" .. L.TooltipMainHand .. ") " .. L.BUFF_CONSUMABLE_REMINDER,
            BOM.Class.MemberBuffTarget:fromSelf(playerMember),
            true)
      else
        -- Text: [Icon] [Consumable Name] x Count (Main hand)
        castButtonTitle = mainhand_message()
        macroCommand = "/use " .. bag .. " " .. slot .. "\n/use 16" -- mainhand
        tasklist:Add(
            castButtonTitle,
            nil,
            "(" .. L.TooltipMainHand .. ") ",
            BOM.Class.MemberBuffTarget:fromSelf(playerMember),
            false)
      end
    end
    BOM.ScanModifier = BOM.SharedState.DontUseConsumables
  else
    -- Don't have item but display the intent
    -- Text: [Icon] [Consumable Name] x Count
    if buff.single then
      -- spell.single can be nil on addon load
      tasklist:Add(
          buff.single .. "x" .. count,
          nil,
          L.TASK_CLASS_MISSING_CONSUM,
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          true)
    else
      BOM.SetForceUpdate("WeaponConsumableBuff display text") -- try rescan?
    end
  end

  return castButtonTitle, macroCommand
end

---Adds a display text for a weapon buff created by a spell (shamans and paladins)
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition the spell to cast
local function bm2AddWeaponEnchantment(state, buff)
  -- TODO: Fix this
  Bm2Addon:Print("TODO: add weap enchantment buff")
  local block_offhand_enchant = false -- set to true to block temporarily

  local _, self_class, _ = UnitClass("player")
  if BOM.TBC and self_class == "SHAMAN" then
    -- Special handling for TBC shamans, you cannot specify slot for enchants,
    -- and it goes into main then offhand
    local has_mh, _mh_expire, _mh_charges, _mh_enchantid, has_oh, _oh_expire
    , _oh_charges, _oh_enchantid = GetWeaponEnchantInfo()

    if not has_mh then
      -- shamans in TBC can't enchant offhand if MH enchant is missing
      block_offhand_enchant = true
    end

    if has_oh then
      block_offhand_enchant = true
    end
  end

  local profile_spell = BOM.GetProfileSpell(buff.ConfigID)

  if profile_spell.MainHandEnable
      and playerMember.MainHandBuff == nil then
    -- Text: [Spell Name] (Main hand)
    tasklist:Add(
        buff.singleLink,
        buff.single,
        L.TooltipMainHand,
        BOM.Class.MemberBuffTarget:fromSelf(playerMember),
        false)
    bomQueueSpell(buff.singleMana, buff.singleId, buff.singleLink,
        playerMember, buff)
  end

  if profile_spell.OffHandEnable
      and playerMember.OffHandBuff == nil then
    if block_offhand_enchant then
      -- Text: [Spell Name] (Off-hand) Blocked waiting
      tasklist:Add(
          buff.singleLink,
          buff.single,
          L.TooltipOffHand .. ": " .. L.ShamanEnchantBlocked,
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          true)
    else
      -- Text: [Spell Name] (Off-hand)
      tasklist:Add(
          buff.singleLink,
          buff.single,
          L.TooltipOffHand,
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          false)
      bomQueueSpell(buff.singleMana, buff.singleId, buff.singleLink,
          playerMember, buff)
    end
  end

  return castButtonTitle, macroCommand
end

---Adds a display text for a consumable buff
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition
local function bm2AddConsumableSelfbuff(state, buff)
  -- TODO: fix below
  Bm2Addon:Print("TODO: add consumable buff")
  local haveItemOffCD, bag, slot, count = bomHasItem(buff.items, true)
  count = count or 0

  local taskText = L.TASK_USE
  if buff.tbcHunterPetBuff then
    taskText = L.TASK_TBC_HUNTER_PET_BUFF
  end

  if haveItemOffCD then
    if BOM.SharedState.DontUseConsumables
        and not IsModifierKeyDown() then
      -- Text: [Icon] [Consumable Name] x Count
      tasklist:AddWithPrefix(
          taskText,
          bomFormatItemBuffText(bag, slot, count),
          nil,
          L.BUFF_CONSUMABLE_REMINDER,
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          true)
    else
      if target then
        macroCommand = string.format("/use [@%s] %d %d", target, bag, slot)
      else
        macroCommand = string.format("/use %d %d", bag, slot)
      end
      castButtonTitle = L.TASK_USE .. " " .. buff.single

      -- Text: [Icon] [Consumable Name] x Count
      tasklist:AddWithPrefix(
          taskText,
          bomFormatItemBuffText(bag, slot, count),
          nil,
          "",
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          false)
    end

    BOM.ScanModifier = BOM.SharedState.DontUseConsumables
  else
    -- Text: "ConsumableName" x Count
    if buff.single then
      -- safety, can crash on load
      tasklist:AddWithPrefix(
          L.TASK_USE,
          bomFormatItemBuffInactiveText(buff.single, count),
          nil,
          "",
          BOM.Class.MemberBuffTarget:fromSelf(playerMember),
          true)
    end
  end

  return castButtonTitle, macroCommand
end

---Adds a display text for a self buff or tracking or seal/weapon self-enchant
---@param buff Bm2BuffDefinition the buff to cast
---@param state Bm2ScanState
local function bm2AddSelfbuff(state, buff)
  if buff.requiresWarlockPet then
    if not UnitExists("pet") or UnitCreatureType("pet") ~= "Demon" then
      return -- No demon pet - buff can not be casted
    end
  end

  if buff.requiresOutdoors and not IsOutdoors() then
    return -- not outdoors
  end
  if tContains(buff.calculatedSkiplist, state.player.name) then
    return -- skip list, try later
  end

  taskListModule:QueueBuff(state, "player", buff.buffId)
end

---Adds a display text for resurrection of a dead player
---@param state Bm2ScanState
---@param buff Bm2BuffDefinition
local function bm2AddResurrection(state, buff)
  local clearskip = true

  for _index, member in ipairs(buff.calculatedTargets) do
    if not tContains(buff.calculatedSkiplist, member.name) then
      clearskip = false
      break
    end
  end

  if clearskip then
    wipe(buff.calculatedSkiplist)
  end

  --Prefer resurrection classes first
  --TODO: This also modifies all subsequent operations on this table preferring those classes first
  table.sort(buff.calculatedTargets, function(a, b)
    local a_resser = tContains(constModule.RESURRECT_CLASSES, a.class)
    local b_resser = tContains(constModule.RESURRECT_CLASSES, b.class)
    if a_resser then
      return not b_resser
    end
    return false
  end)

  for _index, member in ipairs(buff.calculatedTargets) do
    if not tContains(buff.calculatedSkiplist, member.name) then
      engineModule.repeatUpdate = true

      -- Is the body in range?
      local selectSpell = buff:SelectSingleSpell(member.name)
      local canCast = (type(selectSpell) ~= "string")
          and not tContains(buff.calculatedSkiplist, member.name)

      if canCast then
        state.inRange = true
        taskListModule:QueueBuff(state, member.name, buff.buffId)

        ---- Text: Target [Spell Name]
        --tasklist:AddWithPrefix(
        --    L.TASK_CLASS_RESURRECT,
        --    buff.singleLink or buff.single,
        --    buff.single,
        --    "",
        --    BOM.Class.MemberBuffTarget:fromMember(member),
        --    false,
        --    BOM.TaskPriority.Resurrection)
      else
        taskListModule:QueueError(
            state,
            _t("Can't cast") .. " " .. buff.buffId .. ": " .. selectSpell)
        -- Text: Range Target "SpellName"
        --tasklist:AddWithPrefix(
        --    L.TASK_CLASS_RESURRECT,
        --    buff.singleLink or buff.single,
        --    buff.single,
        --    "",
        --    BOM.Class.MemberBuffTarget:fromMember(member),
        --    true,
        --    BOM.TaskPriority.Resurrection)
      end

      -- If in range, we can res?
      -- Should we try and resurrect ghosts when their corpse is not targetable?
      --if canCast or (BOM.SharedState.ResGhost and member.isGhost) then
      --  -- Prevent resurrecting PvP players in the world?
      --  bomQueueSpell(buff.singleMana, buff.singleId, buff.singleLink, member, buff)
      --end
    end
  end
end

---Add a paladin blessing
---@param buff Bm2BuffDefinition Buff to cast
---@param state Bm2ScanState
local function bm2AddBlessing(state, buff)
  --TODO: Rewrite this
  Bm2Addon:Print("TODO: blessings")

  local ok, bag, slot, count
  if buff.reagentRequired then
    ok, bag, slot, count = bomHasItem(buff.reagentRequired, true)
  end

  if type(count) == "number" then
    count = " x" .. count .. " "
  else
    count = ""
  end

  if buff.groupMana ~= nil
      and not BOM.SharedState.NoGroupBuff
  then
    -- For each class name WARRIOR, PALADIN, PRIEST, SHAMAN... etc
    for i, eachClassName in ipairs(BOM.Tool.Classes) do
      if buff.NeedGroup[eachClassName]
          and buff.NeedGroup[eachClassName] >= BOM.SharedState.MinBlessing
      then
        BOM.RepeatUpdate = true
        local classInRange = bomGetClassInRange(buff.group, buff.NeedMember, eachClassName, buff)

        if classInRange == nil then
          classInRange = bomGetClassInRange(buff.group, party, eachClassName, buff)
        end

        if classInRange ~= nil
            and (not buff.DeathGroup[eachClassName] or not BOM.SharedState.DeathBlock)
        then
          -- Group buff (Blessing)
          -- Text: Group 5 [Spell Name] x Reagents
          tasklist:AddWithPrefix(
              L.TASK_BLESS_GROUP,
              buff.groupLink or buff.group,
              buff.single,
              "",
              BOM.Class.GroupBuffTarget:new(eachClassName),
              false)
          inRange = true

          bomQueueSpell(buff.groupMana, buff.groupId, buff.groupLink, classInRange, buff)
        else
          -- Group buff (Blessing) just info text
          -- Text: Group 5 [Spell Name] x Reagents
          tasklist:AddWithPrefix(
              L.TASK_BLESS_GROUP,
              buff.groupLink or buff.group,
              buff.single,
              "",
              BOM.Class.GroupBuffTarget:new(eachClassName),
              true)
        end
      end -- if needgroup >= minblessing
    end -- for all classes
  end

  -- SINGLE BUFF
  for memberIndex, member in ipairs(buff.NeedMember) do
    if not member.isDead
        and buff.singleMana ~= nil
        and (BOM.SharedState.NoGroupBuff
        or buff.groupMana == nil
        or member.class == "pet"
        or buff.NeedGroup[member.class] == nil
        or buff.NeedGroup[member.class] < BOM.SharedState.MinBlessing) then

      if not member.isPlayer then
        BOM.RepeatUpdate = true
      end

      local add = ""
      local blessing_name = BOM.GetProfileSpell(BOM.BLESSING_ID)
      if blessing_name[member.name] ~= nil then
        add = string.format(BOM.PICTURE_FORMAT, BOM.ICON_TARGET_ON)
      end

      local test_in_range = IsSpellInRange(buff.single, member.unitId) == 1
          and not tContains(buff.SkipList, member.name)
      if bomPreventPvpTagging(buff.singleLink, buff.single, member) then
        -- Nothing, prevent poison function has already added the text
      elseif test_in_range then
        -- Single buff on group member
        -- Text: Target [Spell Name]
        tasklist:AddWithPrefix(
            L.TASK_BLESS,
            buff.singleLink or buff.single,
            buff.single,
            "",
            BOM.Class.MemberBuffTarget:fromMember(member),
            false)
        inRange = true

        bomQueueSpell(buff.singleMana, buff.singleId, buff.singleLink, member, buff)
      else
        -- Single buff on group member (inactive just text)
        -- Text: Target "SpellName"
        tasklist:AddWithPrefix(
            L.TASK_BLESS,
            buff.singleLink or buff.single,
            buff.single,
            "",
            BOM.Class.MemberBuffTarget:fromMember(member),
            true)
      end -- if in range
    end -- if not dead
  end -- for all NeedMember
end

local function bm2GetGroupInRange(SpellName, party, groupNb, spell)
  local minDist
  local ret
  for i, member in ipairs(party) do
    if member.group == groupNb then
      if not (IsSpellInRange(SpellName, member.unitId) == 1 or member.isDead) then
        if member.distance > 2000 then
          return nil
        end
      elseif (minDist == nil or member.distance < minDist)
          and not tContains(spell.SkipList, member.name) then
        minDist = member.distance
        ret = member
      end
    end
  end

  return ret
end

---Add a generic buff of some sorts, or a group buff
---@param buff Bm2BuffDefinition Buff to cast
---@param state Bm2ScanState
local function bm2AddBuff(state, buff)
  --local ok, bag, slot, count
  --
  --if buff.reagentRequired then
  --  ok, bag, slot, count = bomHasItem(buff.reagentRequired, true)
  --end
  --
  --if type(count) == "number" then
  --  count = " x" .. count .. " "
  --else
  --  count = ""
  --end

  ------------------------
  -- Add GROUP BUFF
  ------------------------
  if not profileModule.active.singleBuffOnly then
    -- TODO: Fix group buffing
    Bm2Addon:Print("TODO: group buff task")
    for groupIndex = 1, 8 do
      if buff.calculatedGroup[groupIndex]
          and buff.calculatedGroup[groupIndex] >= profileModule.active.groupBuffMinCount
      then
        engineModule.repeatUpdate = true
        --local selectGroupSpell = buff:SelectGroupSpell(state.?)
        local groupInRange = bm2GetGroupInRange(buff.group, buff.NeedMember, groupIndex, buff)

        if groupInRange == nil then
          groupInRange = bm2GetGroupInRange(buff.group, party, groupIndex, buff)
        end

        if groupInRange ~= nil
            and (not buff.DeathGroup[groupIndex] or not BOM.SharedState.DeathBlock)
        then
          -- Text: Group 5 [Spell Name]
          tasklist:AddWithPrefix(
              L.BUFF_CLASS_GROUPBUFF,
              buff.groupLink or buff.group,
              buff.single,
              "",
              BOM.Class.GroupBuffTarget:new(groupIndex),
              false)
          inRange = true

          bomQueueSpell(buff.groupMana, buff.groupId, buff.groupLink, groupInRange, buff)
        else
          -- Text: Group 5 [Spell Name]
          tasklist:AddWithPrefix(
              L.BUFF_CLASS_GROUPBUFF,
              buff.groupLink or buff.group,
              buff.single,
              "",
              BOM.Class.GroupBuffTarget:new(groupIndex),
              false)
        end -- if group not nil
      end
    end -- for all 8 groups
  end

  ------------------------
  -- Add SINGLE BUFF
  ------------------------
  Bm2Addon:Print("TODO: single buff task")
  for _index, member in ipairs(buff.calculatedTargets) do
    if not member.isDead
        and buff.singleMana ~= nil
        and (BOM.SharedState.NoGroupBuff
        or buff.groupMana == nil
        or member.group == 9
        or buff.NeedGroup[member.group] == nil
        or buff.NeedGroup[member.group] < BOM.SharedState.MinBuff)
    then
      if not member.isPlayer then
        BOM.RepeatUpdate = true
      end

      local add = ""
      local profile_spell = BOM.GetProfileSpell(buff.ConfigID)

      if profile_spell.ForcedTarget[member.name] then
        add = string.format(BOM.PICTURE_FORMAT, BOM.ICON_TARGET_ON)
      end

      local is_in_range = (IsSpellInRange(buff.single, member.unitId) == 1)
          and not tContains(buff.SkipList, member.name)

      if bomPreventPvpTagging(buff.singleLink, buff.single, member) then
        -- Nothing, prevent poison function has already added the text
      elseif is_in_range then
        -- Text: Target [Spell Name]
        tasklist:AddWithPrefix(
            L.BUFF_CLASS_REGULAR,
            buff.singleLink or buff.single,
            buff.single,
            "",
            BOM.Class.MemberBuffTarget:fromMember(member),
            false)
        inRange = true
        bomQueueSpell(buff.singleMana, buff.singleId, buff.singleLink, member, buff)
      else
        -- Text: Target "SpellName"
        tasklist:AddWithPrefix(
            L.BUFF_CLASS_REGULAR,
            buff.singleLink or buff.single,
            buff.single,
            "",
            BOM.Class.MemberBuffTarget:fromMember(member),
            false)
      end
    end
  end -- for all spell.needmember
end

---@param buff Bm2BuffDefinition
---@param state Bm2ScanState
local function bm2ScanOneSpell(state, buff)
  --if next(buff.calculatedTargets)
  --    and not buff:IsConsumableBuff()
  --then
  --  if buff.singleMana < taskListModule.maxPlayerMana
  --      and buff.singleMana > taskListModule.currentPlayerMana then
  --    local singleSpell = spellsDb.singleBuffSpellIds[buff.buffId]
  --    -- TODO: Why is this written this way?
  --    taskListModule.maxPlayerMana = singleSpell.spellCost
  --  end
  --
  --  if buff.groupMana
  --      and buff.groupMana < taskListModule.maxPlayerMana
  --      and buff.groupMana > taskListModule.currentPlayerMana then
  --    local groupSpell = spellsDb.singleBuffSpellIds[buff.buffId]
  --    -- TODO: Why is this written this way?
  --    taskListModule.maxPlayerMana = groupSpell.spellCost
  --  end
  --end

  if buff.buffType == buffDefModule.BUFFTYPE_SUMMON then
    bm2AddSummonSpell(state, buff)

  elseif buff.buffType == buffDefModule.BUFFTYPE_ITEM_TARGET_ITEM then
    -- Weapon enchantments are casted by using an item then clicking another item
    if next(buff.calculatedTargets) ~= nil then
      bm2AddConsumableWeaponBuff(state, buff)
    end
  elseif buff.buffType == buffDefModule.BUFFTYPE_WEAPON_ENCHANTMENT_SPELL then
    -- Shaman weapon enchantments are casted on unenchanted weapons first goes
    -- mainhand then offhand
    if next(buff.calculatedTargets) ~= nil then
      bm2AddWeaponEnchantment(state, buff)
    end

  elseif buff:IsConsumableBuff() then
    if next(buff.calculatedTargets) ~= nil then
      bm2AddConsumableSelfbuff(state, buff)
      state.inRange = true
    end

    --elseif buff.isInfo then
    --  if #buff.NeedMember then
    --    for memberIndex, member in ipairs(buff.NeedMember) do
    --      -- Text: [Player Link] [Spell Link]
    --      tasklist:Add(
    --          buff.singleLink or buff.single,
    --          buff.single,
    --          "Info",
    --          BOM.Class.MemberBuffTarget:fromMember(member),
    --          true)
    --    end
    --  end

  elseif buff.buffType == buffDefModule.BUFFTYPE_TRACKING then
    if next(buff.calculatedTargets) ~= nil then
      if not eventsModule.playerIsCasting then
        buff:SetTracking(true)
      else
        taskListModule:QueueComment(state, _t("Tracking:") .. " " .. buff.buffId)
        -- Text: "Player" "Spell Name"
        --tasklist:AddWithPrefix(
        --    L.TASK_ACTIVATE,
        --    buff.singleLink or buff.single,
        --    buff.single,
        --    L.BUFF_CLASS_TRACKING,
        --    BOM.Class.MemberBuffTarget:fromSelf(playerMember),
        --    false)
      end
    end

  elseif (buff:IsSelfCast()
      or buff.buffType == buffDefModule.BUFFTYPE_AURA
      or buff.buffType == buffDefModule.BUFFTYPE_SEAL)
  then
    -- TODO: fix aura and seal
    Bm2Addon:Print("TODO: fix aura and seal buffs")
    if buff.shapeshiftFormId and GetShapeshiftFormID() == buff.shapeshiftFormId then
      -- if spell is shapeshift, and is already active, skip it
    elseif next(buff.calculatedTargets) ~= nil then
      -- self buffs are not pvp-guarded
      bm2AddSelfbuff(state, buff)
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_RESURRECTION then
    bm2AddResurrection(state, buff)

  elseif buff.buffType == buffDefModule.BUFFTYPE_BLESSING then
    bm2AddBlessing(state, buff)

  else
    bm2AddBuff(state, buff)
  end
end

---@param state Bm2ScanState
local function bm2ScanSelectedSpells(state)
  for _, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    --local profile_spell = BOM.GetProfileSpell(buff.ConfigID)
    --if buff.isInfo and profile_spell.Whisper then
    --  bomWhisperExpired(buff)
    --end

    -- If we're in the correct shapeshift form
    if buff.needForm == nil or GetShapeshiftFormID() == buff.needForm then
      bm2ScanOneSpell(state, buff)
    end
  end
end

---Activate tracking spells
local function bm2ActivateSelectedTracking()
  --reset tracking
  taskListModule.forceTracking = nil

  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]

    if buff.buffType == spellsDb.BUFF_CLASS_TRACKING then
      if buff.needForm ~= nil then
        if GetShapeshiftFormID() == buff.shapeshiftFormId
            and taskListModule.forceTracking ~= buff.trackingIconId then
          taskListModule.forceTracking = buff.trackingIconId
          engineModule:UpdateSpellsTab("activate tracking 1")
        end
      elseif buff:IsTrackingActive()
          and Bm2Addon.db.char.lastTracking ~= buff.trackingIconId then
        Bm2Addon.db.char.lastTracking = buff.trackingIconId
        engineModule:UpdateSpellsTab("activate tracking 2")
      end
    end -- if tracking
  end -- for all spells

  taskListModule.forceTracking = taskListModule.forceTracking
      or Bm2Addon.db.char.lastTracking
end

---@param playerMember Bm2Member
local function bm2GetActiveAuraAndSeal(playerMember)
  --find active aura / seal
  taskListModule.activeAura = nil
  taskListModule.activeSeal = nil

  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    local buffOnPlayer = playerMember:HasBuff(buffId)

    if buffOnPlayer then
      if buff.buffType == buffDefModule.BUFFTYPE_AURA then
        if (taskListModule.activeAura == nil and taskListModule.lastAura == buffId)
            or UnitIsUnit(buffOnPlayer.source, "player")
        then
          if bm2TimeCheck(buffOnPlayer.expirationTime, buffOnPlayer.duration) then
            taskListModule.activeAura = buffId
          end
        end

      elseif buff.type == "seal" then
        if UnitIsUnit(buffOnPlayer.source, "player") then
          if bm2TimeCheck(buffOnPlayer.expirationTime, buffOnPlayer.duration) then
            taskListModule.activeSeal = buffId
          end
        end
      end -- if is aura
    end -- if player.buffs[config.id]
  end -- for all spells
end

local function bm2CheckChangesAndUpdateSpelltab()
  --reset aura/seal
  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]

    if buff.buffType == buffDefModule.BUFFTYPE_AURA then
      if taskListModule.activeAura == buffId and taskListModule.lastAura ~= buffId then
        taskListModule.lastAura = buffId
        engineModule:UpdateSpellsTab("check changes and update: for aura")
      end

    elseif buff.buffType == buffDefModule.BUFFTYPE_SEAL then
      if taskListModule.activeSeal == buffId and taskListModule.lastSeal ~= buffId then
        taskListModule.lastSeal = buffId
        engineModule:UpdateSpellsTab("check changes and update: for seal")
      end
    end
  end
end

---Check if player has rep items equipped where they should not have them
---@param state Bm2ScanState
local function bm2CheckTrinkets(state)
  local _name, _instanceType, _difficultyID, _difficultyName, _maxPlayers
  , _dynamicDifficulty, _isDynamic, instanceID, _instanceGroupSize
  , _LfgDungeonID = GetInstanceInfo()

  local itemTrinket1, _ = GetInventoryItemID("player", constModule.EquipTrinket1)
  local itemTrinket2, _ = GetInventoryItemID("player", constModule.EquipTrinket2)

  if profileModule.active.warnReputationTrinket then
    -- settings to remind to remove AD trinket != instance compatible with AD Commission
    --if playerMember.hasArgentumDawn ~= tContains(BOM.ArgentumDawn.zoneId, instanceID) then
    local hasRepTrinket = tContains(constModule.ReputationTrinket.itemIds, itemTrinket1)
        or tContains(constModule.ReputationTrinket.itemIds, itemTrinket2)

    if hasRepTrinket and not tContains(constModule.ReputationTrinket.allowInZone, instanceID) then
      taskListModule:QueueComment(state, _t("Unequip reputation trinket"))
    end
  end

  ----------------------------------------------
  if profileModule.active.warnRidingTrinket then
    local hasRidingTrinket = tContains(constModule.RidingTrinket.itemIds, itemTrinket1)
        or tContains(constModule.RidingTrinket.itemIds, itemTrinket2)

    if hasRidingTrinket and not tContains(constModule.RidingTrinket.allowInZone, instanceID) then
      -- Text: Unequip [Carrot on a Stick]
      taskListModule:QueueComment(state, _t("Unequip riding trinket"))
    end
  end
end

---Check if player has rep items equipped where they should not have them
---@param state Bm2ScanState
local function bm2CheckWeapons(state)
  --TODO: check missing weapons
  --TODO: check fishing pole
end

---Check player weapons and report if they have the "Warn about missing enchants" option enabled
---@param state Bm2ScanState
local function bm2CheckMissingWeaponEnchantments(state)
  -- enchantment on weapons
  local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID
  , hasOffHandEnchant, offHandExpiration, offHandCharges
  , offHandEnchantId = GetWeaponEnchantInfo()

  if not hasMainHandEnchant then
    local slotId, _texture = GetInventorySlotInfo("MainHandSlot")
    local link = GetInventoryItemLink("player", slotId)

    if link then
      -- Text: [Consumable Enchant Link]
      taskListModule:QueueComment(state, _t("Mainhand enchantment missing"))
    end
  end

  if not hasOffHandEnchant then
    local slotId, _texture = GetInventorySlotInfo("SecondaryHandSlot")
    local link = GetInventoryItemLink("player", slotId)

    if link then
      taskListModule:QueueComment(state, _t("Offhand enchantment missing"))
    end
  end
end

---@param state Bm2ScanState
local function bm2CheckItemsAndContainers(state)
  --Check the items
  --Note: only items listed in bagModule.trackItems are stored
  local itemList = bagModule:GetItemList() ---@type table<number, Bm2GetContainerItemInfoResult>

  for _index, item in ipairs(itemList) do
    local ok = false

    if item.cooldownExpire then
      -- if cooldowns on iteminfo are not empty
      if item.cooldownExpire > 0 then
        -- Do nothing, still on CD

      elseif item.itemLink then
        local target

        --Some item off cooldown and there is target to cast it
        local buffId = spellsDb.itemIdBuffReverseLookup[item.itemId]
        if buffId then
          local preferredTargets = profileModule.active.buffTargets[buffId]
          if preferredTargets and next(preferredTargets) then
            target = preferredTargets[1]
          end
        end

        if profileModule.active.reminderConsumables or IsModifierKeyDown() then
          taskListModule:QueueComment(state, _t("Reminder to use") .. " " .. item.itemLink)
        else
          taskListModule:QueueUseItem(state, item.bag, item.slot, target or UnitName("target"))
        end
      end
    elseif item.Lootable then
      taskListModule:QueueUseItem(state, item.bag, item.slot, nil)
    end
  end
end

---Continue scanning for active buffs which are missing on targets
---@return table<number, Bm2Task> New value to replace taskListModule.tasks
function taskListModule:Scan_Step2()
  local party, player = partyModule:GetPartyMembers()
  local state = {
    player          = player,
    party           = party,
    inRange         = false,
    castButtonTitle = "",
    macroCommand    = "",
    tasks           = {},
  } ---@type Bm2ScanState

  if engineModule.forceUpdate then
    bm2ActivateSelectedTracking()
    -- Get the running aura (buff zone around player) and the running seal
    bm2GetActiveAuraAndSeal(player)
    -- Check changes to auras and seals and update the spell tab
    bm2CheckChangesAndUpdateSpelltab()
    bm2ForceUpdate(state)
  end

  -- cancel buffs
  engineModule:CancelBuffsOn(player)

  -- fill list and find cast
  taskListModule.currentPlayerMana = UnitPower("player", constModule.PowertypeMana) or 0 --mana
  taskListModule.maxPlayerMana = UnitPowerMax("player", constModule.PowertypeMana) or 0

  if bm2IsMountedAndCrusaderAuraWanted() then
    -- Cast crusader aura when mounted, without condition. Ignore all other buffs
    -- Cannot cast anything else while mounted
    taskListModule:QueueBuff(state, "player", "buff_crusaderaura")

  else
    -- Otherwise scan all enabled spells
    bm2ScanSelectedSpells(state)

    -- Check reputation trinket, riding trinket, and missing weapons (despawned in bag or unequipped)
    bm2CheckTrinkets(state)
    bm2CheckWeapons(state)

    if profileModule.active.warnNoEnchantment then
      bm2CheckMissingWeaponEnchantments(state) -- if option to warn is enabled
    end

    bm2CheckItemsAndContainers(state)
  end

  -- Open Buffomat if any cast tasks were added to the task list
  -- TODO: fix from here
  if next(state.tasks) ~= nil then
    BOM.AutoOpen()
  else
    BOM.AutoClose()
  end

  tasklist:Display() -- Show all tasks and comments

  BOM.ForceUpdate = false

  if BOM.PlayerCasting == "cast" then
    --Print player is busy (casting normal spell)
    bomCastButton(L.MsgBusy, false)
    bomUpdateMacro()

  elseif BOM.PlayerCasting == "channel" then
    --Print player is busy (casting channeled spell)
    bomCastButton(L.MsgBusyChanneling, false)
    bomUpdateMacro()

  elseif next_cast_spell.Member and next_cast_spell.SpellId then
    --Next cast is already defined - update the button text
    bomCastButton(next_cast_spell.Link, true)
    bomUpdateMacro(next_cast_spell.Member, next_cast_spell.SpellId)

    local cdtest = GetSpellCooldown(next_cast_spell.SpellId) or 0

    if cdtest ~= 0 then
      BOM.CheckCoolDown = next_cast_spell.SpellId
      BomC_ListTab_Button:Disable()
    else
      BomC_ListTab_Button:Enable()
    end

    BOM.CastFailedSpell = next_cast_spell.Spell
    BOM.CastFailedSpellTarget = next_cast_spell.Member
  else
    if #tasklist.tasks == 0 then
      --If don't have any strings to display, and nothing to do -
      --Clear the cast button
      bomCastButton(L.MsgNothingToDo, true)

      for spellIndex, spell in ipairs(profileModule.active.selectedBuffs) do
        if #spell.SkipList > 0 then
          wipe(spell.SkipList)
        end
      end

    else
      if someoneIsDead and BOM.SharedState.DeathBlock then
        bomCastButton(L.InactiveReason_DeadMember, false)
      else
        if inRange then
          -- Range is good but cast is not possible
          bomCastButton(ERR_OUT_OF_MANA, false)
        else
          bomCastButton(ERR_SPELL_OUT_OF_RANGE, false)
          local skipreset = false

          for spellIndex, spell in ipairs(profileModule.active.selectedBuffs) do
            if #spell.SkipList > 0 then
              skipreset = true
              wipe(spell.SkipList)
            end
          end

          if skipreset then
            BOM.FastUpdateTimer()
            BOM.SetForceUpdate("SkipReset")
          end
        end -- if inrange
      end -- if somebodydeath and deathblock
    end -- if #display == 0

    if castButtonTitle then
      bomCastButton(castButtonTitle, true)
    end

    bomUpdateMacro(nil, nil, macroCommand)
  end -- if not player casting

  return tasks
end

function taskListModule:Scan(caller)
  bagModule:GetItemList() -- possibly update the bag cache, and update the cooldowns

  if next(profileModule.active.selectedBuffs) == nil then
    -- No selected spells, nothing to do
    return
  end

  if engineModule.loadingScreen then
    -- No action during the loading screen
    return
  end

  -- Check whether BOM is disabled due to some option and a matching condition
  local isBm2Active, reasonDisabled = bm2IsActive()
  if not isBm2Active then
    engineModule.forceUpdate = false
    mainWindow:AutoClose()
    macroModule:Clear()
    mainWindow:CastButton(reasonDisabled, false)
    return
  end

  --Choose Profile
  local selectedProfile = profileModule:ChooseProfile()
  if profileModule:Activate(selectedProfile) then
    mainWindow:UpdateSpellTabs("tasklist:scan() profile changed")
    BM2_MAIN_WINDOW_TITLE:SetText(
        uiModule:FormatTexture(constModule.MacroIconFullpath)
            .. " " .. constModule.AddonName .. " - "
            .. _t("profile_" .. selectedProfile))
    engineModule:SetForceUpdate("tasklist:scan() profile changed")
  end

  -- All pre-checks passed
  taskListModule.tasks = taskListModule:Scan_Step2()
end
