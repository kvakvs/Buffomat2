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

local engineModule = Bm2Module.Import("Engine") ---@type Bm2EngineModule
local _t = Bm2Module.Import("Translation") ---@type Bm2TranslationModule
local constModule = Bm2Module.Import("Const") ---@type Bm2ConstModule
local uiModule = Bm2Module.Import("Ui") ---@type Bm2UiModule
local mainWindow = Bm2Module.Import("Ui/MainWindow") ---@type Bm2UiMainWindowModule
local macroModule = Bm2Module.Import("Macro") ---@type Bm2MacroModule
local profileModule = Bm2Module.Import("Profile")---@type Bm2ProfileModule
local partyModule = Bm2Module.Import("Party")---@type Bm2PartyModule
local spellsDb = Bm2Module.Import("SpellsDb")---@type Bm2SpellsDbModule
local buffDefModule = Bm2Module.Import("SpellsDb/BuffDef")---@type Bm2BuffDefModule
local bagModule = Bm2Module.Import("Bag")---@type Bm2BagModule
local taskModule = Bm2Module.Import("Task")---@type Bm2TaskModule

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

    if buff.alwaysBuffTargets[member.name] then
      pickThisTarget = true
    end

    if buff.neverBuffTargets[member.name] then
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
        if not bagModule:HasItem(buff.lockIfHaveItem) then
          tinsert(buff.calculatedTargets, state.player)
        end

      elseif not (buffOnPlayer and bm2TimeCheck(buffOnPlayer.expirationTime, buffOnPlayer.duration)) then
        tinsert(buff.calculatedTargets, playerMember)
      end
    end

  elseif buff.buffType == buffDefModule.BUFFTYPE_RESURRECTION then
    for _index, member in ipairs(state.party) do
      if member.isDead
          and not member.hasResurrection
          and member.isConnected
          and member.group ~= 9
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
  if buff.hasCooldown and next(buff.calculatedTargets) ~= nil then
    local highestSingle = spellsDb.buffHighestAvailableSingle[buff.buffId].spellId
    local startTime, duration = GetSpellCooldown(highestSingle)

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

---@param buff Bm2BuffDefinition
---@param state Bm2ScanState
local function bm2ScanOneSpell(state, buff)
  if next(buff.calculatedTargets)
      and not buff:IsConsumableBuff()
  then
    if buff.singleMana < taskListModule.maxPlayerMana
        and buff.singleMana > taskListModule.currentPlayerMana then
      local singleSpell = spellsDb.singleBuffSpellIds[buff.buffId]
      -- TODO: Why is this written this way?
      taskListModule.maxPlayerMana = singleSpell.spellCost
    end

    if buff.groupMana
        and buff.groupMana < taskListModule.maxPlayerMana
        and buff.groupMana > taskListModule.currentPlayerMana then
      local groupSpell = spellsDb.singleBuffSpellIds[buff.buffId]
      -- TODO: Why is this written this way?
      taskListModule.maxPlayerMana = groupSpell.spellCost
    end
  end

  if buff.type == "summon" then
    bomAddSummonSpell(buff, playerMember)

  elseif buff.type == "weapon" then
    if #buff.NeedMember > 0 then
      if buff.isConsumable then
        castButtonTitle, macroCommand = bomAddConsumableWeaponBuff(
            buff, playerMember, castButtonTitle, macroCommand)
      else
        castButtonTitle, macroCommand = bomAddWeaponEnchant(buff, playerMember)
      end
    end

  elseif buff.isConsumable then
    if #buff.NeedMember > 0 then
      castButtonTitle, macroCommand = bomAddConsumableSelfbuff(
          buff, playerMember, castButtonTitle, macroCommand, buff.consumableTarget)
      inRange = true
    end

  elseif buff.isInfo then
    if #buff.NeedMember then
      for memberIndex, member in ipairs(buff.NeedMember) do
        -- Text: [Player Link] [Spell Link]
        tasklist:Add(
            buff.singleLink or buff.single,
            buff.single,
            "Info",
            BOM.Class.MemberBuffTarget:fromMember(member),
            true)
      end
    end

  elseif buff.type == "tracking" then
    -- TODO: Move this to its own periodic timer
    if #buff.NeedMember > 0 then
      if BOM.PlayerCasting == nil then
        bomSetTracking(buff, true)
      else
        -- Text: "Player" "Spell Name"
        tasklist:AddWithPrefix(
            L.TASK_ACTIVATE,
            buff.singleLink or buff.single,
            buff.single,
            L.BUFF_CLASS_TRACKING,
            BOM.Class.MemberBuffTarget:fromSelf(playerMember),
            false)
      end
    end

  elseif (buff.isOwn
      or buff.type == "tracking"
      or buff.type == "aura"
      or buff.type == "seal")
  then
    if buff.shapeshiftFormId and GetShapeshiftFormID() == buff.shapeshiftFormId then
      -- if spell is shapeshift, and is already active, skip it
    elseif #buff.NeedMember > 0 then
      -- self buffs are not pvp-guarded
      bomAddSelfbuff(buff, playerMember)
    end

  elseif buff.type == "resurrection" then
    inRange = bomAddResurrection(buff, playerMember, inRange)

  elseif buff.isBlessing then
    inRange = bomAddBlessing(buff, party, playerMember, inRange)

  else
    inRange = bomAddBuff(buff, party, playerMember, inRange)
  end

  return inRange, castButtonTitle, macroCommand
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
    local hasRidingTrinket = tContains(constModule.RidingTrinket.itemIds, itemTrinket1) or
        tContains(BOM.RidingTrinket.itemIds, itemTrinket2)
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
  local party, playerMember = partyModule:GetPartyMembers()
  local state = {
    playerMember    = playerMember,
    party           = party,
    inRange         = false,
    castButtonTitle = "",
    macroCommand    = "",
    tasks           = {},
  } ---@type Bm2ScanState

  if engineModule.forceUpdate then
    bm2ActivateSelectedTracking()
    -- Get the running aura (buff zone around player) and the running seal
    bm2GetActiveAuraAndSeal(playerMember)
    -- Check changes to auras and seals and update the spell tab
    bm2CheckChangesAndUpdateSpelltab()
    bm2ForceUpdate(state)
  end

  -- cancel buffs
  engineModule:CancelBuffsOn(playerMember)

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
  if next(tasks) ~= nil then
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
  Bm2Addon:Print("Scan (called from " .. caller .. ")")

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
