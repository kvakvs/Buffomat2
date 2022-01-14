---@class Bm2TaskListModule
local taskListModule = Bm2Module.DeclareModule("TaskList")
taskListModule.tasks = {} ---@type table<number, Bm2Task>

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

---Continue scanning for active buffs which are missing on targets
function taskListModule:Scan_Step2()
  local party, playerMember = BOM.GetPartyMembers()

  local someoneIsDead = bomSaveSomeoneIsDead
  if BOM.ForceUpdate then
    someoneIsDead = bomForceUpdate(party, playerMember)
  end

  -- cancel buffs
  bomCancelBuffs(playerMember)

  -- fill list and find cast
  bomCurrentPlayerMana = UnitPower("player", 0) or 0 --mana
  BOM.ManaLimit = UnitPowerMax("player", 0) or 0

  bomClearNextCastSpell()

  local macroCommand ---@type string
  local castButtonTitle ---@type string
  local inRange = false

  -- Cast crusader aura when mounted, without condition. Ignore all other buffs
  if bomMountedCrusaderAuraPrompt() then
    -- Do not scan other spells
    castButtonTitle = "Crusader"
    macroCommand = "/cast Crusader Aura"
  else
    -- Otherwise scan all enabled spells
    BOM.ScanModifier = false

    inRange, castButtonTitle, macroCommand = bomScanSelectedSpells(
        playerMember, party, inRange,
        castButtonTitle, macroCommand)

    bomCheckReputationItems(playerMember)
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

  wipe(taskListModule.tasks)

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
  taskListModule:Scan_Step2()
end
