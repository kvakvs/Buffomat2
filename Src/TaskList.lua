---@class Bm2TaskListModule
---@field saveSomeoneIsDead boolean
---@field currentPlayerMana number Used for task list building
---@field maxPlayerMana number Used for task list building
---@field tasks table<number, Bm2CastSpell> Spells and buffs to cast, sorted

---@field activeAura string BuffId of active aura (Updated by bm2GetActiveAuraAndSeal) around player
---@field activeSeal string BuffId of active seal (Updated by bm2GetActiveAuraAndSeal) a buff providing weapon augment
---@field lastAura string Updated by bm2GetActiveAuraAndSeal

local taskListModule = Bm2Module.DeclareModule("TaskList")
taskListModule.tasks = {} ---@type table<number, Bm2Task>

---@class Bm2CastSpell
---@field target string
---@field buff Bm2BuffDefinition
-- -@field isSingle boolean

---@class Bm2Task
---@field buffId string
---@field target string Target unit, or group
---@field text string Extra message to display
---@field error string|nil Error message, if not nil, display only error in red

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

---@param party table<number, Bm2Member> - the party
---@param playerMember Bm2Member - the player
local function bm2ForceUpdate(party, playerMember)
  -- TODO: fix below
  -- who needs a buff!
  -- for each spell update spell potential targets
  local someoneIsDead = false -- the flag that buffing cannot continue while someone is dead

  -- For each selected spell check the targets
  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    someoneIsDead = bomUpdateSpellTargets(party, buff, playerMember, someoneIsDead)
  end

  return someoneIsDead
end

local function bm2IsMountedAndCrusaderAuraWanted()
  return Bm2Addon.db.char.autoCrusaderAura -- if setting enabled
      and IsSpellKnown(constModule.spellId.PALADIN_CRUSADERAURA) -- and has the spell
      and (IsMounted() or bomIsFlying()) -- and flying
      and GetShapeshiftForm() ~= constModule.shapeshiftForm.PALADIN_CRUSADERAURA -- and not crusader aura
end

---@param tasks table<number, Bm2CastSpell> The table where to add (later becomes taskListModule.tasks)
function taskListModule:QueueBuff(tasks, target, buff)
  local castSpell = {
    target = target,
    buff   = buff,
  } ---@type Bm2CastSpell
  tinsert(tasks, castSpell)
end

---@param tasks table<number, Bm2CastSpell> The table where to add (later becomes taskListModule.tasks)
function taskListModule:QueueGearChange(tasks, text)
  local castSpell = {
    target = target,
    buff   = buff,
  } ---@type Bm2CastSpell
  tinsert(tasks, castSpell)
end

---@class Bm2ScanState
---@field playerMember Bm2Member
---@field party table<number, Bm2Member>
---@field inRange boolean
---@field castButtonTitle string
---@field macroCommand string

---@param buff Bm2BuffDefinition
---@param state Bm2ScanState
local function bm2ScanOneSpell(buff, state)
  if #buff.NeedMember > 0
      and not buff.isInfo
      and not buff.isConsumable
  then
    if buff.singleMana < BOM.ManaLimit
        and buff.singleMana > bomCurrentPlayerMana then
      BOM.ManaLimit = buff.singleMana
    end

    if buff.groupMana
        and buff.groupMana < BOM.ManaLimit
        and buff.groupMana > bomCurrentPlayerMana then
      BOM.ManaLimit = buff.groupMana
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
      bm2ScanOneSpell(buff, state)
    end
  end
end

---Checks whether a tracking spell is now active
---@param buff Bm2BuffDefinition The tracking spell which might have tracking enabled
local function bm2IsTrackingActive(buff)
  if constModule.IsTBC then
    for i = 1, GetNumTrackingTypes() do
      local _name, _texture, active, _category, _nesting, spellId = GetTrackingInfo(i)
      local _i, buffSingleId = next(buff.singleId)

      if spellId == buffSingleId and active then
        return true
      end
    end
    -- not found
    return false
  else
    return GetTrackingTexture() == buff.trackingIconId
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
      elseif bm2IsTrackingActive(buff)
          and Bm2Addon.db.char.lastTracking ~= buff.trackingIconId then
        Bm2Addon.db.char.lastTracking = buff.trackingIconId
        engineModule:UpdateSpellsTab("activate tracking 2")
      end
    end -- if tracking
  end -- for all spells

  taskListModule.forceTracking = taskListModule.forceTracking
      or Bm2Addon.db.char.lastTracking
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
    -- TODO: Set forceUpdate timer to expiration time
    --if expirationTime < BOM.MinTimer then
    --  BOM.MinTimer = expirationTime
    --end
    return true
  end

  return false
