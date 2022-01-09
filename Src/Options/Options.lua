---@class Bm2OptionsModule
local options = Bm2Module.DeclareModule("Options")

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

local function opt_scanInRestAreas(order)
  return {
    type  = "toggle",
    order = order,
    name  = _t_fn('Scan in rest areas'),
    desc  = _t_fn('Allow scanning for missing buffs in cities and inns'),
    width = 1.5,
    get   = function()
      return Bm2Addon.db.char.scanInRestAreas;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanInRestAreas = value;
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
      return Bm2Addon.db.char.scanInOpenWorld;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanInOpenWorld = value;
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
      return Bm2Addon.db.char.scanInDungeons;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanInDungeons = value;
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
      return Bm2Addon.db.char.scanInRestAreas;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanInRestAreas = value;
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
      return Bm2Addon.db.char.scanInStealth;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanInStealth = value;
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
      return Bm2Addon.db.char.scanWhileMounted;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.scanWhileMounted = value;
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
      return Bm2Addon.db.char.preventPvpTag;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.preventPvpTag = value;
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
      return Bm2Addon.db.char.autoDismountGround;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoDismountGround = value;
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
      return Bm2Addon.db.char.autoDismountFlying;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoDismountFlying = value;
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
      return Bm2Addon.db.char.autoStand;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoStand = value;
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
      return Bm2Addon.db.char.autoLeaveShapeshift;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoLeaveShapeshift = value;
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
      return Bm2Addon.db.char.autoCrusaderAura;
    end,
    set   = function(info, value)
      Bm2Addon.db.char.autoCrusaderAura = value;
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
          preventPvpTag       = opt_preventPvpTag(2),
          autoDismountGround  = opt_autoDismountGround(3),
          autoDismountFlying  = opt_autoDismountFlying(4),
          autoStand           = opt_autoStand(5),
          autoLeaveShapeshift = opt_autoLeaveShapeshift(6),
          autoCrusaderAura    = opt_autoCrusaderAura(7),
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
    global = {},
    char   = {
      mainWindowX         = 0,
      mainWindowY         = 0,
      mainWindowWidth     = 180,
      mainWindowHeight    = 90,

      autoShow            = true,
      scanInRestAreas     = true,
      scanInOpenWorld     = true,
      scanInDungeons      = true,
      scanInPvp           = true,
      scanInStealth       = false,
      scanWhileMounted    = false,
      preventPvpTag       = true,
      autoDismountGround  = true,
      autoDismountFlying  = false,
      autoStand           = true,
      autoLeaveShapeshift = true,
      autoCrusaderAura    = true,
    },
  }
end
