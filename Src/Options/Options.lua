---@class Bm2OptionsModule
local options = Bm2Module.DeclareModule("Options")

local profileModule = Bm2Module.Import("Profile")---@type Bm2ProfileModule

---@type Bm2TranslationModule
local translation = Bm2Module.Import("Translation")
local function _t_fn(key)
  return function()
    return translation(key)
  end
end

local function opt_autoShow(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Show when there\'s work to do'),
    desc  = _t_fn('Pop Buffomat window when task list is not empty'),
    width = 1.5,
    get   = function()
      return Bm2Addon.db.char.autoShow;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoShow = value;
    end,
  }
end

local function opt_buffCurrentTarget(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Buff current target first'),
    desc  = _t_fn('Start buffing with the currently targeted raid or party member as a priority.'),
    width = 1.5,
    get   = function()
      return Bm2Addon.db.char.buffCurrentTarget;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.buffCurrentTarget = value;
    end,
  }
end

local function opt_scanInRestAreas(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in rest areas'),
    desc  = _t_fn('Allow scanning for missing buffs in cities and inns'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanInRestAreas;
    end,
    set   = function(info, value)
      profileModule.active.scanInRestAreas = value;
    end,
  }
end

local function opt_scanInOpenWorld(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in open world'),
    desc  = _t_fn('Allow scanning in the open world.'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanInOpenWorld;
    end,
    set   = function(info, value)
      profileModule.active.scanInOpenWorld = value;
    end,
  }
end

local function opt_scanInDungeons(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in dungeons and raids'),
    desc  = _t_fn('Allow scanning for missing buffs in dungeon and raid instances.'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanInDungeons;
    end,
    set   = function(info, value)
      profileModule.active.scanInDungeons = value;
    end,
  }
end

local function opt_scanInPvp(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in PvP zones'),
    desc  = _t_fn('Allow scanning for missing buffs in battlegrounds and PvP areas.'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanInPvp;
    end,
    set   = function(info, value)
      profileModule.active.scanInPvp = value;
    end,
  }
end

local function opt_scanInStealth(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in stealth'),
    desc  = _t_fn('Allow scanning for missing buffs while player is stealthed. Prevents accidental loss of stealth.'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanInStealth;
    end,
    set   = function(info, value)
      profileModule.active.scanInStealth = value;
    end,
  }
end

local function opt_scanWhileMounted(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan while mounted'),
    desc  = _t_fn('Allow scanning for missing buffs while on a ground or flying mount.'),
    width = 1.5,
    get   = function()
      return profileModule.active.scanWhileMounted;
    end,
    set   = function(info, value)
      profileModule.active.scanWhileMounted = value;
    end,
  }
end

local function opt_preventPvpTag(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Prevent accidental PvP tag'),
    desc  = _t_fn('Skip PvP flagged targets if the player is not PvP flagged.'),
    width = 1.5,
    get   = function()
      return profileModule.active.preventPvpTag;
    end,
    set   = function(info, value)
      profileModule.active.preventPvpTag = value;
    end,
  }
end

local function opt_autoDismountGround(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Dismount while mounted'),
    desc  = _t_fn('Hop off your ground mount if a buff is attempted.'),
    width = 1.5,
    get   = function()
      return profileModule.active.autoDismountGround;
    end,
    set   = function(info, value)
      profileModule.active.autoDismountGround = value;
    end,
  }
end

local function opt_autoDismountFlying(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Dismount while flying'),
    desc  = _t_fn('Hop off your flying mount if a buff is attempted. Can cause death.'),
    width = 1.5,
    get   = function()
      return profileModule.active.autoDismountFlying;
    end,
    set   = function(info, value)
      profileModule.active.autoDismountFlying = value;
    end,
  }
end

local function opt_autoStand(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Stand up if sitting'),
    desc  = _t_fn('Stand up if a buff is attempted while the character was sitting.'),
    width = 1.5,
    get   = function()
      return profileModule.active.autoStand;
    end,
    set   = function(info, value)
      profileModule.active.autoStand = value;
    end,
  }
end

local function opt_autoLeaveShapeshift(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Leave shapeshift forms'),
    desc  = _t_fn('If a buff is attempted while in a shapeshift form, leave that form.'),
    width = 1.5,
    get   = function()
      return profileModule.active.autoLeaveShapeshift;
    end,
    set   = function(info, value)
      profileModule.active.autoLeaveShapeshift = value;
    end,
  }
end

local function opt_autoCrusaderAura(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Suggest to use crusader aura'),
    desc  = _t_fn('For paladins suggest enabling crusader aura when mounted.'),
    width = 1.5,
    get   = function()
      return profileModule.active.autoCrusaderAura;
    end,
    set   = function(info, value)
      profileModule.active.autoCrusaderAura = value;
    end,
  }
end

function options:MakeGeneralTab()
  return {
    name  = _t_fn('General'),
    type  = "group",
    order = 10,
    args  = {
      --header_general = {
      --  type  = "header",
      --  order = 1,
      --  name  = _t('General Options'),
      --},
      g_options1     = {
        type   = "group",
        order  = 1,
        inline = true,
        name   = _t_fn('Behavioral settings'),
        args   = {
          autoShow            = opt_autoShow(1),
          buffCurrentTarget   = opt_buffCurrentTarget(2),
          preventPvpTag       = opt_preventPvpTag(3),
          autoDismountGround  = opt_autoDismountGround(4),
          autoDismountFlying  = opt_autoDismountFlying(5),
          autoStand           = opt_autoStand(6),
          autoLeaveShapeshift = opt_autoLeaveShapeshift(7),
          autoCrusaderAura    = opt_autoCrusaderAura(8),
        }
      },
      g_activateWhen = {
        type   = "group",
        order  = 2,
        inline = true,
        name   = _t_fn('Activate when...'),
        args   = {
          scanInRestAreas  = opt_scanInRestAreas(1),
          scanInOpenWorld  = opt_scanInOpenWorld(2),
          scanInDungeons   = opt_scanInDungeons(3),
          scanInPvp        = opt_scanInPvp(4),
          scanInStealth    = opt_scanInStealth(5),
          scanWhileMounted = opt_scanWhileMounted(6),
        },
      },
    }
  }
end

function options:GetDefaults()
  return {
    global = {
    },
    char   = {
      -- TODO: durationCache has names populated from the known spells when updating spells
      durationCache     = {}, -- [spellname] => GetTime(), for spells known to Buffomat

      mainWindowX       = 0,
      mainWindowY       = 0,
      mainWindowWidth   = 180,
      mainWindowHeight  = 90,

      autoShow          = true,
      buffCurrentTarget = true,
      lastTracking      = "", -- icon path for tracking which was last active

      rebuffForDuration60 = 5,
      rebuffForDuration300 = 60,
      rebuffForDuration600 = 120,
      rebuffForDuration1800 = 180,
      rebuffForDuration3600 = 180,

      --
      -- Profile management and multiple profiles for the player
      --
      useProfiles       = false,
      forceProfile      = "",
      profile           = {
        solo  = profileModule:NewProfile("solo"),
        raid  = profileModule:NewProfile("raid"),
        party = profileModule:NewProfile("party"),
        pvp   = profileModule:NewProfile("pvp"),
      },
    },
  }
end