end

---@param playerMember Bm2Member
local function bm2GetActiveAuraAndSeal(playerMember)
  --find active aura / seal
  taskListModule.activeAura = nil
  taskListModule.activeSeal = nil

  for i, buffId in ipairs(profileModule.active.selectedBuffs) do
    local buff = spellsDb.allPossibleBuffs[buffId]
    local buffOnPlayer = playerMember.buffs[buff.ConfigID]

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
---@param playerMember Bm2Member
local function bm2CheckGear(tasks, playerMember)
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

    if hasRepTrinket and not tContains(constModule.ReputationTrinket.zoneId, instanceID) then
      taskListModule:QueueGearChange(tasks, _t("Unequip reputation trinket"))
    end
  end

  ----------------------------------------------
  if profileModule.active.warnRidingTrinket then
    local hasCarrot = tContains(BOM.Carrot.itemIds, itemTrinket1) or
        tContains(BOM.Carrot.itemIds, itemTrinket2)
    if hasCarrot and not tContains(BOM.Carrot.zoneId, instanceID) then
      -- Text: Unequip [Carrot on a Stick]
      tasklist:Comment(L.TASK_UNEQUIP .. " " .. L.RIDING_SPEED_REMINDER)
    end
  end

  ----------------------------------------------
  Bm2Addon:Print("Check no weapon; or fishing pole")
end

---Continue scanning for active buffs which are missing on targets
---@return table<number, Bm2CastSpell> New value to replace taskListModule.tasks
function taskListModule:Scan_Step2()
  local party, playerMember = partyModule:GetPartyMembers()

  if engineModule.forceUpdate then
    bm2ActivateSelectedTracking()
    -- Get the running aura (buff zone around player) and the running seal
    bm2GetActiveAuraAndSeal(playerMember)
    -- Check changes to auras and seals and update the spell tab
    bm2CheckChangesAndUpdateSpelltab()

    taskListModule.saveSomeoneIsDead = bm2ForceUpdate(party, playerMember)
  end

  -- cancel buffs
  engineModule:CancelBuffsOn(playerMember)

  -- fill list and find cast
  taskListModule.currentPlayerMana = UnitPower("player", constModule.POWER_MANA) or 0 --mana
  taskListModule.maxPlayerMana = UnitPowerMax("player", constModule.POWER_MANA) or 0

  local macroCommand ---@type string
  local castButtonTitle ---@type string
  local inRange = false
  local tasks = {} ---@type table<number, Bm2CastSpell>

  if bm2IsMountedAndCrusaderAuraWanted() then
    -- Cast crusader aura when mounted, without condition. Ignore all other buffs
    taskListModule:QueueBuff(tasks, "player", "buff_crusaderaura")

  else
    -- Otherwise scan all enabled spells
    local state = { playerMember    = playerMember,
                    party           = party,
                    inRange         = inRange,
                    castButtonTitle = castButtonTitle,
                    macroCommand    = macroCommand } ---@type Bm2ScanState
    bm2ScanSelectedSpells(state)

    -- Check reputation trinket, riding trinket, and missing weapons (despawned in bag or unequipped)
    bm2CheckGear(tasks, playerMember)

    bomCheckMissingWeaponEnchantments(playerMember) -- if option to warn is enabled

    castButtonTitle, macroCommand = bomCheckItemsAndContainers(
        playerMember, castButtonTitle, macroCommand)
  end

  -- Open Buffomat if any cast tasks were added to the task list
  if #tasklist.tasks > 0 or #tasklist.comments > 0 then
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
